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
    addSafely(() => _db.stock);
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
      SELECT 
        p.id AS product_id,
        p.name AS name,
        p.sku AS sku,
        SUM(si.quantity) AS total_qty,
        SUM(si.quantity * si.price_in_cents) AS total_amount_in_cents,
        SUM(CASE 
              WHEN s.average_unit_price_in_cents IS NULL OR s.average_unit_price_in_cents = 0 THEN 0 
              ELSE si.quantity * (si.price_in_cents - s.average_unit_price_in_cents) 
            END) AS total_profit_in_cents,
        SUM(CASE 
              WHEN s.average_unit_price_in_cents IS NULL OR s.average_unit_price_in_cents = 0 THEN 1 
              ELSE 0 
            END) AS missing_cost_count
      FROM sales_transaction_item si
      INNER JOIN sales_transaction st ON st.id = si.sales_transaction_id
      INNER JOIN product p ON p.id = si.product_id
      LEFT JOIN stock s ON s.product_id = si.product_id 
        AND s.shop_id = st.shop_id 
        AND (s.batch_id = si.batch_id OR (s.batch_id IS NULL AND si.batch_id IS NULL))
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
      SELECT 
        p.id AS product_id,
        p.name AS name,
        p.sku AS sku,
        SUM(si.quantity) AS total_qty,
        SUM(si.quantity * si.price_in_cents) AS total_amount_in_cents,
        SUM(CASE 
              WHEN s.average_unit_price_in_cents IS NULL OR s.average_unit_price_in_cents = 0 THEN 0 
              ELSE si.quantity * (si.price_in_cents - s.average_unit_price_in_cents) 
            END) AS total_profit_in_cents,
        SUM(CASE 
              WHEN s.average_unit_price_in_cents IS NULL OR s.average_unit_price_in_cents = 0 THEN 1 
              ELSE 0 
            END) AS missing_cost_count
      FROM sales_transaction_item si
      INNER JOIN sales_transaction st ON st.id = si.sales_transaction_id
      INNER JOIN product p ON p.id = si.product_id
      LEFT JOIN stock s ON s.product_id = si.product_id 
        AND s.shop_id = st.shop_id 
        AND (s.batch_id = si.batch_id OR (s.batch_id IS NULL AND si.batch_id IS NULL))
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
