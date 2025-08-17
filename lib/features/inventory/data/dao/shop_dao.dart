import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/shops_table.dart';

part 'shop_dao.g.dart';

@DriftAccessor(tables: [Shop])
class ShopDao extends DatabaseAccessor<AppDatabase> with _$ShopDaoMixin {
  ShopDao(super.db);

  /// 插入店铺
  Future<int> insertShop(ShopCompanion shop) {
    return into(db.shop).insert(shop);
  }

  /// 根据ID获取店铺
  Future<ShopData?> getShopById(int id) {
    return (select(
      shop,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据名称获取店铺
  Future<ShopData?> getShopByName(String name) {
    return (select(
      shop,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  /// 获取所有店铺
  Future<List<ShopData>> getAllShops() {
    return select(shop).get();
  }

  /// 监听所有店铺变化
  Stream<List<ShopData>> watchAllShops() {
    return select(shop).watch();
  }

  /// 更新店铺
  Future<bool> updateShop(ShopCompanion shop) async {
    final result = await (update(
      db.shop,
    )..where((t) => t.id.equals(shop.id.value))).write(shop);
    return result > 0;
  }

  /// 删除店铺
  Future<int> deleteShop(int id) {
    return (delete(shop)..where((t) => t.id.equals(id))).go();
  }

  /// 根据名称搜索店铺（模糊搜索）
  Future<List<ShopData>> searchShopsByName(String searchTerm) {
    return (select(
      shop,
    )..where((t) => t.name.like('%$searchTerm%'))).get();
  }

  /// 根据店长搜索店铺（模糊搜索）
  Future<List<ShopData>> searchShopsByManager(String managerName) {
    return (select(
      shop,
    )..where((t) => t.manager.like('%$managerName%'))).get();
  }

  /// 检查店铺名称是否存在（排除指定ID）
  Future<bool> isShopNameExists(String name, [int? excludeId]) async {
    var query = select(shop)..where((t) => t.name.equals(name));

    if (excludeId != null) {
      query = query..where((t) => t.id.isNotValue(excludeId));
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// 获取店铺数量
  Future<int> getShopCount() async {
    final result = await (selectOnly(
      shop,
    )..addColumns([shop.id.count()])).getSingle();
    return result.read(shop.id.count()) ?? 0;
  }
}
