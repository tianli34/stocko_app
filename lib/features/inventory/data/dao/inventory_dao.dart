import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inventory_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [InventoryTable])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  /// 插入库存记录
  Future<int> insertInventory(InventoryTableCompanion inventory) {
    return into(inventoryTable).insert(inventory);
  }

  /// 根据ID获取库存
  Future<InventoryTableData?> getInventoryById(String id) {
    return (select(
      inventoryTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据产品ID和店铺ID获取库存
  Future<InventoryTableData?> getInventoryByProductAndShop(
    String productId,
    String shopId,
  ) {
    return (select(inventoryTable)..where(
          (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
        ))
        .getSingleOrNull();
  }

  /// 获取所有库存
  Future<List<InventoryTableData>> getAllInventory() {
    return select(inventoryTable).get();
  }

  /// 根据店铺ID获取库存列表
  Future<List<InventoryTableData>> getInventoryByShop(String shopId) {
    return (select(
      inventoryTable,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据产品ID获取库存列表
  Future<List<InventoryTableData>> getInventoryByProduct(String productId) {
    return (select(
      inventoryTable,
    )..where((t) => t.productId.equals(productId))).get();
  }

  /// 监听所有库存变化
  Stream<List<InventoryTableData>> watchAllInventory() {
    return select(inventoryTable).watch();
  }

  /// 监听指定店铺的库存变化
  Stream<List<InventoryTableData>> watchInventoryByShop(String shopId) {
    return (select(
      inventoryTable,
    )..where((t) => t.shopId.equals(shopId))).watch();
  }

  /// 监听指定产品的库存变化
  Stream<List<InventoryTableData>> watchInventoryByProduct(String productId) {
    return (select(
      inventoryTable,
    )..where((t) => t.productId.equals(productId))).watch();
  }

  /// 更新库存
  Future<bool> updateInventory(InventoryTableCompanion inventory) async {
    final result = await (update(
      inventoryTable,
    )..where((t) => t.id.equals(inventory.id.value))).write(inventory);
    return result > 0;
  }

  /// 删除库存记录
  Future<int> deleteInventory(String id) {
    return (delete(inventoryTable)..where((t) => t.id.equals(id))).go();
  }

  /// 根据产品和店铺删除库存
  Future<int> deleteInventoryByProductAndShop(String productId, String shopId) {
    return (delete(inventoryTable)..where(
          (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
        ))
        .go();
  }

  /// 更新库存数量
  Future<bool> updateInventoryQuantity(
    String productId,
    String shopId,
    double quantity,
  ) async {
    final result =
        await (update(inventoryTable)..where(
              (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
            ))
            .write(
              InventoryTableCompanion(
                quantity: Value(quantity),
                updatedAt: Value(DateTime.now()),
              ),
            );
    return result > 0;
  }

  /// 获取低库存产品列表
  Future<List<InventoryTableData>> getLowStockInventory(
    String shopId,
    int warningLevel,
  ) {
    return (select(inventoryTable)..where(
          (t) =>
              t.shopId.equals(shopId) &
              t.quantity.isSmallerOrEqualValue(warningLevel.toDouble()),
        ))
        .get();
  }

  /// 获取缺货产品列表
  Future<List<InventoryTableData>> getOutOfStockInventory(String shopId) {
    return (select(inventoryTable)..where(
          (t) => t.shopId.equals(shopId) & t.quantity.isSmallerOrEqualValue(0),
        ))
        .get();
  }

  /// 获取库存总数量（按店铺）
  Future<double> getTotalInventoryByShop(String shopId) async {
    final result =
        await (selectOnly(inventoryTable)
              ..addColumns([inventoryTable.quantity.sum()])
              ..where(inventoryTable.shopId.equals(shopId)))
            .getSingle();
    return result.read(inventoryTable.quantity.sum()) ?? 0.0;
  }

  /// 获取库存总数量（按产品）
  Future<double> getTotalInventoryByProduct(String productId) async {
    final result =
        await (selectOnly(inventoryTable)
              ..addColumns([inventoryTable.quantity.sum()])
              ..where(inventoryTable.productId.equals(productId)))
            .getSingle();
    return result.read(inventoryTable.quantity.sum()) ?? 0.0;
  }

  /// 检查库存是否存在
  Future<bool> inventoryExists(String productId, String shopId) async {
    final result = await getInventoryByProductAndShop(productId, shopId);
    return result != null;
  }
}
