// lib/features/product/presentation/controllers/product_add_edit_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/barcode.dart';

import '../../application/category_notifier.dart';
import '../../application/provider/product_providers.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/category_service.dart';

/// 表单数据封装
class ProductFormData {
  final String? productId;
  final String name;
  final String? selectedCategoryId;
  final String newCategoryName;
  final String? selectedUnitId;
  final String newUnitName;
  final String? imagePath;
  final String barcode;
  final double? retailPrice;
  final double? promotionalPrice;
  final double? suggestedRetailPrice;
  final int? stockWarningValue;
  final int? shelfLife;
  final String shelfLifeUnit;
  final bool enableBatchManagement;
  final String? remarks;
  final List<ProductUnit>? productUnits;

  const ProductFormData({
    this.productId,
    required this.name,
    this.selectedCategoryId,
    this.newCategoryName = '',
    this.selectedUnitId,
    this.newUnitName = '',
    this.imagePath,
    this.barcode = '',
    this.retailPrice,
    this.promotionalPrice,
    this.suggestedRetailPrice,
    this.stockWarningValue,
    this.shelfLife,
    this.shelfLifeUnit = 'months',
    this.enableBatchManagement = false,
    this.remarks,
    this.productUnits,
  });
}

/// 操作结果
class ProductOperationResult {
  final bool success;
  final String? message;
  final Product? product;

  const ProductOperationResult._(this.success, {this.message, this.product});

  factory ProductOperationResult.success({String? message, Product? product}) =>
      ProductOperationResult._(true, message: message, product: product);

  factory ProductOperationResult.failure(String message) =>
      ProductOperationResult._(false, message: message);
}

/// Controller 提供者
final productAddEditControllerProvider = Provider<ProductAddEditController>(
  (ref) => ProductAddEditController(ref),
);

/// 产品添加/编辑控制器
class ProductAddEditController {
  final Ref ref;
  ProductAddEditController(this.ref);

  /// 提交表单并返回操作结果
  Future<ProductOperationResult> submitForm(ProductFormData data) async {
    try {
      // 1. 处理类别
      String? categoryId = data.selectedCategoryId;
      if ((categoryId == null || categoryId.isEmpty) &&
          data.newCategoryName.trim().isNotEmpty) {
        final categories = ref.read(categoriesProvider);
        final existingCat = categories.firstWhere(
          (c) =>
              c.name.toLowerCase() == data.newCategoryName.trim().toLowerCase(),
          orElse: () => Category(id: '', name: ''),
        );
        if (existingCat.id.isNotEmpty) {
          categoryId = existingCat.id;
        } else {
          final service = ref.read(categoryServiceProvider);
          categoryId = service.generateCategoryId();
          await service.addCategory(
            id: categoryId,
            name: data.newCategoryName.trim(),
          );
        }
      }

      // 2. 处理单位
      String? unitId = data.selectedUnitId;
      if ((unitId == null || unitId.isEmpty) &&
          data.newUnitName.trim().isNotEmpty) {
        final units = ref
            .read(allUnitsProvider)
            .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
        final existingUnit = units.firstWhere(
          (u) => u.name.toLowerCase() == data.newUnitName.trim().toLowerCase(),
          orElse: () => Unit(id: '', name: ''),
        );
        if (existingUnit.id.isNotEmpty) {
          unitId = existingUnit.id;
        } else {
          final unitCtrl = ref.read(unitControllerProvider.notifier);
          unitId = 'unit_${DateTime.now().millisecondsSinceEpoch}';
          await unitCtrl.addUnit(
            Unit(id: unitId, name: data.newUnitName.trim()),
          );
        }
      }
      if (unitId == null || unitId.isEmpty) {
        return ProductOperationResult.failure('请选择计量单位');
      }

      // 3. 构建产品对象
      final product = Product(
        id: data.productId?.isNotEmpty == true
            ? data.productId!
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: data.name.trim(),
        image: data.imagePath,
        categoryId: categoryId,
        unitId: unitId,
        retailPrice: data.retailPrice,
        promotionalPrice: data.promotionalPrice,
        suggestedRetailPrice: data.suggestedRetailPrice,
        stockWarningValue: data.stockWarningValue,
        shelfLife: data.shelfLife,
        shelfLifeUnit: data.shelfLifeUnit,
        enableBatchManagement: data.enableBatchManagement,
        remarks: data.remarks?.trim(),
        lastUpdated: DateTime.now(),
      );

      // 4. 保存产品
      final ops = ref.read(productOperationsProvider.notifier);
      if (data.productId == null || data.productId!.isEmpty) {
        await ops.addProduct(product);
      } else {
        await ops.updateProduct(product);
      }

      // 5. 保存单位配置
      await _saveProductUnits(product, data.productUnits);

      // 6. 保存主条码
      await _saveMainBarcode(product, data.barcode);

      return ProductOperationResult.success(
        message: data.productId == null || data.productId!.isEmpty
            ? '创建成功'
            : '更新成功',
        product: product,
      );
    } catch (e) {
      return ProductOperationResult.failure('保存失败: ${e.toString()}');
    }
  }

  /// 保存或替换产品单位配置
  Future<void> _saveProductUnits(
    Product product,
    List<ProductUnit>? units,
  ) async {
    final ctrl = ref.read(productUnitControllerProvider.notifier);
    final list = (units != null && units.isNotEmpty)
        ? units
        : [
            ProductUnit(
              productUnitId: 'pu_${product.id}_${product.unitId!}',
              productId: product.id,
              unitId: product.unitId!,
              conversionRate: 1.0,
            ),
          ];
    await ctrl.replaceProductUnits(product.id, list);
  }

  /// 保存主条码
  Future<void> _saveMainBarcode(Product product, String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;
    final ctrl = ref.read(barcodeControllerProvider.notifier);
    final id = 'barcode_${product.id}_${DateTime.now().millisecondsSinceEpoch}';
    await ctrl.addBarcode(
      Barcode(
        id: id,
        productUnitId: product.unitId!,
        barcode: code,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
