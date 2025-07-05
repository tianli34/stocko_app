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
import '../../application/provider/unit_edit_form_providers.dart';

/// 辅单位条码数据
class AuxiliaryUnitBarcodeData {
  final String productUnitId;
  final String barcode;

  const AuxiliaryUnitBarcodeData({
    required this.productUnitId,
    required this.barcode,
  });
}

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
  final List<AuxiliaryUnitBarcodeData>? auxiliaryUnitBarcodes;

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
    this.auxiliaryUnitBarcodes,
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
          // 立即刷新类别缓存，确保新类别在编辑时可见
          await ref.read(categoryListProvider.notifier).loadCategories();
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

      // 2.1 处理辅单位 - 检查并插入新的辅单位到单位表
      await _processAuxiliaryUnits(data.productUnits);

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

      // 7. 保存辅单位条码
      await _saveAuxiliaryUnitBarcodes(product, data.auxiliaryUnitBarcodes);

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
    print('🔍 [DEBUG] ==================== 开始保存产品单位 ====================');
    print('🔍 [DEBUG] 产品ID: ${product.id}');
    print('🔍 [DEBUG] 传入单位数量: ${units?.length ?? 0}');

    if (units != null && units.isNotEmpty) {
      print('🔍 [DEBUG] --- 传入的单位列表 ---');
      for (int i = 0; i < units.length; i++) {
        final unit = units[i];
        print(
          '🔍 [DEBUG] 单位 ${i + 1}: ${unit.productUnitId} (换算率: ${unit.conversionRate})',
        );
      }
    }

    // 从表单状态获取辅单位数据
    final formState = ref.read(unitEditFormProvider);
    final auxiliaryUnits = formState.auxiliaryUnits;
    print('🔍 [DEBUG] 表单中辅单位数量: ${auxiliaryUnits.length}');

    final ctrl = ref.read(productUnitControllerProvider.notifier);
    final list = <ProductUnit>[];

    // 添加基础单位
    list.add(
      ProductUnit(
        productUnitId: 'pu_${product.id}_${product.unitId!}',
        productId: product.id,
        unitId: product.unitId!,
        conversionRate: 1.0,
      ),
    );

    // 添加辅单位 - 重新刷新单位数据并等待加载完成
    ref.invalidate(allUnitsProvider);
    
    // 等待数据重新加载
    await Future.delayed(const Duration(milliseconds: 100));
    
    final allUnits = ref
        .read(allUnitsProvider)
        .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
    print('🔍 [DEBUG] 刷新后单位总数: ${allUnits.length}');

    for (final auxUnit in auxiliaryUnits) {
      final unitName = auxUnit.unitName.trim();
      print('🔍 [DEBUG] 处理辅单位: "$unitName", 换算率: ${auxUnit.conversionRate}');

      if (unitName.isEmpty) {
        print('🔍 [DEBUG] 单位名称为空，跳过');
        continue;
      }

      var unit = allUnits.firstWhere(
        (u) => u.name.toLowerCase() == unitName.toLowerCase(),
        orElse: () => Unit(id: '', name: ''),
      );

      // 如果未找到单位，尝试重新刷新数据并再次查找
      if (unit.id.isEmpty) {
        print('🔍 [DEBUG] 首次未找到单位 "$unitName"，重新刷新数据');
        ref.invalidate(allUnitsProvider);
        await Future.delayed(const Duration(milliseconds: 200));
        
        final refreshedUnits = ref
            .read(allUnitsProvider)
            .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
        
        unit = refreshedUnits.firstWhere(
          (u) => u.name.toLowerCase() == unitName.toLowerCase(),
          orElse: () => Unit(id: '', name: ''),
        );
      }

      if (unit.id.isNotEmpty) {
        list.add(
          ProductUnit(
            productUnitId: 'pu_${product.id}_${unit.id}',
            productId: product.id,
            unitId: unit.id,
            conversionRate: auxUnit.conversionRate,
            sellingPrice: auxUnit.retailPrice.trim().isNotEmpty
                ? double.tryParse(auxUnit.retailPrice.trim())
                : null,
          ),
        );
        print(
          '🔍 [DEBUG] ✅ 添加辅单位: ${unit.name} (ID: ${unit.id}, 换算率: ${auxUnit.conversionRate})',
        );
      } else {
        print('🔍 [DEBUG] ❌ 未找到单位: "$unitName"');
        // 可以选择跳过这个单位或抛出异常
        // throw Exception('未找到单位: $unitName');
      }
    }

    print('🔍 [DEBUG] --- 最终保存的单位列表 ---');
    for (int i = 0; i < list.length; i++) {
      final unit = list[i];
      print(
        '🔍 [DEBUG] 保存单位 ${i + 1}: ${unit.productUnitId} (换算率: ${unit.conversionRate})',
      );
    }

    try {
      await ctrl.replaceProductUnits(product.id, list);
      print('🔍 [DEBUG] ✅ 产品单位保存成功');
    } catch (e) {
      print('🔍 [DEBUG] ❌ 产品单位保存失败: $e');
      rethrow;
    }

    print('🔍 [DEBUG] ==================== 产品单位保存完成 ====================');
  }

  /// 保存主条码
  Future<void> _saveMainBarcode(Product product, String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;

    // 找到基础产品单位ID
    final productUnitController = ref.read(
      productUnitControllerProvider.notifier,
    );
    final productUnits = await productUnitController.getProductUnitsByProductId(
      product.id,
    );
    final baseProductUnit = productUnits.firstWhere(
      (pu) => pu.conversionRate == 1.0,
      orElse: () => throw Exception('未找到基础产品单位'),
    );

    final ctrl = ref.read(barcodeControllerProvider.notifier);
    final id = 'barcode_${product.id}_${DateTime.now().millisecondsSinceEpoch}';
    await ctrl.addBarcode(
      Barcode(
        id: id,
        productUnitId: baseProductUnit.productUnitId, // 使用正确的productUnitId
        barcode: code,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// 保存辅单位条码
  Future<void> _saveAuxiliaryUnitBarcodes(
    Product product,
    List<AuxiliaryUnitBarcodeData>? auxiliaryBarcodes,
  ) async {
    print('🔍 [DEBUG] ==================== 开始保存辅单位条码 ====================');
    
    // 从表单状态获取辅单位条码数据
    final formState = ref.read(unitEditFormProvider);
    final auxiliaryUnits = formState.auxiliaryUnits;
    
    print('🔍 [DEBUG] 表单中辅单位数量: ${auxiliaryUnits.length}');
    
    if (auxiliaryUnits.isEmpty) {
      print('🔍 [DEBUG] 没有辅单位数据，跳过条码保存');
      return;
    }

    // 获取已保存的产品单位信息
    final productUnitController = ref.read(productUnitControllerProvider.notifier);
    final productUnits = await productUnitController.getProductUnitsByProductId(product.id);
    
    final ctrl = ref.read(barcodeControllerProvider.notifier);
    final barcodes = <Barcode>[];

    for (final auxUnit in auxiliaryUnits) {
      final code = auxUnit.barcode.trim();
      if (code.isEmpty) {
        print('🔍 [DEBUG] 辅单位 "${auxUnit.unitName}" 条码为空，跳过');
        continue;
      }
      
      // 通过单位名称和换算率查找对应的产品单位ID
      final allUnits = ref.read(allUnitsProvider).maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
      final targetUnit = allUnits.firstWhere(
        (u) => u.name.toLowerCase() == auxUnit.unitName.trim().toLowerCase(),
        orElse: () => Unit(id: '', name: ''),
      );
      
      if (targetUnit.id.isNotEmpty) {
        final matchingProductUnit = productUnits.firstWhere(
          (pu) => pu.unitId == targetUnit.id && pu.conversionRate == auxUnit.conversionRate,
          orElse: () => ProductUnit(productUnitId: '', productId: '', unitId: '', conversionRate: 0),
        );
        
        if (matchingProductUnit.productUnitId.isNotEmpty) {
          final id = 'barcode_${product.id}_${matchingProductUnit.productUnitId}_${DateTime.now().millisecondsSinceEpoch}';
          barcodes.add(
            Barcode(
              id: id,
              productUnitId: matchingProductUnit.productUnitId,
              barcode: code,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          print('🔍 [DEBUG] ✅ 添加辅单位条码: ${auxUnit.unitName} -> $code (ProductUnitId: ${matchingProductUnit.productUnitId})');
        } else {
          print('🔍 [DEBUG] ❌ 未找到匹配的产品单位: ${auxUnit.unitName} (换算率: ${auxUnit.conversionRate})');
        }
      } else {
        print('🔍 [DEBUG] ❌ 未找到单位: ${auxUnit.unitName}');
      }
    }

    if (barcodes.isNotEmpty) {
      await ctrl.addMultipleBarcodes(barcodes);
      print('🔍 [DEBUG] ✅ 成功保存 ${barcodes.length} 个辅单位条码');
    } else {
      print('🔍 [DEBUG] 没有有效的辅单位条码需要保存');
    }
    
    print('🔍 [DEBUG] ==================== 辅单位条码保存完成 ====================');
  }

  /// 处理辅单位 - 检查并插入新的辅单位到单位表
  Future<void> _processAuxiliaryUnits(List<ProductUnit>? productUnits) async {
    print('🔍 [DEBUG] ==================== 开始处理辅单位 ====================');

    // 获取辅单位表单数据
    final formState = ref.read(unitEditFormProvider);
    print('🔍 [DEBUG] 表单中的辅单位数量: ${formState.auxiliaryUnits.length}');

    if (formState.auxiliaryUnits.isEmpty) {
      print('🔍 [DEBUG] 表单中没有辅单位数据，跳过处理');
      return;
    }

    final unitCtrl = ref.read(unitControllerProvider.notifier);
    final units = ref
        .read(allUnitsProvider)
        .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);

    print('🔍 [DEBUG] 当前数据库中的单位数量: ${units.length}');

    for (int i = 0; i < formState.auxiliaryUnits.length; i++) {
      final auxUnit = formState.auxiliaryUnits[i];
      final unitName = auxUnit.unitName.trim();

      print('🔍 [DEBUG] --- 处理辅单位 ${i + 1}: "$unitName" ---');

      if (unitName.isEmpty) {
        print('🔍 [DEBUG] 单位名称为空，跳过');
        continue;
      }

      // 检查单位是否已存在
      final existingUnit = units.firstWhere(
        (u) => u.name.toLowerCase() == unitName.toLowerCase(),
        orElse: () => Unit(id: '', name: ''),
      );

      if (existingUnit.id.isNotEmpty) {
        print(
          '🔍 [DEBUG] 单位已存在: ID=${existingUnit.id}, 名称="${existingUnit.name}"',
        );
      } else {
        // 如果单位不存在，创建新单位
        final newUnitId =
            'unit_${DateTime.now().millisecondsSinceEpoch}_${unitName.hashCode}';
        print('🔍 [DEBUG] 创建新单位: ID=$newUnitId, 名称="$unitName"');

        try {
          await unitCtrl.addUnit(Unit(id: newUnitId, name: unitName));
          print('🔍 [DEBUG] ✅ 新单位创建成功');
          
          // 刷新单位缓存以确保新单位可被查找到
          ref.invalidate(allUnitsProvider);
        } catch (e) {
          print('🔍 [DEBUG] ❌ 新单位创建失败: $e');
          throw Exception('创建单位失败: $unitName - $e');
        }
      }
    }

    // 最终刷新一次单位数据以确保所有新单位都可用
    ref.invalidate(allUnitsProvider);
    print('🔍 [DEBUG] ==================== 辅单位处理完成 ====================');
  }
}
