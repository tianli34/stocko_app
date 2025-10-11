import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart';

/// 移动加权平均价格计算服务
/// 负责计算和更新库存的移动加权平均价格
class WeightedAveragePriceService {
  final AppDatabase _database;

  WeightedAveragePriceService(this._database);

  /// 计算并更新移动加权平均价格
  /// 当有新的入库时调用此方法
  /// 注意：此方法只更新平均价格，不更新库存数量（库存数量由 InventoryService.inbound 负责）
  Future<void> updateWeightedAveragePrice({
    required int productId,
    required int shopId,
    required int? batchId,
    required int inboundQuantity,
    required int inboundUnitPriceInCents,
  }) async {
    await _database.transaction(() async {
      // 获取当前库存信息
      final currentStock = await _database.inventoryDao
          .getInventoryByProductShopAndBatch(productId, shopId, batchId);

      if (currentStock == null) {
        // 如果没有现有库存，不做任何操作
        // 库存记录会由 InventoryService.inbound 创建
        // 这里只需要在库存创建后更新平均价格即可
        return;
      } else {
        // 计算新的移动加权平均价格
        final currentQuantity = currentStock.quantity;
        final currentAveragePrice = currentStock.averageUnitPriceInCents;

        // 移动加权平均价格公式：
        // 新平均价格 = (现有库存数量 × 现有平均价格 + 入库数量 × 入库单价) ÷ (现有库存数量 + 入库数量)
        final totalValue =
            (currentQuantity * currentAveragePrice) +
            (inboundQuantity * inboundUnitPriceInCents);
        final totalQuantity = currentQuantity + inboundQuantity;

        final newAveragePrice = totalQuantity > 0
            ? (totalValue / totalQuantity).round()
            : 0;

        // 只更新平均价格，不更新库存数量
        await _database.inventoryDao.updateInventory(
          StockCompanion(
            id: drift.Value(currentStock.id),
            averageUnitPriceInCents: drift.Value(newAveragePrice),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// 出库时更新移动加权平均价格
  /// 出库不改变平均价格，只减少数量
  Future<void> updateOnOutbound({
    required int productId,
    required int shopId,
    required int? batchId,
    required int outboundQuantity,
  }) async {
    final currentStock = await _database.inventoryDao
        .getInventoryByProductShopAndBatch(productId, shopId, batchId);

    if (currentStock != null) {
      final newQuantity = currentStock.quantity - outboundQuantity;

      await _database.inventoryDao.updateInventory(
        StockCompanion(
          id: drift.Value(currentStock.id),
          quantity: drift.Value(newQuantity),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  /// 获取指定库存的移动加权平均价格
  Future<int> getWeightedAveragePrice({
    required int productId,
    required int shopId,
    int? batchId,
  }) async {
    final stock = await _database.inventoryDao
        .getInventoryByProductShopAndBatch(productId, shopId, batchId);

    return stock?.averageUnitPriceInCents ?? 0;
  }

  /// 批量重新计算所有库存的移动加权平均价格
  /// 基于历史入库记录重新计算，用于数据修复
  Future<void> recalculateAllWeightedAveragePrices() async {
    await _database.transaction(() async {
      // 获取所有库存记录
      final allStocks = await _database.inventoryDao.getAllInventory();

      for (final stock in allStocks) {
        await _recalculateStockWeightedAveragePrice(
          productId: stock.productId,
          shopId: stock.shopId,
          batchId: stock.batchId,
        );
      }
    });
  }

  /// 重新计算单个库存的移动加权平均价格
  Future<void> _recalculateStockWeightedAveragePrice({
    required int productId,
    required int shopId,
    int? batchId,
  }) async {
    // 获取该库存的所有入库记录，按时间排序
    final inboundRecords = await _getInboundRecordsForStock(
      productId: productId,
      shopId: shopId,
      batchId: batchId,
    );

    if (inboundRecords.isEmpty) return;

    int cumulativeQuantity = 0;
    int weightedAveragePrice = 0;

    // 按时间顺序重新计算移动加权平均价格
    for (final record in inboundRecords) {
      final inboundQuantity = record['quantity'] as int;
      final inboundPrice = record['unitPriceInCents'] as int;

      if (cumulativeQuantity == 0) {
        // 第一次入库
        weightedAveragePrice = inboundPrice;
      } else {
        // 计算新的移动加权平均价格
        final totalValue =
            (cumulativeQuantity * weightedAveragePrice) +
            (inboundQuantity * inboundPrice);
        final totalQuantity = cumulativeQuantity + inboundQuantity;
        weightedAveragePrice = (totalValue / totalQuantity).round();
      }

      cumulativeQuantity += inboundQuantity;
    }

    // 更新库存的移动加权平均价格
    final currentStock = await _database.inventoryDao
        .getInventoryByProductShopAndBatch(productId, shopId, batchId);

    if (currentStock != null) {
      await _database.inventoryDao.updateInventory(
        StockCompanion(
          id: drift.Value(currentStock.id),
          averageUnitPriceInCents: drift.Value(weightedAveragePrice),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  /// 获取指定库存的入库记录
  Future<List<Map<String, dynamic>>> _getInboundRecordsForStock({
    required int productId,
    required int shopId,
    int? batchId,
  }) async {
    final batchCondition = batchId != null
        ? 'AND ii.batch_id = $batchId'
        : 'AND ii.batch_id IS NULL';

    final result = await _database
        .customSelect(
          '''
      SELECT ii.quantity, ii.unit_price_in_cents, ir.created_at
      FROM inbound_item ii
      JOIN inbound_receipt ir ON ii.receipt_id = ir.id
      WHERE ii.product_id = ? AND ir.shop_id = ? $batchCondition
      ORDER BY ir.created_at ASC
      ''',
          variables: [
            drift.Variable.withInt(productId),
            drift.Variable.withInt(shopId),
          ],
        )
        .get();

    return result
        .map(
          (row) => {
            'quantity': row.read<int>('quantity'),
            'unitPriceInCents': row.read<int>('unit_price_in_cents'),
            'createdAt': row.read<DateTime>('created_at'),
          },
        )
        .toList();
  }
}

/// 移动加权平均价格服务提供者
final weightedAveragePriceServiceProvider =
    Provider<WeightedAveragePriceService>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return WeightedAveragePriceService(database);
    });
