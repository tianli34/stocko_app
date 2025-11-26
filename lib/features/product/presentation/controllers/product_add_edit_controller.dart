// lib/features/product/presentation/controllers/product_add_edit_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/barcode.dart';
import '../../domain/model/auxiliary_unit_data.dart';

import '../../application/category_notifier.dart';
import '../../application/provider/product_providers.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/product_group_providers.dart';
import '../../application/category_service.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import '../../data/repository/product_unit_repository.dart';
import '../../domain/model/product_group.dart';
import '../state/product_form_ui_provider.dart';

/// 辅单位条码数据
class AuxiliaryUnitBarcodeData {
  final int id;
  final String barcode;

  const AuxiliaryUnitBarcodeData({required this.id, required this.barcode});
}

/// 变体数据（用于批量创建）
class VariantFormData {
  final String variantName;
  final String barcode;

  const VariantFormData({
    required this.variantName,
    this.barcode = '',
  });
}

/// 表单数据封装
class ProductFormData {
  final int? productId;
  final String name;
  final int? selectedCategoryId;
  final String newCategoryName;
  final int? selectedUnitId;
  final String newUnitName;
  final String? imagePath;
  final String barcode;
  // 价格（元）
  final double? retailPriceInCents;
  final double? promotionalPriceInCents;
  final double? suggestedRetailPriceInCents;
  final int? stockWarningValue;
  final int? shelfLife;
  final String shelfLifeUnit;
  final bool enableBatchManagement;
  final String? remarks;
  final List<UnitProduct>? productUnits;
  final List<AuxiliaryUnitBarcodeData>? auxiliaryUnitBarcodes;
  // 商品组相关
  final int? groupId;
  final String? variantName;
  // 多变体模式
  final bool isMultiVariantMode;
  final List<VariantFormData> variants;

  const ProductFormData({
    this.productId,
    required this.name,
    this.selectedCategoryId,
    this.newCategoryName = '',
    this.selectedUnitId,
    this.newUnitName = '',
    this.imagePath,
    this.barcode = '',
    this.retailPriceInCents,
    this.promotionalPriceInCents,
    this.suggestedRetailPriceInCents,
    this.stockWarningValue,
    this.shelfLife,
    this.shelfLifeUnit = 'months',
    this.enableBatchManagement = false,
    this.remarks,
    this.productUnits,
    this.auxiliaryUnitBarcodes,
    this.groupId,
    this.variantName,
    this.isMultiVariantMode = false,
    this.variants = const [],
  });
}

/// 操作结果
class ProductOperationResult {
  final bool success;
  final String? message;
  final ProductModel? product;

  const ProductOperationResult._(this.success, {this.message, this.product});

  factory ProductOperationResult.success({
    String? message,
    ProductModel? product,
  }) => ProductOperationResult._(true, message: message, product: product);

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
    // 多变体模式：批量创建商品
    if (data.isMultiVariantMode && data.variants.isNotEmpty && data.productId == null) {
      return _submitMultiVariants(data);
    }
    
    // 单商品模式
    return _submitSingleProduct(data);
  }

  /// 批量创建多个变体商品
  Future<ProductOperationResult> _submitMultiVariants(ProductFormData data) async {
    try {
      // 1. 处理类别
      int? categoryId = await _resolveCategory(data);

      // 2. 处理单位
      int? unitId = await _resolveUnit(data);
      if (unitId == null) {
        return ProductOperationResult.failure('请选择计量单位');
      }

      // 2.1 处理辅单位
      await _processAuxiliaryUnits(data.productUnits);

      // 3. 处理商品组：如果没有选择已有商品组，则创建新商品组
      int? groupId = data.groupId;
      if (groupId == null && data.name.trim().isNotEmpty) {
        // 验证商品组名称唯一性
        final existingGroups = await ref.read(allProductGroupsProvider.future);
        final nameExists = existingGroups.any(
          (g) => g.name.toLowerCase() == data.name.trim().toLowerCase(),
        );
        if (nameExists) {
          return ProductOperationResult.failure('商品组名称"${data.name.trim()}"已存在，请选择已有商品组或使用其他名称');
        }
        
        // 创建新商品组
        final groupModel = ProductGroupModel(name: data.name.trim());
        groupId = await ref
            .read(productGroupOperationsProvider.notifier)
            .createProductGroup(groupModel);
        if (groupId == null) {
          return ProductOperationResult.failure('创建商品组失败');
        }
      }

      // 4. 批量创建变体商品
      final ops = ref.read(productOperationsProvider.notifier);
      int successCount = 0;
      final List<String> errors = [];

      for (final variant in data.variants) {
        if (variant.variantName.trim().isEmpty) continue;

        try {
          // 构建变体商品名称：基础名称 + 变体名称
          final productName = '${data.name.trim()} ${variant.variantName.trim()}';
          
          Money? toMoney(double? yuan) =>
              yuan == null ? null : Money((yuan * 100).round());

          final product = ProductModel(
            id: DateTime.now().millisecondsSinceEpoch + successCount,
            name: productName,
            image: data.imagePath,
            categoryId: categoryId,
            baseUnitId: unitId,
            groupId: groupId,
            variantName: variant.variantName.trim(),
            suggestedRetailPrice: toMoney(data.suggestedRetailPriceInCents),
            retailPrice: toMoney(data.retailPriceInCents),
            promotionalPrice: toMoney(data.promotionalPriceInCents),
            stockWarningValue: data.stockWarningValue,
            shelfLife: data.shelfLife,
            shelfLifeUnit: ShelfLifeUnit.values.byName(data.shelfLifeUnit),
            enableBatchManagement: data.enableBatchManagement,
            remarks: data.remarks?.trim(),
            lastUpdated: DateTime.now(),
          );

          await ops.addProduct(product);

          // 保存单位配置
          await _saveProductUnits(product, data.productUnits);

          // 保存条码（如果变体有自己的条码）
          if (variant.barcode.trim().isNotEmpty) {
            await _saveMainBarcode(product, variant.barcode.trim());
          }

          successCount++;
        } catch (e) {
          errors.add('${variant.variantName}: $e');
        }
      }

      // 刷新数据
      ref.invalidate(allProductsProvider);
      ref.invalidate(categoryListProvider);
      ref.invalidate(allProductGroupsProvider);

      if (successCount == 0) {
        return ProductOperationResult.failure('创建失败: ${errors.join(', ')}');
      }

      final message = successCount == data.variants.length
          ? '成功创建 $successCount 个变体商品'
          : '成功创建 $successCount 个变体商品，${errors.length} 个失败';

      return ProductOperationResult.success(message: message);
    } catch (e) {
      return ProductOperationResult.failure('批量创建失败: ${e.toString()}');
    }
  }

  /// 解析类别ID
  Future<int?> _resolveCategory(ProductFormData data) async {
    int? categoryId = data.selectedCategoryId;
    if ((categoryId == null) && data.newCategoryName.trim().isNotEmpty) {
      final categoryNotifier = ref.read(categoryListProvider.notifier);
      await categoryNotifier.loadCategories();
      final categories = ref.read(categoryListProvider).categories;
      CategoryModel? existingCat;
      try {
        existingCat = categories.firstWhere(
          (c) =>
              c.name.toLowerCase() ==
              data.newCategoryName.trim().toLowerCase(),
        );
      } catch (e) {
        existingCat = null;
      }
      if (existingCat != null) {
        categoryId = existingCat.id;
      } else {
        final service = ref.read(categoryServiceProvider);
        categoryId = await service.addCategory(
          name: data.newCategoryName.trim(),
        );
        ref.invalidate(categoryListProvider);
      }
    }
    return categoryId;
  }

  /// 解析单位ID
  Future<int?> _resolveUnit(ProductFormData data) async {
    int? unitId = data.selectedUnitId;
    if (unitId == null && data.newUnitName.trim().isNotEmpty) {
      final units = ref
          .read(allUnitsProvider)
          .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
      Unit? existingUnit;
      existingUnit = units
          .where(
            (u) =>
                u.name.toLowerCase() == data.newUnitName.trim().toLowerCase(),
          )
          .firstOrNull;

      if (existingUnit != null) {
        unitId = existingUnit.id;
      } else {
        final unitCtrl = ref.read(unitControllerProvider.notifier);
        final newUnit = await unitCtrl.addUnit(
          Unit(name: data.newUnitName.trim()),
        );
        unitId = newUnit.id;
      }
    }
    return unitId;
  }

  /// 提交单个商品
  Future<ProductOperationResult> _submitSingleProduct(ProductFormData data) async {
    try {
      // 1. 处理类别
      int? categoryId = data.selectedCategoryId;
      if ((categoryId == null) && data.newCategoryName.trim().isNotEmpty) {
        final categoryNotifier = ref.read(categoryListProvider.notifier);
        await categoryNotifier.loadCategories();
        final categories = ref.read(categoryListProvider).categories;
        CategoryModel? existingCat;
        try {
          existingCat = categories.firstWhere(
            (c) =>
                c.name.toLowerCase() ==
                data.newCategoryName.trim().toLowerCase(),
          );
        } catch (e) {
          existingCat = null;
        }
        if (existingCat != null) {
          categoryId = existingCat.id;
        } else {
          // 调试信息
          print('🔍 [DEBUG] 创建新类别: "${data.newCategoryName.trim()}"');

          final service = ref.read(categoryServiceProvider);
          categoryId = await service.addCategory(
            name: data.newCategoryName.trim(),
          );

          // 调试信息
          print('🔍 [DEBUG] 新类别创建成功，ID: $categoryId');

          // 立即刷新类别缓存，确保新类别在编辑时可见
          ref.invalidate(categoryListProvider);
        }
      }

      // 2. 处理单位
      int? unitId = data.selectedUnitId;
      if (unitId == null && data.newUnitName.trim().isNotEmpty) {
        final units = ref
            .read(allUnitsProvider)
            .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
        Unit? existingUnit;
        existingUnit = units
            .where(
              (u) =>
                  u.name.toLowerCase() == data.newUnitName.trim().toLowerCase(),
            )
            .firstOrNull;

        if (existingUnit != null) {
          unitId = existingUnit.id;
        } else {
          final unitCtrl = ref.read(unitControllerProvider.notifier);
          final newUnit = await unitCtrl.addUnit(
            Unit(name: data.newUnitName.trim()),
          );
          unitId = newUnit.id;
        }
      }
      if (unitId == null) {
        return ProductOperationResult.failure('请选择计量单位');
      }

      // 2.1 处理辅单位 - 检查并插入新的辅单位到单位表
      await _processAuxiliaryUnits(data.productUnits);

      // 3. 构建产品对象
      Money? toMoney(double? yuan) =>
          yuan == null ? null : Money((yuan * 100).round());

      // 调试信息
      print('🔍 [DEBUG] ==================== 创建产品 ====================');
      print('🔍 [DEBUG] 产品名称: "${data.name.trim()}"');
      print('🔍 [DEBUG] 选中的类别ID: ${data.selectedCategoryId}');
      print('🔍 [DEBUG] 新类别名称: "${data.newCategoryName.trim()}"');
      print('🔍 [DEBUG] 最终类别ID: $categoryId');
      print('🔍 [DEBUG] 单位ID: $unitId');

      final product = ProductModel(
        id: data.productId ?? DateTime.now().millisecondsSinceEpoch,
        // 确保id为整数类型
        name: data.name.trim(),
        image: data.imagePath,
        categoryId: categoryId,
        baseUnitId: unitId,
        // 商品组相关
        groupId: data.groupId,
        variantName: data.variantName?.trim(),
        // 可选字段按需传入
        suggestedRetailPrice: toMoney(data.suggestedRetailPriceInCents),
        retailPrice: toMoney(data.retailPriceInCents),
        promotionalPrice: toMoney(data.promotionalPriceInCents),
        stockWarningValue: data.stockWarningValue,
        shelfLife: data.shelfLife,
        shelfLifeUnit: ShelfLifeUnit.values.byName(data.shelfLifeUnit),
        enableBatchManagement: data.enableBatchManagement,
        remarks: data.remarks?.trim(),
        lastUpdated: DateTime.now(),
      );

      // 4. 保存产品
      final ops = ref.read(productOperationsProvider.notifier);
      if (data.productId == null) {
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

      // 修复：在所有数据库操作（包括单位和条码）完成后，再次强制刷新产品列表，
      // 确保UI获取到包含最新单位信息的货品数据。
      ref.invalidate(allProductsProvider);
      // 关键修复：同时使主条码的Provider失效，以便下次进入页面时能重新获取
      ref.invalidate(mainBarcodeProvider(product.id!));
      // 确保类别列表也被刷新，以便编辑页面能正确显示新创建的类别
      ref.invalidate(categoryListProvider);

      return ProductOperationResult.success(
        message: data.productId == null ? '创建成功' : '更新成功',
        product: product,
      );
    } catch (e) {
      return ProductOperationResult.failure('保存失败: ${e.toString()}');
    }
  }

  /// 保存或替换产品单位配置
  Future<void> _saveProductUnits(
    ProductModel product,
    List<UnitProduct>? units,
  ) async {
    print('🔍 [DEBUG] ==================== 开始保存产品单位 ====================');
    print('🔍 [DEBUG] 产品ID: ${product.id}');
    print('🔍 [DEBUG] 传入单位数量: ${units?.length ?? 0}');

    if (units != null && units.isNotEmpty) {
      print('🔍 [DEBUG] --- 传入的单位列表 ---');
      for (int i = 0; i < units.length; i++) {
        final unit = units[i];
        print(
          '🔍 [DEBUG] 单位 ${i + 1}: ${unit.id} (换算率: ${unit.conversionRate})',
        );
      }
    }

    // 获取 UI 状态，检查是否进入过辅单位编辑页面
    final uiState = ref.read(productFormUiProvider);
    final hasEnteredAuxUnitPage = uiState.hasEnteredAuxUnitPage;
    print('🔍 [DEBUG] 是否进入过辅单位页面: $hasEnteredAuxUnitPage');

    List<AuxiliaryUnitData> auxiliaryUnits;

    if (hasEnteredAuxUnitPage) {
      // ✅ 用户进入过辅单位编辑页面，从表单状态获取数据
      print('🔍 [DEBUG] 从表单状态获取辅单位数据');
      final formState = ref.read(unitEditFormProvider);
      auxiliaryUnits = formState.auxiliaryUnits;
      print('🔍 [DEBUG] 表单中辅单位数量: ${auxiliaryUnits.length}');
    } else if (product.id != null) {
      // ✅ 用户未进入辅单位编辑页面且是编辑模式，从数据库加载现有辅单位
      print('🔍 [DEBUG] 从数据库加载现有辅单位数据');
      auxiliaryUnits = await _loadExistingAuxiliaryUnits(product.id!);
      print('🔍 [DEBUG] 从数据库加载了 ${auxiliaryUnits.length} 个辅单位');
    } else {
      // 新增模式且未进入辅单位页面
      print('🔍 [DEBUG] 新增模式，无辅单位数据');
      auxiliaryUnits = [];
    }

    final ctrl = ref.read(productUnitControllerProvider.notifier);
    final list = <UnitProduct>[];

    // 添加基础单位
    list.add(
      UnitProduct(
        productId: product.id!,
        unitId: product.baseUnitId,
        conversionRate: 1,
      ),
    );

    // 直接从provider获取最新的单位列表，.future会自动处理加载状态
    final allUnits = await ref.read(allUnitsProvider.future);
    print('🔍 [DEBUG] 刷新后单位总数: ${allUnits.length}');

    for (final auxUnit in auxiliaryUnits) {
      final unitName = auxUnit.unitName.trim();
      print('🔍 [DEBUG] 处理辅单位: "$unitName", 换算率: ${auxUnit.conversionRate}');

      if (unitName.isEmpty) {
        print('🔍 [DEBUG] 单位名称为空，跳过');
        continue;
      }

      Unit? unit;
      try {
        unit = allUnits
            .where((u) => u.name.toLowerCase() == unitName.toLowerCase())
            .firstOrNull;
      } catch (e) {
        unit = null;
      }

      // 如果在这里找不到单位，说明有一个辅单位的名称在单位表中不存在，
      // 这在正常流程下不应该发生，因为所有新单位都应在_processAuxiliaryUnits中被添加。
      // 因此，这是一个关键错误，需要抛出异常而不是静默失败。
      if (unit != null && unit.id != null) {
        list.add(
          UnitProduct(
            productId: product.id!,
            unitId: unit.id!,
            conversionRate: auxUnit.conversionRate,
            sellingPriceInCents: auxUnit.retailPriceInCents.trim().isNotEmpty
                ? int.tryParse(auxUnit.retailPriceInCents.trim())
                : null,
            wholesalePriceInCents:
                auxUnit.wholesalePriceInCents.trim().isNotEmpty
                ? int.tryParse(auxUnit.wholesalePriceInCents.trim())
                : null,
          ),
        );
        print(
          '🔍 [DEBUG] ✅ 添加辅单位: ${unit.name} (ID: ${unit.id}, 换算率: ${auxUnit.conversionRate})',
        );
      } else {
        print('🔍 [DEBUG] ❌ 在_saveProductUnits中未找到单位: "$unitName"');
        // 这是一个关键错误，意味着在表单提交时，一个预期的单位没有被正确创建或找到。
        // 抛出异常以阻止不完整的数据被保存。
        throw Exception('保存产品单位失败：无法找到单位 "$unitName"。请检查单位是否已正确添加。');
      }
    }

    print('🔍 [DEBUG] --- 最终保存的单位列表 ---');
    for (int i = 0; i < list.length; i++) {
      final unit = list[i];
      print(
        '🔍 [DEBUG] 保存单位 ${i + 1}: ${unit.id} (换算率: ${unit.conversionRate})',
      );
    }

    try {
      await ctrl.replaceProductUnits(product.id!, list);
      print('🔍 [DEBUG] ✅ 产品单位保存成功');
    } catch (e) {
      print('🔍 [DEBUG] ❌ 产品单位保存失败: $e');
      rethrow;
    }

    print('🔍 [DEBUG] ==================== 产品单位保存完成 ====================');
  }

  /// 保存主条码
  Future<void> _saveMainBarcode(ProductModel product, String barcode) async {
    final code = barcode.trim();
    final barcodeCtrl = ref.read(barcodeControllerProvider.notifier);
    final productUnitRepository = ref.read(productUnitRepositoryProvider);

    // 1. 找到新的基础产品单位ID (在 _saveProductUnits 执行后)
    final productUnitController = ref.read(
      productUnitControllerProvider.notifier,
    );
    final productUnits = await productUnitController.getProductUnitsByProductId(
      product.id!,
    );
    final baseProductUnit = productUnits
        .where((pu) => pu.conversionRate == 1.0)
        .firstOrNull;
    if (baseProductUnit == null) {
      throw Exception('保存主条码失败：未找到基础产品单位。');
    }
    final baseUnitProductId = baseProductUnit.id!;

    // 2. 查找与输入条码匹配的现有条码
    final existingBarcode = code.isEmpty
        ? null
        : await barcodeCtrl.getBarcodeByValue(code);

    // 3. 验证条码是否被其他货品占用
    if (existingBarcode != null) {
      // 通过 unitProductId 找到对应的 product_unit 记录
      final productUnit = await productUnitRepository.getProductUnitById(
        existingBarcode.unitProductId,
      );
      // 如果能找到 product_unit 记录，并且其 productId 不是当前产品的 ID，则说明条码被占用
      if (productUnit != null && productUnit.productId != product.id) {
        throw Exception('条码 "$code" 已被其他货品使用，无法重复添加。');
      }
    }

    // 4. 查找与当前产品关联的所有条码，并找到主条码
    // 由于 unit_id 已变，直接查找会很困难。我们转而处理与当前产品关联的所有条码。
    // 此处简化逻辑：我们信任验证步骤，并直接进行 upsert 操作。
    // 我们需要先删除所有与该产品基础单位无关的条码（即旧的条码）。
    // 这部分逻辑比较复杂，暂时的修复方案是只处理当前条码的更新。

    // 5. 同步主条码
    if (code.isEmpty) {
      // 如果输入为空，则删除现有的主条码（如果存在）
      if (existingBarcode != null &&
          existingBarcode.unitProductId == baseUnitProductId) {
        await barcodeCtrl.deleteBarcode(existingBarcode.id!);
      }
    } else {
      // 输入不为空
      if (existingBarcode != null) {
        // 条码已存在（验证已确认它属于当前产品），更新其 unitProductId 指向新的基础单位
        if (existingBarcode.unitProductId != baseUnitProductId) {
          await barcodeCtrl.updateBarcode(
            existingBarcode.copyWith(unitProductId: baseUnitProductId),
          );
        }
      } else {
        // 条码不存在，添加新条码
        await barcodeCtrl.addBarcode(
          BarcodeModel(unitProductId: baseUnitProductId, barcodeValue: code),
        );
      }
    }
  }

  /// 保存辅单位条码
  Future<void> _saveAuxiliaryUnitBarcodes(
    ProductModel product,
    List<AuxiliaryUnitBarcodeData>? auxiliaryBarcodes,
  ) async {
    print('🔍 [DEBUG] ==================== 开始保存辅单位条码 ====================');

    // 获取 UI 状态，检查是否进入过辅单位编辑页面
    final uiState = ref.read(productFormUiProvider);
    final hasEnteredAuxUnitPage = uiState.hasEnteredAuxUnitPage;
    print('🔍 [DEBUG] 是否进入过辅单位页面: $hasEnteredAuxUnitPage');

    List<AuxiliaryUnitData> auxiliaryUnits;

    if (hasEnteredAuxUnitPage) {
      // ✅ 用户进入过辅单位编辑页面，从表单状态获取数据
      print('🔍 [DEBUG] 从表单状态获取辅单位条码数据');
      final formState = ref.read(unitEditFormProvider);
      auxiliaryUnits = formState.auxiliaryUnits;
      print('🔍 [DEBUG] 表单中辅单位数量: ${auxiliaryUnits.length}');
    } else if (product.id != null) {
      // ✅ 用户未进入辅单位编辑页面且是编辑模式，从数据库加载现有辅单位
      print('🔍 [DEBUG] 从数据库加载现有辅单位条码数据');
      auxiliaryUnits = await _loadExistingAuxiliaryUnits(product.id!);
      print('🔍 [DEBUG] 从数据库加载了 ${auxiliaryUnits.length} 个辅单位');
    } else {
      // 新增模式且未进入辅单位页面
      print('🔍 [DEBUG] 新增模式，无辅单位条码数据');
      auxiliaryUnits = [];
    }

    if (auxiliaryUnits.isEmpty) {
      print('🔍 [DEBUG] 没有辅单位数据，跳过条码保存');
      return;
    }

    // 获取已保存的产品单位信息
    final productUnitController = ref.read(
      productUnitControllerProvider.notifier,
    );
    final productUnits = await productUnitController.getProductUnitsByProductId(
      product.id!,
    );

    final ctrl = ref.read(barcodeControllerProvider.notifier);
    final barcodes = <BarcodeModel>[];

    for (final auxUnit in auxiliaryUnits) {
      final code = auxUnit.barcode.trim();
      if (code.isEmpty) {
        print('🔍 [DEBUG] 辅单位 "${auxUnit.unitName}" 条码为空，跳过');
        continue;
      }

      // 通过单位名称和换算率查找对应的产品单位ID
      final allUnits = ref
          .read(allUnitsProvider)
          .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);
      Unit? targetUnit;
      try {
        targetUnit = allUnits
            .where(
              (u) =>
                  u.name.toLowerCase() == auxUnit.unitName.trim().toLowerCase(),
            )
            .firstOrNull;
      } catch (e) {
        targetUnit = null;
      }

      if (targetUnit != null) {
        final finalTargetUnit = targetUnit;
        UnitProduct? matchingProductUnit;
        matchingProductUnit = productUnits
            .where(
              (pu) =>
                  pu.unitId == finalTargetUnit.id &&
                  pu.conversionRate == auxUnit.conversionRate,
            )
            .firstOrNull;

        if (matchingProductUnit == null) {
          throw Exception(
            '数据不一致：在产品单位列表中找不到单位 ${finalTargetUnit.name} (换算率: ${auxUnit.conversionRate})',
          );
        }

        if ((matchingProductUnit.id ?? 0) > 0) {
          barcodes.add(
            BarcodeModel(
              unitProductId: matchingProductUnit.id!,
              barcodeValue: code,
            ),
          );
          print(
            '🔍 [DEBUG] ✅ 添加辅单位条码: ${auxUnit.unitName} -> $code (ProductUnitId: ${matchingProductUnit.id})',
          );
        } else {
          print(
            '🔍 [DEBUG] ❌ 未找到匹配的产品单位: ${auxUnit.unitName} (换算率: ${auxUnit.conversionRate})',
          );
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

  /// 从数据库加载现有辅单位数据并转换为表单格式
  Future<List<AuxiliaryUnitData>> _loadExistingAuxiliaryUnits(
    int productId,
  ) async {
    try {
      final productUnitController = ref.read(
        productUnitControllerProvider.notifier,
      );
      final barcodeController = ref.read(barcodeControllerProvider.notifier);

      // 获取所有产品单位
      final allProductUnits = await productUnitController
          .getProductUnitsByProductId(productId);

      // 过滤出辅单位（换算率不为1）
      final auxiliaryProductUnits = allProductUnits
          .where((pu) => pu.conversionRate != 1.0)
          .toList();

      if (auxiliaryProductUnits.isEmpty) {
        return [];
      }

      // 获取所有单位信息
      final allUnits = await ref.read(allUnitsProvider.future);

      // 转换为 AuxiliaryUnitData 格式
      final List<AuxiliaryUnitData> auxiliaryUnitsData = [];

      for (final productUnit in auxiliaryProductUnits) {
        // 查找单位名称
        final unit = allUnits.firstWhere(
          (u) => u.id == productUnit.unitId,
          orElse: () => Unit(name: 'Unknown'),
        );

        // 查找条码
        final barcodes = await barcodeController.getBarcodesByProductUnitId(
          productUnit.id,
        );
        final barcodeValue = barcodes.isNotEmpty
            ? barcodes.first.barcodeValue
            : '';

        // 转换价格（分 -> 元的字符串）
        final retailPrice = productUnit.sellingPriceInCents != null
            ? productUnit.sellingPriceInCents.toString()
            : '';
        final wholesalePrice = productUnit.wholesalePriceInCents != null
            ? productUnit.wholesalePriceInCents.toString()
            : '';

        auxiliaryUnitsData.add(
          AuxiliaryUnitData(
            id: productUnit.id ?? 0,
            unitId: unit.id,
            unitName: unit.name,
            conversionRate: productUnit.conversionRate,
            barcode: barcodeValue,
            retailPriceInCents: retailPrice,
            wholesalePriceInCents: wholesalePrice,
          ),
        );

        print(
          '🔍 [DEBUG] 加载辅单位: ${unit.name}, 换算率: ${productUnit.conversionRate}, '
          '零售价: $retailPrice, 批发价: $wholesalePrice',
        );
      }

      return auxiliaryUnitsData;
    } catch (e) {
      print('🔍 [DEBUG] ❌ 加载现有辅单位失败: $e');
      return [];
    }
  }

  /// 处理辅单位 - 检查并插入新的辅单位到单位表
  Future<void> _processAuxiliaryUnits(List<UnitProduct>? productUnits) async {
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
      Unit? existingUnit;
      existingUnit = units
          .where((u) => u.name.toLowerCase() == unitName.toLowerCase())
          .firstOrNull;

      if (existingUnit != null) {
        print(
          '🔍 [DEBUG] 单位已存在: ID=${existingUnit.id}, 名称="${existingUnit.name}"',
        );
      } else {
        // 如果单位不存在，创建新单位
        print('🔍 [DEBUG] 创建新单位: 名称="$unitName"');

        try {
          // 调用新的addUnit方法，它会处理一切
          final newUnit = await unitCtrl.addUnit(Unit(name: unitName));
          print('🔍 [DEBUG] ✅ 新单位创建成功, ID: ${newUnit.id}');

          // 将新创建的单位添加到当前循环的单位列表中，
          // 以便在同一个循环中处理依赖于这个新单位的其他逻辑。
          units.add(newUnit);
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
