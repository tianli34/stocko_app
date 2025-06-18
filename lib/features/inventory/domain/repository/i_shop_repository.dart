import '../model/shop.dart';

/// 店铺仓储接口
/// 定义店铺相关的业务操作规范
abstract class IShopRepository {
  /// 添加店铺
  Future<int> addShop(Shop shop);

  /// 根据ID获取店铺
  Future<Shop?> getShopById(String id);

  /// 根据名称获取店铺
  Future<Shop?> getShopByName(String name);

  /// 获取所有店铺
  Future<List<Shop>> getAllShops();

  /// 监听所有店铺变化
  Stream<List<Shop>> watchAllShops();

  /// 更新店铺
  Future<bool> updateShop(Shop shop);

  /// 删除店铺
  Future<int> deleteShop(String id);

  /// 检查店铺名称是否已存在
  Future<bool> isShopNameExists(String name, [String? excludeId]);

  /// 根据名称搜索店铺
  Future<List<Shop>> searchShopsByName(String searchTerm);

  /// 根据店长搜索店铺
  Future<List<Shop>> searchShopsByManager(String managerName);

  /// 获取店铺数量
  Future<int> getShopCount();
}
