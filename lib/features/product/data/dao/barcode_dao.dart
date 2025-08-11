import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/barcodes_table.dart';

part 'barcode_dao.g.dart';

/// 条码数据访问对象 (DAO)
/// 专门负责条码相关的数据库操作
@DriftAccessor(tables: [Barcode])
class BarcodeDao extends DatabaseAccessor<AppDatabase> with _$BarcodeDaoMixin {
  BarcodeDao(super.db);

  /// 添加条码
  Future<int> insertBarcode(BarcodeCompanion companion) async {
    return await into(db.barcode).insert(companion);
  }

  /// 批量添加条码
  Future<void> insertMultipleBarcodes(
    List<BarcodeCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.barcode, companions);
    });
  }

  /// 根据ID获取条码
  Future<BarcodeData?> getBarcodeById(int id) async {
    return await (select(
      db.barcode,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据条码值获取条码信息
  Future<BarcodeData?> getBarcodeByValue(String barcode) async {
    return await (select(
      db.barcode,
    )..where((tbl) => tbl.barcodeValue.equals(barcode))).getSingleOrNull();
  }

  /// 根据产品单位ID获取所有条码
  Future<List<BarcodeData>> getBarcodesByProductUnitId(
    int productUnitId,
  ) async {
    return await (select(
      db.barcode,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).get();
  }

  /// 获取所有条码
  Future<List<BarcodeData>> getAllBarcodes() async {
    return await select(db.barcode).get();
  }

  /// 监听产品单位的条码变化
  Stream<List<BarcodeData>> watchBarcodesByProductUnitId(
    int productUnitId,
  ) {
    return (select(
      db.barcode,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).watch();
  }

  /// 更新条码
  Future<bool> updateBarcode(BarcodeCompanion companion) async {
    final rowsAffected = await (update(
      db.barcode,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除条码
  Future<int> deleteBarcode(int id) async {
    return await (delete(
      db.barcode,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 删除产品单位的所有条码
  Future<int> deleteBarcodesByProductUnitId(int productUnitId) async {
    return await (delete(
      db.barcode,
    )..where((tbl) => tbl.productUnitId.equals(productUnitId))).go();
  }

  /// 检查条码是否已存在
  Future<bool> barcodeExists(String barcode) async {
    final result =
        await (select(db.barcode)
              ..where((tbl) => tbl.barcodeValue.equals(barcode))
              ..limit(1))
            .get();
    return result.isNotEmpty;
  }

  /// 检查产品单位是否已有该条码
  Future<bool> productUnitHasBarcode(
    int productUnitId,
    String barcode,
  ) async {
    final result =
        await (select(db.barcode)
              ..where(
                (tbl) =>
                    tbl.productUnitId.equals(productUnitId) &
                    tbl.barcodeValue.equals(barcode),
              )
              ..limit(1))
            .get();
    return result.isNotEmpty;
  }

  /// 更新或插入条码（如果存在则更新，否则插入）
  Future<void> upsertBarcode(BarcodeCompanion companion) async {
    await into(db.barcode).insertOnConflictUpdate(companion);
  }

  /// 批量更新或插入条码
  Future<void> upsertMultipleBarcodes(
    List<BarcodeCompanion> companions,
  ) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.insert(
          db.barcode,
          companion,
          onConflict: DoUpdate((_) => companion),
        );
      }
    });
  }
}
