import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/products_table.dart';
import '../../../../core/database/barcodes_table.dart';
import '../../../../core/database/product_units_table.dart';

part 'product_dao.g.dart';

/// 产品数据访问对象 (DAO)
/// 专门负责产品相关的数据库操作
@DriftAccessor(tables: [ProductsTable, BarcodesTable, ProductUnitsTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  /// 添加产品
  Future<int> insertProduct(ProductsTableCompanion companion) async {
    return await into(db.productsTable).insert(companion);
  }

  /// 根据ID获取产品
  Future<ProductsTableData?> getProductById(String id) async {
    return await (select(
      db.productsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 获取所有产品
  Future<List<ProductsTableData>> getAllProducts() async {
    return await select(db.productsTable).get();
  }

  /// 监听所有产品变化
  Stream<List<ProductsTableData>> watchAllProducts() {
    return select(db.productsTable).watch();
  }

  /// 更新产品
  Future<bool> updateProduct(ProductsTableCompanion companion) async {
    final rowsAffected = await (update(
      db.productsTable,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除产品
  Future<int> deleteProduct(String id) async {
    print('💾 数据库层：删除产品，ID: $id');
    final result = await (delete(
      db.productsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
    print('💾 数据库层：删除完成，影响行数: $result');
    return result;
  }

  /// 根据条件查询产品
  Future<List<ProductsTableData>> getProductsByCondition({
    String? categoryId,
    String? status,
    String? keyword,
  }) async {
    final query = select(db.productsTable);

    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }

    if (status != null) {
      query.where((tbl) => tbl.status.equals(status));
    }
    if (keyword != null && keyword.isNotEmpty) {
      query.where(
        (tbl) =>
            tbl.name.contains(keyword) |
            // 条码搜索已移除，现在条码存储在独立的条码表中
            tbl.sku.contains(keyword),
      );
    }

    return await query.get();
  }

  /// 监听指定类别的产品
  Stream<List<ProductsTableData>> watchProductsByCategory(String categoryId) {
    return (select(
      db.productsTable,
    )..where((tbl) => tbl.categoryId.equals(categoryId))).watch();
  }

  /// 获取库存预警产品 (假设当前库存通过其他方式获取)
  Future<List<ProductsTableData>> getStockWarningProducts() async {
    return await (select(
      db.productsTable,
    )..where((tbl) => tbl.stockWarningValue.isNotNull())).get();
  }

  /// 批量插入产品
  Future<void> insertMultipleProducts(
    List<ProductsTableCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.productsTable, companions);
    });
  }

  /// 批量更新产品
  Future<void> updateMultipleProducts(
    List<ProductsTableCompanion> companions,
  ) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.update(
          db.productsTable,
          companion,
          where: (tbl) => tbl.id.equals(companion.id.value),
        );
      }
    });
  }

  /// 检查产品是否存在
  Future<bool> productExists(String id) async {
    final result =
        await (selectOnly(db.productsTable)
              ..addColumns([db.productsTable.id])
              ..where(db.productsTable.id.equals(id)))
            .getSingleOrNull();
    return result != null;
  }

  /// 获取产品数量
  Future<int> getProductCount() async {
    final countExp = countAll();
    final query = selectOnly(db.productsTable)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp)!;
  }

  /// 根据条码获取产品
  /// 通过条码表和产品单位表联查获取产品
  Future<ProductsTableData?> getProductByBarcode(String barcode) async {
    // 首先在条码表中找到对应的产品单位ID
    final barcodeResult = await (select(
      db.barcodesTable,
    )..where((tbl) => tbl.barcode.equals(barcode))).getSingleOrNull();

    if (barcodeResult == null) {
      return null; // 条码不存在
    }

    // 然后在产品单位表中找到对应的产品ID
    final productUnitResult =
        await (select(db.productUnitsTable)..where(
              (tbl) => tbl.productUnitId.equals(barcodeResult.productUnitId),
            ))
            .getSingleOrNull();

    if (productUnitResult == null) {
      return null; // 产品单位不存在
    }

    // 最后获取产品信息
    return await (select(db.productsTable)
          ..where((tbl) => tbl.id.equals(productUnitResult.productId)))
        .getSingleOrNull();
  }
}
