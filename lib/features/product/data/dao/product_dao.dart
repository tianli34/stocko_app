import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/products_table.dart';
import '../../../../core/database/barcodes_table.dart';
import '../../../../core/database/product_units_table.dart';
import '../../../../core/database/units_table.dart';
import '../../../../core/database/inventory_table.dart';

part 'product_dao.g.dart';

/// 产品数据访问对象 (DAO)
/// 专门负责产品相关的数据库操作
@DriftAccessor(
  tables: [Product, Barcode, UnitProduct, Unit, Stock],
)
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  /// 添加产品
  Future<int> insertProduct( ProductCompanion companion) async {
    return await into(db.product).insert(companion);
  }

  /// 根据ID获取产品
  Future<ProductData?> getProductById(int id) async {
    return await (select(
      db.product,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 监听单个产品的变化
  Stream<ProductData?> watchProductById(int id) {
    return (select(
      db.product,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// 获取所有产品
  Future<List<ProductData>> getAllProducts() async {
    return await select(db.product).get();
  }

  /// 监听所有产品变化
  Stream<List<ProductData>> watchAllProducts() {
    return select(db.product).watch();
  }

  /// 监听所有产品及其主单位的名称
  Stream<
    List<
      ({
        ProductData product,
        int unitId,
        String unitName,
        int conversionRate,
        int? sellingPriceInCents,
        int? wholesalePriceInCents
      })
    >
  >
  watchAllProductsWithUnit() {
    final query = select(db.product).join([
      leftOuterJoin(
        db.unitProduct,
        db.unitProduct.productId.equalsExp(db.product.id) &
            db.unitProduct.conversionRate.equals(1),
      ),
      leftOuterJoin(
        db.unit,
        db.unit.id.equalsExp(db.product.baseUnitId),
      ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        try {
          final product = row.readTable(db.product);
          final unit = row.readTableOrNull(db.unit);
          final unitProduct = row.readTableOrNull(db.unitProduct);
          
          // 安全地获取单位ID，确保不会出现数字解析错误
          int unitId;
          String unitName;
          
          if (unit != null) {
            unitId = unit.id;
            unitName = unit.name;
          } else {
            // 如果没有找到单位，使用产品的基础单位ID
            unitId = product.baseUnitId;
            unitName = '未知单位';
          }
          
          return (
            product: product,
            unitId: unitId,
            unitName: unitName,
            conversionRate: unitProduct?.conversionRate ?? 1,
            sellingPriceInCents: unitProduct?.sellingPriceInCents,
            wholesalePriceInCents: unitProduct?.wholesalePriceInCents,
          );
        } catch (e) {
          print('处理产品单位数据时出错: $e');
          // 返回一个安全的默认值
          final product = row.readTable(db.product);
          return (
            product: product,
            unitId: product.baseUnitId,
            unitName: '未知单位',
            conversionRate: 1,
            sellingPriceInCents: null,
            wholesalePriceInCents: null,
          );
        }
      }).toList();
    }).handleError((error) {
      print('监听产品及单位数据时出错: $error');
      return <({
        ProductData product,
        int unitId,
        String unitName,
        int conversionRate,
        int? sellingPriceInCents,
        int? wholesalePriceInCents
      })>[];
    });
  }

  /// 更新产品
  Future<bool> updateProduct( ProductCompanion companion) async {
    final rowsAffected = await (update(
      db.product,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
    return rowsAffected > 0;
  }

  /// 删除产品
  Future<int> deleteProduct(int id) async {
    print('💾 数据库层：删除产品，ID: $id');
    final result = await (delete(
      db.product,
    )..where((tbl) => tbl.id.equals(id))).go();
    print('💾 数据库层：删除完成，影响行数: $result');
    return result;
  }

  /// 根据条件查询产品
  Future<List<ProductData>> getProductsByCondition({
    int? categoryId,
    String? status,
    String? keyword,
  }) async {
    final query = select(db.product);

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
  Stream<List<ProductData>> watchProductsByCategory(int categoryId) {
    return (select(
      db.product,
    )..where((tbl) => tbl.categoryId.equals(categoryId))).watch();
  }

  /// 获取库存预警产品 (假设当前库存通过其他方式获取)
  Future<List<ProductData>> getStockWarningProducts() async {
    return await (select(
      db.product,
    )..where((tbl) => tbl.stockWarningValue.isNotNull())).get();
  }

  /// 批量插入产品
  Future<void> insertMultipleProducts(
    List< ProductCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.product, companions);
    });
  }

  /// 批量更新产品
  Future<void> updateMultipleProducts(
    List< ProductCompanion> companions,
  ) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.update(
          db.product,
          companion,
          where: (tbl) => tbl.id.equals(companion.id.value),
        );
      }
    });
  }

  /// 检查产品是否存在
  Future<bool> productExists(int id) async {
    final result =
        await (selectOnly(db.product)
              ..addColumns([db.product.id])
              ..where(db.product.id.equals(id)))
            .getSingleOrNull();
    return result != null;
  }

  /// 获取产品数量
  Future<int> getProductCount() async {
    final countExp = countAll();
    final query = selectOnly(db.product)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp)!;
  }

  /// 根据条码获取产品
  /// 通过条码表和产品单位表联查获取产品
  Future<ProductData?> getProductByBarcode(String barcode) async {
    // 首先在条码表中找到对应的产品单位ID
    final barcodeResult = await (select(
      db.barcode,
    )..where((tbl) => tbl.barcodeValue.equals(barcode))).getSingleOrNull();

    if (barcodeResult == null) {
      return null; // 条码不存在
    }

    // 然后在产品单位表中找到对应的产品ID
    final productUnitResult =
        await (select(db.unitProduct)..where(
              (tbl) => tbl.id.equals(barcodeResult.unitProductId),
            ))
            .getSingleOrNull();

    if (productUnitResult == null) {
      return null; // 产品单位不存在
    }

    // 最后获取产品信息
    return await (select(db.product)
          ..where((tbl) => tbl.id.equals(productUnitResult.productId)))
        .getSingleOrNull();
  }

  /// 根据条码获取产品及其单位信息
  /// 返回包含产品信息和单位名称的结果
  Future<
    ({
      ProductData product,
      int unitId,
      String unitName,
      int conversionRate,
      int? sellingPriceInCents,
      int? wholesalePriceInCents,
      int? averageUnitPriceInCents
    })?
  >
  getProductWithUnitByBarcode(String barcode) async {
    // 首先在条码表中找到对应的产品单位ID
    final barcodeResult = await (select(
      db.barcode,
    )..where((tbl) => tbl.barcodeValue.equals(barcode))).getSingleOrNull();

    if (barcodeResult == null) {
      return null; // 条码不存在
    }

    // 联合查询产品单位表、产品表和单位表
    final query =
        select(db.unitProduct).join([
          innerJoin(
            db.product,
            db.product.id.equalsExp(db.unitProduct.productId),
          ),
          innerJoin(
            db.unit,
            db.unit.id.equalsExp(db.unitProduct.unitId),
          ),
        ])..where(
          db.unitProduct.id.equals(
            barcodeResult.unitProductId,
          ),
        );

    final result = await query.getSingleOrNull();
    if (result == null) {
      return null;
    }

    final product = result.readTable(db.product);
    final unit = result.readTable(db.unit);
    final unitProduct = result.readTable(db.unitProduct);

    // 查询库存获取采购价（移动加权平均价）
    // 这里获取所有店铺的库存，取第一个有库存的店铺的采购价
    final stockQuery = select(db.stock)
      ..where((tbl) => tbl.productId.equals(product.id))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.quantity)])
      ..limit(1);
    
    final stock = await stockQuery.getSingleOrNull();
    final averageUnitPriceInCents = stock?.averageUnitPriceInCents;

    // 如果 UnitProduct 表中的售价为 null，则回退使用 Product 表中的价格
    // 优先级：UnitProduct.sellingPriceInCents > Product.retailPrice > Product.suggestedRetailPrice
    final int? effectiveSellingPrice = unitProduct.sellingPriceInCents 
        ?? product.retailPrice?.cents 
        ?? product.suggestedRetailPrice?.cents;

    return (
      product: product,
      unitId: unit.id,
      unitName: unit.name,
      conversionRate: unitProduct.conversionRate,
      sellingPriceInCents: effectiveSellingPrice,
      wholesalePriceInCents: unitProduct.wholesalePriceInCents,
      averageUnitPriceInCents: averageUnitPriceInCents,
    );
  }

  /// 检查单位是否被任何产品使用
  Future<bool> isUnitUsed(int unitId) async {
    final query = select(db.product)
      ..where((tbl) => tbl.baseUnitId.equals(unitId))
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null;
  }
}
