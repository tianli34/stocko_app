import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/units_table.dart';

part 'unit_dao.g.dart';

/// 单位数据访问对象 (DAO)
/// 专门负责单位相关的数据库操作
@DriftAccessor(tables: [UnitsTable])
class UnitDao extends DatabaseAccessor<AppDatabase> with _$UnitDaoMixin {
  UnitDao(super.db);

  /// 添加单位
  Future<int> insertUnit(UnitsTableCompanion companion) async {
    return await into(db.unitsTable).insert(companion);
  }

  /// 根据ID获取单位
  Future<UnitsTableData?> getUnitById(String id) async {
    return await (select(
      db.unitsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据名称获取单位
  Future<UnitsTableData?> getUnitByName(String name) async {
    return await (select(
      db.unitsTable,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }

  /// 获取所有单位
  Future<List<UnitsTableData>> getAllUnits() async {
    return await select(db.unitsTable).get();
  }

  /// 监听所有单位变化
  Stream<List<UnitsTableData>> watchAllUnits() {
    return select(db.unitsTable).watch();
  }

  /// 更新单位
  Future<bool> updateUnit(UnitsTableCompanion companion) async {
    final rowsAffected = await (update(
      db.unitsTable,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除单位
  Future<int> deleteUnit(String id) async {
    print('💾 数据库层：删除单位，ID: $id');
    final result = await (delete(
      db.unitsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
    print('💾 数据库层：删除完成，影响行数: $result');
    return result;
  }

  /// 检查单位名称是否已存在
  Future<bool> isUnitNameExists(String name, [String? excludeId]) async {
    final query = select(db.unitsTable)..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query.where((tbl) => tbl.id.isNotValue(excludeId));
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// 批量插入默认单位
  Future<void> insertDefaultUnits() async {
    final defaultUnits = [
      UnitsTableCompanion.insert(id: 'unit_piece', name: '个'),
      UnitsTableCompanion.insert(id: 'unit_box', name: '箱'),
      UnitsTableCompanion.insert(id: 'unit_pack', name: '包'),
      UnitsTableCompanion.insert(id: 'unit_kg', name: '公斤'),
      UnitsTableCompanion.insert(id: 'unit_gram', name: '克'),
      UnitsTableCompanion.insert(id: 'unit_liter', name: '升'),
      UnitsTableCompanion.insert(id: 'unit_ml', name: '毫升'),
    ];

    for (final unit in defaultUnits) {
      final existing = await getUnitById(unit.id.value);
      if (existing == null) {
        await insertUnit(unit);
      }
    }
  }
}
