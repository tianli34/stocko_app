import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inventory_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Stock])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  /// 插入库存记录
  Future<int> insertInventory(StockCompanion inventory) {
    return into(stock).insert(inventory);
  }

  /// 根据ID获取库存
  Future<StockData?> getInventoryById(int id) {
    return (select(
      stock,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据产品ID和店铺ID获取库存
  Future<StockData?> getInventoryByProductAndShop(
    int productId,
    int shopId,
  ) {
    // 注意：同一 productId + shopId 可能存在多条记录（不同 batchId）。
    // 为避免 getSingleOrNull 在多行时抛出异常，这里限定只取一条。
    return (select(stock)
          ..where(
            (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// 根据产品、店铺与批次获取库存（batchId 可为空）
  Future<StockData?> getInventoryByProductShopAndBatch(
    int productId,
    int shopId,
    int? batchId,
  ) {
    final query = select(stock)
      ..where((t) => t.productId.equals(productId) & t.shopId.equals(shopId));

    if (batchId == null) {
      query.where((t) => t.batchId.isNull());
    } else {
      query.where((t) => t.batchId.equals(batchId));
    }

    return query.getSingleOrNull();
  }

  /// 获取所有库存
  Future<List<StockData>> getAllInventory() async {
    try {
      return await select(stock).get();
    } catch (e) {
      print('📦 DAO层：获取所有库存数据失败: $e');
      // 如果标准查询失败，尝试使用原始 SQL 过滤有问题的记录
      try {
        final result = await customSelect(
          'SELECT id, product_id, batch_id, quantity, average_unit_price_in_sis, shop_id, '
          'datetime(COALESCE(created_at, CURRENT_TIMESTAMP)) as created_at, '
          'datetime(COALESCE(updated_at, CURRENT_TIMESTAMP)) as updated_at '
          'FROM stock WHERE id IS NOT NULL AND product_id IS NOT NULL',
          readsFrom: {stock},
        ).get();
        
        return result.map((row) {
          final createdAtStr = row.readNullable<String>('created_at');
          final updatedAtStr = row.readNullable<String>('updated_at');

          return StockData(
            id: row.read<int>('id'),
            productId: row.read<int>('product_id'),
            batchId: row.readNullable<int>('batch_id'),
            quantity: row.read<int>('quantity'),
            averageUnitPriceInSis: row.read<int>('average_unit_price_in_sis'),
            shopId: row.read<int>('shop_id'),
            createdAt: DateTime.tryParse(createdAtStr ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(updatedAtStr ?? '') ?? DateTime.now(),
          );
        }).toList();
      } catch (e2) {
        print('📦 DAO层：备用查询也失败: $e2');
        return [];
      }
    }
  }

  /// 根据店铺ID获取库存列表
  Future<List<StockData>> getInventoryByShop(int shopId) {
    return (select(
      stock,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据产品ID获取库存列表
  Future<List<StockData>> getInventoryByProduct(int productId) {
    return (select(
      stock,
    )..where((t) => t.productId.equals(productId))).get();
  }

  /// 监听所有库存变化
  Stream<List<StockData>> watchAllInventory() {
    return select(stock).watch();
  }

  /// 监听指定店铺的库存变化
  Stream<List<StockData>> watchInventoryByShop(int shopId) {
    return (select(
      stock,
    )..where((t) => t.shopId.equals(shopId))).watch();
  }

  /// 监听指定产品的库存变化
  Stream<List<StockData>> watchInventoryByProduct(int productId) {
    return (select(
      stock,
    )..where((t) => t.productId.equals(productId))).watch();
  }

  /// 更新库存
  Future<bool> updateInventory(StockCompanion inventory) async {
    final result = await (update(
      stock,
    )..where((t) => t.id.equals(inventory.id.value))).write(inventory);
    return result > 0;
  }

  /// 删除库存记录
  Future<int> deleteInventory(int id) {
    return (delete(stock)..where((t) => t.id.equals(id))).go();
  }

  /// 根据产品和店铺删除库存
  Future<int> deleteInventoryByProductAndShop(int productId, int shopId) {
    return (delete(stock)..where(
          (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
        ))
        .go();
  }

  /// 更新库存数量
  Future<bool> updateInventoryQuantity(
    int productId,
    int shopId,
    int quantity,
  ) async {
    final result =
        await (update(stock)..where(
              (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
            ))
            .write(
              StockCompanion(
                quantity: Value(quantity),
                updatedAt: Value(DateTime.now()),
              ),
            );
    return result > 0;
  }

  /// 原子增加库存数量（允许负库存，单SQL更新）
  Future<int> incrementQuantity(
    int productId,
    int shopId,
    int? batchId,
    int amount,
  ) async {
    if (batchId == null) {
      return await customUpdate(
  // Use milliseconds since epoch for updated_at to match Drift's int-backed DateTime
  'UPDATE stock SET quantity = quantity + ?, updated_at = CAST(strftime(\'%s\', \'now\') AS INTEGER) * 1000 '
        'WHERE product_id = ? AND shop_id = ? AND batch_id IS NULL',
        variables: [
          Variable.withInt(amount),
          Variable.withInt(productId),
          Variable.withInt(shopId),
        ],
        updates: {stock},
      );
    } else {
      return await customUpdate(
  // Use milliseconds since epoch for updated_at to match Drift's int-backed DateTime
  'UPDATE stock SET quantity = quantity + ?, updated_at = CAST(strftime(\'%s\', \'now\') AS INTEGER) * 1000 '
        'WHERE product_id = ? AND shop_id = ? AND batch_id = ?',
        variables: [
          Variable.withInt(amount),
          Variable.withInt(productId),
          Variable.withInt(shopId),
          Variable.withInt(batchId),
        ],
        updates: {stock},
      );
    }
  }

  /// 原子减少库存数量（允许负库存，不做 >=0 约束）
  Future<int> decrementQuantity(
    int productId,
    int shopId,
    int? batchId,
    int amount,
  ) async {
    if (batchId == null) {
      return await customUpdate(
  // Use milliseconds since epoch for updated_at to match Drift's int-backed DateTime
  'UPDATE stock SET quantity = quantity - ?, updated_at = CAST(strftime(\'%s\', \'now\') AS INTEGER) * 1000 '
        'WHERE product_id = ? AND shop_id = ? AND batch_id IS NULL',
        variables: [
          Variable.withInt(amount),
          Variable.withInt(productId),
          Variable.withInt(shopId),
        ],
        updates: {stock},
      );
    } else {
      return await customUpdate(
  // Use milliseconds since epoch for updated_at to match Drift's int-backed DateTime
  'UPDATE stock SET quantity = quantity - ?, updated_at = CAST(strftime(\'%s\', \'now\') AS INTEGER) * 1000 '
        'WHERE product_id = ? AND shop_id = ? AND batch_id = ?',
        variables: [
          Variable.withInt(amount),
          Variable.withInt(productId),
          Variable.withInt(shopId),
          Variable.withInt(batchId),
        ],
        updates: {stock},
      );
    }
  }

  /// 按批次更新库存数量（batchId 可为空）
  Future<bool> updateInventoryQuantityByBatch(
    int productId,
    int shopId,
    int? batchId,
    int quantity,
  ) async {
    final updater = update(stock)
      ..where((t) => t.productId.equals(productId) & t.shopId.equals(shopId));

    if (batchId == null) {
      updater.where((t) => t.batchId.isNull());
    } else {
      updater.where((t) => t.batchId.equals(batchId));
    }

    final result = await updater.write(
      StockCompanion(
        quantity: Value(quantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return result > 0;
  }

  /// 获取低库存产品列表
  Future<List<StockData>> getLowStockInventory(
    int shopId,
    int warningLevel,
  ) {
    return (select(stock)..where(
          (t) =>
              t.shopId.equals(shopId) &
              t.quantity.isSmallerOrEqualValue(warningLevel),
        ))
        .get();
  }

  /// 获取缺货产品列表
  Future<List<StockData>> getOutOfStockInventory(int shopId) {
    return (select(stock)..where(
          (t) => t.shopId.equals(shopId) & t.quantity.isSmallerOrEqualValue(0),
        ))
        .get();
  }

  /// 获取库存总数量（按店铺）
  Future<double> getTotalInventoryByShop(int shopId) async {
    final result =
        await (selectOnly(stock)
              ..addColumns([stock.quantity.sum().cast<double>()])
              ..where(stock.shopId.equals(shopId)))
            .getSingle();
    return result.read(stock.quantity.sum().cast<double>()) ?? 0.0;
  }

  /// 获取库存总数量（按产品）
  Future<double> getTotalInventoryByProduct(int productId) async {
    final result =
        await (selectOnly(stock)
              ..addColumns([stock.quantity.sum().cast<double>()])
              ..where(stock.productId.equals(productId)))
            .getSingle();
    return result.read(stock.quantity.sum().cast<double>()) ?? 0.0;
  }

  /// 检查库存是否存在
  Future<bool> inventoryExists(int productId, int shopId) async {
    // 使用受限查询判断是否存在，避免因多条记录导致的单行读取异常
    final rows = await (select(stock)
          ..where(
            (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
          )
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  /// 获取库存的移动加权平均价格
  Future<int> getAverageUnitPrice(int productId, int shopId, int? batchId) async {
    final stock = await getInventoryByProductShopAndBatch(productId, shopId, batchId);
    return stock?.averageUnitPriceInSis ?? 0;
  }

  /// 更新库存的移动加权平均价格
  Future<bool> updateAverageUnitPrice(
    int productId,
    int shopId,
    int? batchId,
    int averageUnitPriceInSis,
  ) async {
    final updater = update(stock)
      ..where((t) => t.productId.equals(productId) & t.shopId.equals(shopId));

    if (batchId == null) {
      updater.where((t) => t.batchId.isNull());
    } else {
      updater.where((t) => t.batchId.equals(batchId));
    }

    final result = await updater.write(
      StockCompanion(
        averageUnitPriceInSis: Value(averageUnitPriceInSis),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return result > 0;
  }

  /// 获取库存总价值（数量 × 移动加权平均价格）
  /// 只计算 averageUnitPriceInSis > 0 的库存
  Future<double> getTotalInventoryValue(int shopId) async {
    final result = await customSelect(
      'SELECT SUM(quantity * average_unit_price_in_sis) as total_value FROM stock WHERE shop_id = ? AND average_unit_price_in_sis > 0',
      variables: [Variable.withInt(shopId)],
      readsFrom: {stock},
    ).getSingleOrNull();
    
    final totalValueInCents = result?.read<int>('total_value') ?? 0;
    return totalValueInCents / 100.0; // 转换为元
  }

  /// 获取指定产品的库存总价值
  /// 只计算 averageUnitPriceInSis > 0 的库存
  Future<double> getProductInventoryValue(int productId) async {
    final result = await customSelect(
      'SELECT SUM(quantity * average_unit_price_in_sis) as total_value FROM stock WHERE product_id = ? AND average_unit_price_in_sis > 0',
      variables: [Variable.withInt(productId)],
      readsFrom: {stock},
    ).getSingleOrNull();
    
    final totalValueInCents = result?.read<int>('total_value') ?? 0;
    return totalValueInCents / 100.0; // 转换为元
  }
}
