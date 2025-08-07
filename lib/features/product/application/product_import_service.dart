import 'package:drift/drift.dart';

// 导入数据库定义文件和所有表
import '../../../core/database/database.dart';

/// 一个服务类，用于处理从外部数据源批量导入商品。
class ProductImportService {
  final AppDatabase db;

  ProductImportService(this.db);

  /// 根据名称查找或创建一个分类，并返回其ID。
  Future<String> _getOrCreateCategory(String name) async {
    // 1. 尝试查找已存在的分类
    final existingCategory = await (db.select(
      db.categoriesTable,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();

    if (existingCategory != null) {
      return existingCategory.id; // 2. 如果找到，返回其ID
    } else {
      // 3. 如果没找到，创建一个新的
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final companion = CategoriesTableCompanion.insert(id: newId, name: name);
      await db.into(db.categoriesTable).insert(companion);
      return newId;
    }
  }

  /// 根据名称查找或创建一个单位，并返回其ID。
  Future<String> _getOrCreateUnit(String name) async {
    final existingUnit = await (db.select(
      db.unitsTable,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();

    if (existingUnit != null) {
      return existingUnit.id;
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final companion = UnitsTableCompanion.insert(id: newId, name: name);
      await db.into(db.unitsTable).insert(companion);
      return newId;
    }
  }

  double _parsePrice(String priceString) {
    // 使用正则表达式从字符串中提取价格数值
    // 这个表达式匹配第一个出现的数字序列（可以包含一个小数点）
    final match = RegExp(r'\d+\.?\d*').firstMatch(priceString);
    if (match != null) {
      // group(0) 返回整个匹配的字符串，例如 "50.00"
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  /// 从一个原始数据Map列表中批量插入商品。
  Future<String?> bulkInsertProducts(
    List<Map<String, dynamic>> rawProductsData,
  ) async {
    if (rawProductsData.isEmpty) return '没有需要导入的数据。';

    // --- 步骤 1: 预处理，收集所有唯一的品牌和单位名称 ---
    final categoryNames = rawProductsData
        .map((data) => data['品牌'] as String)
        .toSet();
    final unitNames = {'包', '条'}; // 根据需求固定

    // --- 步骤 2: 一次性查找或创建所有需要的ID，并存入Map ---
    final categoryIdMap = <String, String>{};
    for (final name in categoryNames) {
      categoryIdMap[name] = await _getOrCreateCategory(name);
    }

    final unitIdMap = <String, String>{};
    for (final name in unitNames) {
      unitIdMap[name] = await _getOrCreateUnit(name);
    }

    final packUnitId = unitIdMap['包']!;
    final cartonUnitId = unitIdMap['条']!;

    // --- 新增步骤: 预检查条码唯一性 ---
    final allBarcodes = <String>[];
    final duplicateBarcodesInFile = <String>{};
    final seenBarcodes = <String>{};

    for (final productData in rawProductsData) {
      final packBarcode = productData['包条码'] as String?;
      final cartonBarcode = productData['条条码'] as String?;

      if (packBarcode != null && packBarcode.isNotEmpty) {
        if (seenBarcodes.contains(packBarcode)) {
          duplicateBarcodesInFile.add(packBarcode);
        }
        seenBarcodes.add(packBarcode);
        allBarcodes.add(packBarcode);
      }
      if (cartonBarcode != null &&
          cartonBarcode.isNotEmpty &&
          cartonBarcode != packBarcode) {
        if (seenBarcodes.contains(cartonBarcode)) {
          duplicateBarcodesInFile.add(cartonBarcode);
        }
        seenBarcodes.add(cartonBarcode);
        allBarcodes.add(cartonBarcode);
      }
    }

    if (duplicateBarcodesInFile.isNotEmpty) {
      return '导入失败：文件中发现重复条码: ${duplicateBarcodesInFile.join(', ')}。请修正数据后重试。';
    }

    if (allBarcodes.isNotEmpty) {
      final existingBarcodes = await (db.select(
        db.barcodesTable,
      )..where((t) => t.barcode.isIn(allBarcodes))).get();

      if (existingBarcodes.isNotEmpty) {
        final existingBarcodeValues = existingBarcodes
            .map((b) => b.barcode)
            .join(', ');
        return '导入失败：以下条码已存在于数据库中: $existingBarcodeValues。请修正数据后重试。';
      }
    }
    // --- 预检查结束 ---

    // --- 步骤 3: 执行高效的批量插入 ---
    try {
      await db.batch((batch) {
        for (final productData in rawProductsData) {
          final productId =
              DateTime.now().millisecondsSinceEpoch; // 使用时间戳作为临时ID
          final productName = productData['货品名称'] as String;
          final brand = productData['品牌'] as String;
          final categoryId = categoryIdMap[brand]!; // 从Map中快速获取ID

          final cartonSuggestedRetailPrice = _parsePrice(
            productData['建议零售价'] as String,
          );
          final cartonWholesalePrice = _parsePrice(
            productData['批发价'] as String,
          );
          const conversionRate = 10.0;

          // 插入商品主记录
          batch.insert(
            db.productsTable,
            ProductsTableCompanion.insert(
              id: Value(productId),
              name: productName,
              brand: Value(brand),
              categoryId: Value(categoryId),
              unitId: Value(packUnitId), // 基础单位ID是“包”
              suggestedRetailPrice: Value(
                cartonSuggestedRetailPrice / conversionRate,
              ),
            ),
          );

          // 插入“包”的单位和条码记录
          final productPackUnitId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
          batch.insert(
            db.productUnitsTable,
            ProductUnitsTableCompanion.insert(
              productUnitId:productPackUnitId,
              productId: productId,
              unitId: packUnitId,
              conversionRate: 1.0,
              sellingPrice: Value(cartonSuggestedRetailPrice / conversionRate),
              wholesalePrice: Value(cartonWholesalePrice / conversionRate),
            ),
          );
          final packBarcode = productData['包条码'] as String?;
          if (packBarcode != null && packBarcode.isNotEmpty) {
            batch.insert(
              db.barcodesTable,
              BarcodesTableCompanion.insert(
                id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
                productUnitId: productPackUnitId,
                barcode: packBarcode,
              ),
            );
          }

          // 插入“条”的单位和条码记录
          final productCartonUnitId =
              (DateTime.now().millisecondsSinceEpoch + 3).toString();
          batch.insert(
            db.productUnitsTable,
            ProductUnitsTableCompanion.insert(
              productUnitId: productCartonUnitId,
              productId: productId,
              unitId: cartonUnitId,
              conversionRate: conversionRate,
              sellingPrice: Value(cartonSuggestedRetailPrice),
              wholesalePrice: Value(cartonWholesalePrice),
            ),
          );
          final cartonBarcode = productData['条条码'] as String?;
          if (cartonBarcode != null && cartonBarcode.isNotEmpty) {
            batch.insert(
              db.barcodesTable,
              BarcodesTableCompanion.insert(
                id: (DateTime.now().millisecondsSinceEpoch + 4).toString(),
                productUnitId:productCartonUnitId,
                barcode: cartonBarcode,
              ),
            );
          }
        }
      });
      return '批量导入任务完成，成功处理 ${rawProductsData.length} 条记录。';
    } catch (e, s) {
      // 在预检查后，此处的 UNIQUE constraint 错误理论上不应再发生
      // 但保留以防万一
      print('处理商品数据时发生意外错误: $e\n$s'); // 保留开发者日志
      return '导入过程中发生未知错误，请检查日志。';
    }
  }
}
