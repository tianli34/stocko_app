import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/product_suppliers_table.dart';

part 'product_supplier_dao.g.dart';

@DriftAccessor(tables: [ProductSuppliersTable])
class ProductSupplierDao extends DatabaseAccessor<AppDatabase>
    with _$ProductSupplierDaoMixin {
  ProductSupplierDao(super.db);

  /// 获取所有货品供应商关联记录
  Future<List<ProductSuppliersTableData>> getAllProductSuppliers() =>
      select(productSuppliersTable).get();

  /// 根据商品ID获取供应商（按单位分组）
  Future<List<ProductSuppliersTableData>> getSuppliersByProductId(
    int productId,
  ) {
    return (select(
      productSuppliersTable,
    )..where((tbl) => tbl.productId.equals(productId))).get();
  }

  /// 根据商品ID和单位ID获取供应商
  Future<List<ProductSuppliersTableData>> getSuppliersByProductIdAndUnitId(
    int productId,
    int unitId,
  ) {
    return (select(productSuppliersTable)..where(
          (tbl) => tbl.productId.equals(productId) & tbl.unitId.equals(unitId),
        ))
        .get();
  }

  /// 根据供应商ID获取商品
  Future<List<ProductSuppliersTableData>> getProductsBySupplierId(
    int supplierId,
  ) {
    return (select(
      productSuppliersTable,
    )..where((tbl) => tbl.supplierId.equals(supplierId))).get();
  }

  /// 获取商品指定单位的主要供应商
  Future<ProductSuppliersTableData?> getPrimarySupplierByProductIdAndUnitId(
    int productId,
    int unitId,
  ) {
    return (select(productSuppliersTable)..where(
          (tbl) =>
              tbl.productId.equals(productId) &
              tbl.unitId.equals(unitId) &
              tbl.isPrimary.equals(true) &
              tbl.status.equals('active'),
        ))
        .getSingleOrNull();
  }

  /// 获取商品的主要供应商（所有单位）
  Future<ProductSuppliersTableData?> getPrimarySupplierByProductId(
    int productId,
  ) {
    return (select(productSuppliersTable)..where(
          (tbl) =>
              tbl.productId.equals(productId) &
              tbl.isPrimary.equals(true) &
              tbl.status.equals('active'),
        ))
        .getSingleOrNull();
  }

  /// 添加货品供应商关联
  Future<int> insertProductSupplier(ProductSuppliersTableCompanion entry) {
    return into(productSuppliersTable).insert(entry);
  }

  /// 更新货品供应商关联
  Future<bool> updateProductSupplier(ProductSuppliersTableData entry) {
    return update(productSuppliersTable).replace(entry);
  }

  /// 删除货品供应商关联
  Future<int> deleteProductSupplier(String id) {
    return (delete(
      productSuppliersTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 删除商品的所有供应商关联
  Future<int> deleteProductSuppliersByProductId(int productId) {
    return (delete(
      productSuppliersTable,
    )..where((tbl) => tbl.productId.equals(productId))).go();
  }

  /// 删除供应商的所有商品关联
  Future<int> deleteProductSuppliersBySupplierId(int supplierId) {
    return (delete(
      productSuppliersTable,
    )..where((tbl) => tbl.supplierId.equals(supplierId))).go();
  }

  /// 设置商品指定单位的主要供应商（会将该单位的其他供应商设为非主要）
  Future<void> setPrimarySupplierForUnit(
    int productId,
    int unitId,
    int supplierId,
  ) async {
    await transaction(() async {
      // 先将该商品该单位的所有供应商设为非主要
      await (update(productSuppliersTable)..where(
            (tbl) =>
                tbl.productId.equals(productId) & tbl.unitId.equals(unitId),
          ))
          .write(
            const ProductSuppliersTableCompanion(
              isPrimary: Value(false),
              updatedAt: Value.absent(),
            ),
          );

      // 然后将指定供应商设为主要
      await (update(productSuppliersTable)..where(
            (tbl) =>
                tbl.productId.equals(productId) &
                tbl.unitId.equals(unitId) &
                tbl.supplierId.equals(supplierId),
          ))
          .write(
            ProductSuppliersTableCompanion(
              isPrimary: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  /// 设置商品的主要供应商（会将其他供应商设为非主要）
  Future<void> setPrimarySupplier(int productId, int supplierId) async {
    await transaction(() async {
      // 先将该商品的所有供应商设为非主要
      await (update(
        productSuppliersTable,
      )..where((tbl) => tbl.productId.equals(productId))).write(
        const ProductSuppliersTableCompanion(
          isPrimary: Value(false),
          updatedAt: Value.absent(),
        ),
      );

      // 然后将指定供应商设为主要
      await (update(productSuppliersTable)..where(
            (tbl) =>
                tbl.productId.equals(productId) &
                tbl.supplierId.equals(supplierId),
          ))
          .write(
            ProductSuppliersTableCompanion(
              isPrimary: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  /// 检查货品供应商关联是否存在（指定单位）
  Future<bool> existsProductSupplierWithUnit(
    int productId,
    int supplierId,
    int unitId,
  ) async {
    final count =
        await (selectOnly(productSuppliersTable)
              ..addColumns([productSuppliersTable.id.count()])
              ..where(
                productSuppliersTable.productId.equals(productId) &
                    productSuppliersTable.supplierId.equals(supplierId) &
                    productSuppliersTable.unitId.equals(unitId),
              ))
            .getSingle();
    return count.read(productSuppliersTable.id.count())! > 0;
  }

  /// 检查货品供应商关联是否存在（任意单位）
  Future<bool> existsProductSupplier(
    int productId,
    int supplierId,
  ) async {
    final count =
        await (selectOnly(productSuppliersTable)
              ..addColumns([productSuppliersTable.id.count()])
              ..where(
                productSuppliersTable.productId.equals(productId) &
                    productSuppliersTable.supplierId.equals(supplierId),
              ))
            .getSingle();
    return count.read(productSuppliersTable.id.count())! > 0;
  }

  /// 根据ID获取货品供应商关联
  Future<ProductSuppliersTableData?> getProductSupplierById(String id) {
    return (select(
      productSuppliersTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 获取有效的货品供应商关联
  Future<List<ProductSuppliersTableData>> getActiveProductSuppliers() {
    return (select(
      productSuppliersTable,
    )..where((tbl) => tbl.status.equals('active'))).get();
  }
}
