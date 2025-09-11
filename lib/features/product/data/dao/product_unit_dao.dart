import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/product_units_table.dart';

part 'product_unit_dao.g.dart';

/// 产品单位数据访问对象 (DAO)
/// 专门负责产品单位关联相关的数据库操作
@DriftAccessor(tables: [UnitProduct])
class ProductUnitDao extends DatabaseAccessor<AppDatabase>
    with _$ProductUnitDaoMixin {
  ProductUnitDao(super.db);

  /// 添加产品单位
  Future<int> insertProductUnit(UnitProductCompanion companion) async {
    return await into(db.unitProduct).insert(companion);
  }

  /// 批量添加产品单位
  Future<void> insertMultipleProductUnits(
    List<UnitProductCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.unitProduct, companions);
    });
  }

  /// 根据产品单位ID获取产品单位
  Future<UnitProductData?> getProductUnitById(
    int id,
  ) async {
    return await (select(db.unitProduct)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据产品ID获取所有产品单位
  Future<List<UnitProductData>> getProductUnitsByProductId(
    int productId,
  ) async {
    return await (select(
      db.unitProduct,
    )..where((tbl) => tbl.productId.equals(productId))).get();
  }

  /// 获取所有产品单位
  Future<List<UnitProductData>> getAllProductUnits() async {
    return await select(db.unitProduct).get();
  }

  /// 监听产品的所有单位变化
  Stream<List<UnitProductData>> watchProductUnitsByProductId(
    int productId,
  ) {
    return (select(
      db.unitProduct,
    )..where((tbl) => tbl.productId.equals(productId))).watch();
  }

  /// 更新产品单位
  Future<bool> updateProductUnit(UnitProductCompanion companion) async {
    final rowsAffected =
        await (update(db.unitProduct)..where(
              (tbl) => tbl.id.equals(companion.id.value),
            ))
            .write(companion);
    return rowsAffected > 0;
  }

  /// 删除产品单位
  Future<int> deleteProductUnit(int id) async {
    return await (delete(
      db.unitProduct,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 删除产品的所有单位
  Future<int> deleteProductUnitsByProductId(int productId) async {
    return await (delete(
      db.unitProduct,
    )..where((tbl) => tbl.productId.equals(productId))).go();
  }

  /// 检查产品是否已配置某个单位
  Future<bool> isUnitConfiguredForProduct(
    int productId,
    int unitId,
  ) async {
    final result =
        await (select(db.unitProduct)..where(
              (tbl) =>
                  tbl.productId.equals(productId) & tbl.unitId.equals(unitId),
            ))
            .getSingleOrNull();
    return result != null;
  }

  /// 获取产品的基础单位（换算率为1.0的单位）
  Future<UnitProductData?> getBaseUnitForProduct(int productId) async {
    return await (select(db.unitProduct)..where(
          (tbl) =>
              tbl.productId.equals(productId) & tbl.conversionRate.equals(1),
        ))
        .getSingleOrNull();
  }

  /// 更新或插入产品单位（如果存在则更新，否则插入）
  Future<void> upsertProductUnit(UnitProductCompanion companion) async {
    await into(db.unitProduct).insertOnConflictUpdate(companion);
  }

  /// 批量更新或插入产品单位
  Future<void> upsertMultipleProductUnits(
    List<UnitProductCompanion> companions,
  ) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.insert(
          db.unitProduct,
          companion,
          onConflict: DoUpdate((_) => companion),
        );
      }
    });
  }
}
