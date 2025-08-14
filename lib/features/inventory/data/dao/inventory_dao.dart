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
    String shopId,
  ) {
    return (select(stock)..where(
          (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
        ))
        .getSingleOrNull();
  }

  /// 获取所有库存
  Future<List<StockData>> getAllInventory() {
    return select(stock).get();
  }

  /// 根据店铺ID获取库存列表
  Future<List<StockData>> getInventoryByShop(String shopId) {
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
  Stream<List<StockData>> watchInventoryByShop(String shopId) {
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
  Future<int> deleteInventoryByProductAndShop(int productId, String shopId) {
    return (delete(stock)..where(
          (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
        ))
        .go();
  }

  /// 更新库存数量
  Future<bool> updateInventoryQuantity(
    int productId,
    String shopId,
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

  /// 获取低库存产品列表
  Future<List<StockData>> getLowStockInventory(
    String shopId,
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
  Future<List<StockData>> getOutOfStockInventory(String shopId) {
    return (select(stock)..where(
          (t) => t.shopId.equals(shopId) & t.quantity.isSmallerOrEqualValue(0),
        ))
        .get();
  }

  /// 获取库存总数量（按店铺）
  Future<double> getTotalInventoryByShop(String shopId) async {
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
  Future<bool> inventoryExists(int productId, String shopId) async {
    final result = await getInventoryByProductAndShop(productId, shopId);
    return result != null;
  }
}
