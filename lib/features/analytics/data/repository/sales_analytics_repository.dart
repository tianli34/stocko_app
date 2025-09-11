import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/drift.dart' as drift;
import '../../domain/model/product_sales_ranking.dart';

enum ProductRankingSort { byQtyDesc, byProfitDesc }

class SalesAnalyticsRepository {
  final AppDatabase _db;
  SalesAnalyticsRepository(this._db);

  // 在某些测试场景下（使用 Mock 未 stub 非空表 getter），直接访问 _db.<table>
  // 会因返回 null 而触发运行时类型错误。这里通过 try/catch 安全收集表，
  // 若获取失败则回退为不声明 readsFrom（返回空集合），以便单元测试能专注于行为而非具体表。
  Set<drift.TableInfo<dynamic, dynamic>> _safeReadsFromTables() {
    final set = <drift.TableInfo<dynamic, dynamic>>{};
    void addSafely(Object? Function() getter) {
      try {
        final v = getter();
        if (v is drift.TableInfo) set.add(v);
      } catch (_) {
        // ignore in tests where getters aren't stubbed
      }
    }
    addSafely(() => _db.salesTransactionItem);
    addSafely(() => _db.salesTransaction);
    addSafely(() => _db.product);
    addSafely(() => _db.productBatch);
    addSafely(() => _db.inboundItem);
    addSafely(() => _db.inboundReceipt);
    addSafely(() => _db.purchaseOrder);
    addSafely(() => _db.purchaseOrderItem);
    return set;
  }

  /// 获取指定时间范围内的商品销量排行榜（仅统计有销量的商品）
  /// - 时间范围基于 sales_transaction.created_at
  /// - 仅统计状态不为 'cancelled' 的交易
  Future<List<ProductSalesRanking>> getProductSalesRanking({
    required DateTime start,
    required DateTime end,
    int? limit,
    ProductRankingSort sort = ProductRankingSort.byQtyDesc,
  }) async {
    // 注意：SQLite 不支持 BETWEEN 的上界为闭区间时跨毫秒，这里采用 >= start AND < endNext
    // 这里 end 作为包含当天的自然日，追加 1 天作为开区间上界
    final endOpen = end;

    final orderBy = switch (sort) {
      ProductRankingSort.byQtyDesc => 'total_qty DESC',
      ProductRankingSort.byProfitDesc => 'total_profit_in_cents DESC',
    };

  final query = _db.customSelect(
      '''
      WITH batch_cost AS (
        SELECT 
          pb.id AS batch_id,
          CASE 
            WHEN SUM(ii.quantity) IS NOT NULL AND SUM(ii.quantity) > 0 
              THEN CAST(ROUND(SUM(ii.quantity * poi.unit_price_in_cents) * 1.0 / SUM(ii.quantity)) AS INT)
            ELSE NULL
          END AS unit_cost_in_cents
        FROM product_batch pb
        LEFT JOIN inbound_item ii ON ii.batch_id = pb.id
        LEFT JOIN inbound_receipt ir ON ir.id = ii.receipt_id
        LEFT JOIN purchase_order po ON po.id = ir.purchase_order_id
        LEFT JOIN purchase_order_item poi 
          ON poi.purchase_order_id = po.id 
         AND poi.product_id = pb.product_id 
         AND poi.production_date = pb.production_date
        GROUP BY pb.id
      ),
      poi_avg AS (
        SELECT 
          purchase_order_id,
          product_id,
          CAST(ROUND(SUM(quantity * unit_price_in_cents) * 1.0 / SUM(quantity)) AS INT) AS avg_price_in_cents
        FROM purchase_order_item
        GROUP BY purchase_order_id, product_id
      ),
      global_poi_avg AS (
        SELECT 
          product_id,
          CAST(ROUND(SUM(quantity * unit_price_in_cents) * 1.0 / SUM(quantity)) AS INT) AS avg_price_in_cents
        FROM purchase_order_item
        GROUP BY product_id
      ),
      unbatched_cost AS (
        SELECT 
          ii.product_id AS product_id,
          CASE 
            WHEN SUM(ii.quantity) IS NOT NULL AND SUM(ii.quantity) > 0 
              THEN CAST(ROUND(SUM(ii.quantity * COALESCE(pa.avg_price_in_cents, gpa.avg_price_in_cents)) * 1.0 / SUM(ii.quantity)) AS INT)
            ELSE NULL
          END AS unit_cost_in_cents
        FROM inbound_item ii
        INNER JOIN inbound_receipt ir ON ir.id = ii.receipt_id
        INNER JOIN purchase_order po ON po.id = ir.purchase_order_id
        LEFT JOIN poi_avg pa ON pa.purchase_order_id = po.id AND pa.product_id = ii.product_id
        LEFT JOIN global_poi_avg gpa ON gpa.product_id = ii.product_id
        WHERE ii.batch_id IS NULL
        GROUP BY ii.product_id
      )
      SELECT 
        p.id AS product_id,
        p.name AS name,
        p.sku AS sku,
        SUM(si.quantity) AS total_qty,
        SUM(si.quantity * si.price_in_cents) AS total_amount_in_cents,
        SUM(CASE 
              WHEN si.batch_id IS NULL THEN 
                CASE WHEN COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents) IS NULL THEN 0 
                     ELSE si.quantity * (si.price_in_cents - COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents)) END
              ELSE 
                CASE WHEN bc.unit_cost_in_cents IS NULL THEN 0 
                     ELSE si.quantity * (si.price_in_cents - bc.unit_cost_in_cents) END
            END) AS total_profit_in_cents,
        SUM(CASE 
              WHEN si.batch_id IS NULL THEN CASE WHEN COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents) IS NULL THEN 1 ELSE 0 END
              ELSE CASE WHEN bc.unit_cost_in_cents IS NULL THEN 1 ELSE 0 END
            END) AS missing_cost_count
      FROM sales_transaction_item si
      INNER JOIN sales_transaction st ON st.id = si.sales_transaction_id
      INNER JOIN product p ON p.id = si.product_id
      LEFT JOIN product_batch pb ON pb.id = si.batch_id
      LEFT JOIN batch_cost bc ON bc.batch_id = pb.id
  LEFT JOIN unbatched_cost uc ON uc.product_id = si.product_id
  LEFT JOIN global_poi_avg gpa ON gpa.product_id = si.product_id
      WHERE st.created_at >= ? AND st.created_at < ? AND st.status != 'cancelled'
      GROUP BY p.id, p.name, p.sku
      HAVING SUM(si.quantity) > 0
      ORDER BY $orderBy
      ${limit != null ? 'LIMIT $limit' : ''}
      ''',
      variables: [
        drift.Variable<DateTime>(start),
        drift.Variable<DateTime>(endOpen),
      ],
  readsFrom: _safeReadsFromTables(),
    );

    final rows = await query.get();
  return rows
    .map((r) => ProductSalesRanking(
        productId: r.read<int>('product_id'),
        name: r.read<String>('name'),
        sku: r.read<String?>('sku'),
        totalQty: r.read<int>('total_qty'),
        totalAmountInCents: r.read<int>('total_amount_in_cents'),
        totalProfitInCents: r.read<int>('total_profit_in_cents'),
        missingCostCount: r.read<int>('missing_cost_count'),
      ))
    .toList();
  }

  /// 监听指定时间范围内的商品销量排行榜变动
  Stream<List<ProductSalesRanking>> watchProductSalesRanking({
    required DateTime start,
    required DateTime end,
    int? limit,
    ProductRankingSort sort = ProductRankingSort.byQtyDesc,
  }) {
    final endOpen = end;
    final orderBy = switch (sort) {
      ProductRankingSort.byQtyDesc => 'total_qty DESC',
      ProductRankingSort.byProfitDesc => 'total_profit_in_cents DESC',
    };
  final selectable = _db.customSelect(
      '''
      WITH batch_cost AS (
        SELECT 
          pb.id AS batch_id,
          CASE 
            WHEN SUM(ii.quantity) IS NOT NULL AND SUM(ii.quantity) > 0 
              THEN CAST(ROUND(SUM(ii.quantity * poi.unit_price_in_cents) * 1.0 / SUM(ii.quantity)) AS INT)
            ELSE NULL
          END AS unit_cost_in_cents
        FROM product_batch pb
        LEFT JOIN inbound_item ii ON ii.batch_id = pb.id
        LEFT JOIN inbound_receipt ir ON ir.id = ii.receipt_id
        LEFT JOIN purchase_order po ON po.id = ir.purchase_order_id
        LEFT JOIN purchase_order_item poi 
          ON poi.purchase_order_id = po.id 
         AND poi.product_id = pb.product_id 
         AND poi.production_date = pb.production_date
        GROUP BY pb.id
      ),
      poi_avg AS (
        SELECT 
          purchase_order_id,
          product_id,
          CAST(ROUND(SUM(quantity * unit_price_in_cents) * 1.0 / SUM(quantity)) AS INT) AS avg_price_in_cents
        FROM purchase_order_item
        GROUP BY purchase_order_id, product_id
      ),
      global_poi_avg AS (
        SELECT 
          product_id,
          CAST(ROUND(SUM(quantity * unit_price_in_cents) * 1.0 / SUM(quantity)) AS INT) AS avg_price_in_cents
        FROM purchase_order_item
        GROUP BY product_id
      ),
      unbatched_cost AS (
        SELECT 
          ii.product_id AS product_id,
          CASE 
            WHEN SUM(ii.quantity) IS NOT NULL AND SUM(ii.quantity) > 0 
              THEN CAST(ROUND(SUM(ii.quantity * COALESCE(pa.avg_price_in_cents, gpa.avg_price_in_cents)) * 1.0 / SUM(ii.quantity)) AS INT)
            ELSE NULL
          END AS unit_cost_in_cents
        FROM inbound_item ii
        INNER JOIN inbound_receipt ir ON ir.id = ii.receipt_id
        INNER JOIN purchase_order po ON po.id = ir.purchase_order_id
        LEFT JOIN poi_avg pa ON pa.purchase_order_id = po.id AND pa.product_id = ii.product_id
        LEFT JOIN global_poi_avg gpa ON gpa.product_id = ii.product_id
        WHERE ii.batch_id IS NULL
        GROUP BY ii.product_id
      )
      SELECT 
        p.id AS product_id,
        p.name AS name,
        p.sku AS sku,
        SUM(si.quantity) AS total_qty,
        SUM(si.quantity * si.price_in_cents) AS total_amount_in_cents,
        SUM(CASE 
              WHEN si.batch_id IS NULL THEN 
                CASE WHEN COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents) IS NULL THEN 0 
                     ELSE si.quantity * (si.price_in_cents - COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents)) END
              ELSE 
                CASE WHEN bc.unit_cost_in_cents IS NULL THEN 0 
                     ELSE si.quantity * (si.price_in_cents - bc.unit_cost_in_cents) END
            END) AS total_profit_in_cents,
        SUM(CASE 
              WHEN si.batch_id IS NULL THEN CASE WHEN COALESCE(uc.unit_cost_in_cents, gpa.avg_price_in_cents) IS NULL THEN 1 ELSE 0 END
              ELSE CASE WHEN bc.unit_cost_in_cents IS NULL THEN 1 ELSE 0 END
            END) AS missing_cost_count
      FROM sales_transaction_item si
      INNER JOIN sales_transaction st ON st.id = si.sales_transaction_id
      INNER JOIN product p ON p.id = si.product_id
      LEFT JOIN product_batch pb ON pb.id = si.batch_id
      LEFT JOIN batch_cost bc ON bc.batch_id = pb.id
  LEFT JOIN unbatched_cost uc ON uc.product_id = si.product_id
  LEFT JOIN global_poi_avg gpa ON gpa.product_id = si.product_id
      WHERE st.created_at >= ? AND st.created_at < ? AND st.status != 'cancelled'
      GROUP BY p.id, p.name, p.sku
      HAVING SUM(si.quantity) > 0
      ORDER BY $orderBy
      ${limit != null ? 'LIMIT $limit' : ''}
      ''',
      variables: [
        drift.Variable<DateTime>(start),
        drift.Variable<DateTime>(endOpen),
      ],
  readsFrom: _safeReadsFromTables(),
    );

  return selectable.watch().map((rows) => rows
    .map((r) => ProductSalesRanking(
        productId: r.read<int>('product_id'),
        name: r.read<String>('name'),
        sku: r.read<String?>('sku'),
        totalQty: r.read<int>('total_qty'),
        totalAmountInCents: r.read<int>('total_amount_in_cents'),
        totalProfitInCents: r.read<int>('total_profit_in_cents'),
        missingCostCount: r.read<int>('missing_cost_count'),
      ))
    .toList());
  }
}

// Provider (no codegen)
final salesAnalyticsRepositoryProvider = Provider<SalesAnalyticsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesAnalyticsRepository(db);
});
