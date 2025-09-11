import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/units_table.dart';

part 'unit_dao.g.dart';

/// 单位数据访问对象 (DAO)
/// 专门负责单位相关的数据库操作
@DriftAccessor(tables: [Unit])
class UnitDao extends DatabaseAccessor<AppDatabase> with _$UnitDaoMixin {
  UnitDao(super.db);

  /// 添加单位
  Future<int> insertUnit(UnitCompanion companion) async {
    return await into(db.unit).insert(companion);
  }

  /// 根据ID获取单位
  Future<UnitData?> getUnitById(int id) async {
    return await (select(
      db.unit,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据名称获取单位
  Future<UnitData?> getUnitByName(String name) async {
    return await (select(
      db.unit,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }

  /// 获取所有单位
  Future<List<UnitData>> getAllUnits() async {
    return await select(db.unit).get();
  }

  /// 监听所有单位变化
  Stream<List<UnitData>> watchAllUnits() {
    return select(db.unit).watch();
  }

  /// 更新单位
  Future<bool> updateUnit(UnitCompanion companion) async {
    final rowsAffected = await (update(
      db.unit,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除单位
  Future<int> deleteUnit(int id) async {
    print('💾 数据库层：删除单位，ID: $id');
    final result = await (delete(
      db.unit,
    )..where((tbl) => tbl.id.equals(id))).go();
    print('💾 数据库层：删除完成，影响行数: $result');
    return result;
  }

  /// 检查单位名称是否已存在
  Future<bool> isUnitNameExists(String name, [int? excludeId]) async {
    final query = select(db.unit)..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query.where((tbl) => tbl.id.isNotValue(excludeId));
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// 批量插入默认单位
  Future<void> insertDefaultUnits() async {
    final defaultUnitNames = [
      '个',
      '箱',
      '包',
      '公斤',
      '克',
      '升',
      '毫升',
    ];

    for (final name in defaultUnitNames) {
      final existing = await getUnitByName(name);
      if (existing == null) {
        await insertUnit(UnitCompanion.insert(name: name));
      }
    }
  }
}
