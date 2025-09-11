import '../../domain/repository/i_unit_repository.dart';
import '../../domain/model/unit.dart';
import '../../../../core/database/database.dart';
import '../dao/unit_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单位仓储实现类
/// 基于本地数据库的单位数据访问层实现
class UnitRepository implements IUnitRepository {
  final UnitDao _unitDao;
  UnitRepository(AppDatabase database) : _unitDao = database.unitDao;

  @override
  Future<Unit> addUnit(Unit unit) async {
    try {
      print('🗃️ 仓储层：添加单位，ID: ${unit.id}, 名称: ${unit.name}');
      final newId = await _unitDao.insertUnit(_unitToCompanion(unit));
      // 返回一个包含新ID的新Unit实例
      return unit.copyWith(id: newId);
    } catch (e) {
      print('🗃️ 仓储层：添加单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<Unit?> getUnitById(int id) async {
    try {
      final data = await _unitDao.getUnitById(id);
      return data != null ? _unitDataToModel(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据ID获取单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<Unit?> getUnitByName(String name) async {
    try {
      final data = await _unitDao.getUnitByName(name);
      return data != null ? _unitDataToModel(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据名称获取单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Unit>> getAllUnits() async {
    try {
      final dataList = await _unitDao.getAllUnits();
      return dataList.map(_unitDataToModel).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有单位失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Unit>> watchAllUnits() {
    try {
      return _unitDao.watchAllUnits().map((dataList) {
        return dataList.map(_unitDataToModel).toList();
      });
    } catch (e) {
      print('🗃️ 仓储层：监听所有单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateUnit(Unit unit) async {
    try {
      print('🗃️ 仓储层：更新单位，ID: ${unit.id}, 名称: ${unit.name}');
      return await _unitDao.updateUnit(_unitToCompanion(unit));
    } catch (e) {
      print('🗃️ 仓储层：更新单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteUnit(int id) async {
    try {
      print('🗃️ 仓储层：删除单位，ID: $id');
      final result = await _unitDao.deleteUnit(id);
      print('🗃️ 仓储层：删除完成，影响行数: $result');
      return result;
    } catch (e) {
      print('🗃️ 仓储层：删除单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isUnitNameExists(String name, [int? excludeId]) async {
    try {
      return await _unitDao.isUnitNameExists(name, excludeId);
    } catch (e) {
      print('🗃️ 仓储层：检查单位名称是否存在失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> insertDefaultUnits() async {
    try {
      print('🗃️ 仓储层：插入默认单位');
      await _unitDao.insertDefaultUnits();
      print('🗃️ 仓储层：默认单位插入完成');
    } catch (e) {
      print('🗃️ 仓储层：插入默认单位失败: $e');
      rethrow;
    }
  }

  /// 将 Unit 模型转换为 UnitCompanion
  UnitCompanion _unitToCompanion(Unit unit) {
    return UnitCompanion(
      id: unit.id == null ? const Value.absent() : Value(unit.id!),
      name: Value(unit.name),
    );
  }

  /// 将 UnitData 转换为 Unit 模型
  Unit _unitDataToModel(UnitData data) {
    return Unit(id: data.id, name: data.name);
  }
}

/// Unit Repository Provider
final unitRepositoryProvider = Provider<IUnitRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return UnitRepository(database);
});
