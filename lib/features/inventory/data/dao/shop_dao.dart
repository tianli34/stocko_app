import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/shops_table.dart';

part 'shop_dao.g.dart';

@DriftAccessor(tables: [ShopsTable])
class ShopDao extends DatabaseAccessor<AppDatabase> with _$ShopDaoMixin {
  ShopDao(super.db);

  /// 插入店铺
  Future<int> insertShop(ShopsTableCompanion shop) {
    return into(shopsTable).insert(shop);
  }

  /// 根据ID获取店铺
  Future<ShopsTableData?> getShopById(String id) {
    return (select(
      shopsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据名称获取店铺
  Future<ShopsTableData?> getShopByName(String name) {
    return (select(
      shopsTable,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  /// 获取所有店铺
  Future<List<ShopsTableData>> getAllShops() {
    return select(shopsTable).get();
  }

  /// 监听所有店铺变化
  Stream<List<ShopsTableData>> watchAllShops() {
    return select(shopsTable).watch();
  }

  /// 更新店铺
  Future<bool> updateShop(ShopsTableCompanion shop) async {
    final result = await (update(
      shopsTable,
    )..where((t) => t.id.equals(shop.id.value))).write(shop);
    return result > 0;
  }

  /// 删除店铺
  Future<int> deleteShop(String id) {
    return (delete(shopsTable)..where((t) => t.id.equals(id))).go();
  }

  /// 根据名称搜索店铺（模糊搜索）
  Future<List<ShopsTableData>> searchShopsByName(String searchTerm) {
    return (select(
      shopsTable,
    )..where((t) => t.name.like('%$searchTerm%'))).get();
  }

  /// 根据店长搜索店铺（模糊搜索）
  Future<List<ShopsTableData>> searchShopsByManager(String managerName) {
    return (select(
      shopsTable,
    )..where((t) => t.manager.like('%$managerName%'))).get();
  }

  /// 检查店铺名称是否存在（排除指定ID）
  Future<bool> isShopNameExists(String name, [String? excludeId]) async {
    var query = select(shopsTable)..where((t) => t.name.equals(name));

    if (excludeId != null) {
      query = query..where((t) => t.id.isNotValue(excludeId));
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// 获取店铺数量
  Future<int> getShopCount() async {
    final result = await (selectOnly(
      shopsTable,
    )..addColumns([shopsTable.id.count()])).getSingle();
    return result.read(shopsTable.id.count()) ?? 0;
  }
}
