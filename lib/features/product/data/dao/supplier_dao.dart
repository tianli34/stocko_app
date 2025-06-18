import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/suppliers_table.dart';

part 'supplier_dao.g.dart';

/// 供应商数据访问对象 (DAO)
/// 专门负责供应商相关的数据库操作
@DriftAccessor(tables: [SuppliersTable])
class SupplierDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierDaoMixin {
  SupplierDao(super.db);

  /// 添加供应商
  Future<int> insertSupplier(SuppliersTableCompanion companion) async {
    return await into(db.suppliersTable).insert(companion);
  }

  /// 根据ID获取供应商
  Future<SuppliersTableData?> getSupplierById(String id) async {
    return await (select(
      db.suppliersTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据名称获取供应商
  Future<SuppliersTableData?> getSupplierByName(String name) async {
    return await (select(
      db.suppliersTable,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }

  /// 获取所有供应商
  Future<List<SuppliersTableData>> getAllSuppliers() async {
    return await select(db.suppliersTable).get();
  }

  /// 监听所有供应商变化
  Stream<List<SuppliersTableData>> watchAllSuppliers() {
    return select(db.suppliersTable).watch();
  }

  /// 更新供应商
  Future<bool> updateSupplier(SuppliersTableCompanion companion) async {
    final rowsAffected = await (update(
      db.suppliersTable,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除供应商
  Future<bool> deleteSupplier(String id) async {
    final rowsAffected = await (delete(
      db.suppliersTable,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// 根据名称搜索供应商
  Future<List<SuppliersTableData>> searchSuppliersByName(
    String searchTerm,
  ) async {
    return await (select(
      db.suppliersTable,
    )..where((tbl) => tbl.name.like('%$searchTerm%'))).get();
  }

  /// 检查供应商是否存在
  Future<bool> supplierExists(String name) async {
    final result =
        await (selectOnly(db.suppliersTable)
              ..addColumns([db.suppliersTable.id])
              ..where(db.suppliersTable.name.equals(name)))
            .getSingleOrNull();
    return result != null;
  }

  /// 获取供应商数量
  Future<int> getSupplierCount() async {
    final countQuery = selectOnly(db.suppliersTable)
      ..addColumns([db.suppliersTable.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(db.suppliersTable.id.count()) ?? 0;
  }
}
