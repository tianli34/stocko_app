import '../model/unit.dart';

/// 单位仓储接口
/// 定义单位相关的业务操作规范
abstract class IUnitRepository {
  /// 添加单位
  Future<int> addUnit(Unit unit);

  /// 根据ID获取单位
  Future<Unit?> getUnitById(String id);

  /// 根据名称获取单位
  Future<Unit?> getUnitByName(String name);

  /// 获取所有单位
  Future<List<Unit>> getAllUnits();

  /// 监听所有单位变化
  Stream<List<Unit>> watchAllUnits();

  /// 更新单位
  Future<bool> updateUnit(Unit unit);

  /// 删除单位
  Future<int> deleteUnit(String id);

  /// 检查单位名称是否已存在
  Future<bool> isUnitNameExists(String name, [String? excludeId]);

  /// 批量插入默认单位
  Future<void> insertDefaultUnits();
}
