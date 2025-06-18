import '../model/location.dart';

/// 货位仓储接口
/// 定义货位相关的业务操作规范
abstract class ILocationRepository {
  /// 添加货位
  Future<int> addLocation(Location location);

  /// 根据ID获取货位
  Future<Location?> getLocationById(String id);

  /// 根据编码获取货位
  Future<Location?> getLocationByCode(String code, String shopId);

  /// 获取所有货位
  Future<List<Location>> getAllLocations();

  /// 根据店铺ID获取货位
  Future<List<Location>> getLocationsByShop(String shopId);

  /// 根据状态获取货位
  Future<List<Location>> getLocationsByStatus(String status);

  /// 获取活跃货位
  Future<List<Location>> getActiveLocationsByShop(String shopId);

  /// 监听所有货位变化
  Stream<List<Location>> watchAllLocations();

  /// 监听指定店铺的货位变化
  Stream<List<Location>> watchLocationsByShop(String shopId);

  /// 更新货位
  Future<bool> updateLocation(Location location);

  /// 删除货位
  Future<int> deleteLocation(String id);

  /// 检查货位编码是否已存在（同一店铺内）
  Future<bool> isLocationCodeExists(
    String code,
    String shopId, [
    String? excludeId,
  ]);

  /// 根据名称搜索货位
  Future<List<Location>> searchLocationsByName(String searchTerm);

  /// 获取货位总数
  Future<int> getLocationCount();

  /// 批量添加货位
  Future<void> addMultipleLocations(List<Location> locations);
}
