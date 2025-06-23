import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/barcodes_table.dart';

part 'barcode_dao.g.dart';

/// 条码数据访问对象 (DAO)
/// 专门负责条码相关的数据库操作
@DriftAccessor(tables: [BarcodesTable])
class BarcodeDao extends DatabaseAccessor<AppDatabase> with _$BarcodeDaoMixin {
  BarcodeDao(super.db);

  /// 添加条码
  Future<int> insertBarcode(BarcodesTableCompanion companion) async {
    return await into(db.barcodesTable).insert(companion);
  }

  /// 批量添加条码
  Future<void> insertMultipleBarcodes(
    List<BarcodesTableCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.barcodesTable, companions);
    });
  }

  /// 根据ID获取条码
  Future<BarcodesTableData?> getBarcodeById(String id) async {
    return await (select(
      db.barcodesTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据条码值获取条码信息
  Future<BarcodesTableData?> getBarcodeByValue(String barcode) async {
    return await (select(
      db.barcodesTable,
    )..where((tbl) => tbl.barcode.equals(barcode))).getSingleOrNull();
  }

  /// 根据产品单位ID获取所有条码
  Future<List<BarcodesTableData>> getBarcodesByProductUnitId(
    String productUnitId,
  ) async {
    return await (select(
      db.barcodesTable,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).get();
  }

  /// 获取所有条码
  Future<List<BarcodesTableData>> getAllBarcodes() async {
    return await select(db.barcodesTable).get();
  }

  /// 监听产品单位的条码变化
  Stream<List<BarcodesTableData>> watchBarcodesByProductUnitId(
    String productUnitId,
  ) {
    return (select(
      db.barcodesTable,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).watch();
  }

  /// 更新条码
  Future<bool> updateBarcode(BarcodesTableCompanion companion) async {
    final rowsAffected = await (update(
      db.barcodesTable,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除条码
  Future<int> deleteBarcode(String id) async {
    return await (delete(
      db.barcodesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 删除产品单位的所有条码
  Future<int> deleteBarcodesByProductUnitId(String productUnitId) async {
    return await (delete(
      db.barcodesTable,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).go();
  }

  /// 检查条码是否已存在
  Future<bool> barcodeExists(String barcode) async {
    final result =
        await (select(db.barcodesTable)
              ..where((tbl) => tbl.barcode.equals(barcode))
              ..limit(1))
            .get();
    return result.isNotEmpty;
  }

  /// 检查产品单位是否已有该条码
  Future<bool> productUnitHasBarcode(
    String productUnitId,
    String barcode,
  ) async {
    final result =
        await (select(db.barcodesTable)
              ..where(
                (tbl) =>
                    tbl.productUnitId.equals(productUnitId) &
                    tbl.barcode.equals(barcode),
              )
              ..limit(1))
            .get();
    return result.isNotEmpty;
  }

  /// 更新或插入条码（如果存在则更新，否则插入）
  Future<void> upsertBarcode(BarcodesTableCompanion companion) async {
    await into(db.barcodesTable).insertOnConflictUpdate(companion);
  }

  /// 批量更新或插入条码
  Future<void> upsertMultipleBarcodes(
    List<BarcodesTableCompanion> companions,
  ) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.insert(
          db.barcodesTable,
          companion,
          onConflict: DoUpdate((_) => companion),
        );
      }
    });
  }
}
