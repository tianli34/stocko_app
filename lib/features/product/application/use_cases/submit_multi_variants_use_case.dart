// lib/features/product/application/use_cases/submit_multi_variants_use_case.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/converters/money_converter.dart';
import '../../core/logger/product_logger.dart';
import '../../domain/model/product.dart';
import '../../presentation/models/product_form_data.dart';
import '../../presentation/models/product_operation_result.dart';
import '../category_notifier.dart';
import '../provider/product_group_providers.dart';
import '../provider/product_providers.dart';
import '../services/barcode_sync_service.dart';
import '../services/category_resolver_service.dart';
import '../services/product_group_resolver_service.dart';
import '../services/product_unit_sync_service.dart';
import '../services/unit_resolver_service.dart';

/// 提交多变体商品用例
/// 
/// 编排批量变体商品的创建流程
class SubmitMultiVariantsUseCase {
  final Ref _ref;

  SubmitMultiVariantsUseCase(this._ref);

  /// 执行用例
  /// 
  /// [data] 表单数据
  /// 返回操作结果
  Future<ProductOperationResult> execute(ProductFormData data) async {
    ProductLogger.separator('批量创建变体商品', isStart: true);

    try {
      // 1. 解析类别
      final categoryResolver = _ref.read(categoryResolverServiceProvider);
      final categoryId = await categoryResolver.resolve(
        selectedCategoryId: data.selectedCategoryId,
        newCategoryName: data.newCategoryName,
      );
      ProductLogger.debug('类别ID: $categoryId', tag: 'SubmitMultiVariants');

      // 2. 解析单位
      final unitResolver = _ref.read(unitResolverServiceProvider);
      final unitId = await unitResolver.resolve(
        selectedUnitId: data.selectedUnitId,
        newUnitName: data.newUnitName,
      );

      if (unitId == null) {
        ProductLogger.error('未选择计量单位', tag: 'SubmitMultiVariants');
        return ProductOperationResult.failure('请选择计量单位');
      }
      ProductLogger.debug('单位ID: $unitId', tag: 'SubmitMultiVariants');

      // 3. 处理辅单位
      final productUnitSyncService = _ref.read(productUnitSyncServiceProvider);
      await productUnitSyncService.processAuxiliaryUnits();

      // 4. 解析或创建商品组
      final productGroupResolver = _ref.read(productGroupResolverServiceProvider);
      final groupId = await productGroupResolver.resolveOrCreate(
        groupId: data.groupId,
        groupName: data.name.trim(),
      );
      ProductLogger.debug('商品组ID: $groupId', tag: 'SubmitMultiVariants');

      // 5. 批量创建变体商品
      final result = await _createVariants(
        data: data,
        categoryId: categoryId,
        unitId: unitId,
        groupId: groupId,
        productUnitSyncService: productUnitSyncService,
      );

      // 6. 刷新相关 Provider
      _invalidateProviders();

      ProductLogger.separator('批量创建变体商品完成', isStart: false);

      return result;
    } catch (e) {
      ProductLogger.error('批量创建失败', tag: 'SubmitMultiVariants', error: e);
      return ProductOperationResult.failure('批量创建失败: ${e.toString()}');
    }
  }

  /// 创建变体商品
  Future<ProductOperationResult> _createVariants({
    required ProductFormData data,
    required int? categoryId,
    required int unitId,
    required int? groupId,
    required ProductUnitSyncService productUnitSyncService,
  }) async {
    final ops = _ref.read(productOperationsProvider.notifier);
    final barcodeSyncService = _ref.read(barcodeSyncServiceProvider);

    int successCount = 0;
    final List<String> errors = [];

    for (final variant in data.variants) {
      if (variant.variantName.trim().isEmpty) continue;

      try {
        // 构建变体商品名称
        final productName = '${data.name.trim()} ${variant.variantName.trim()}';

        final product = ProductModel(
          id: DateTime.now().millisecondsSinceEpoch + successCount,
          name: productName,
          image: data.imagePath,
          categoryId: categoryId,
          baseUnitId: unitId,
          groupId: groupId,
          variantName: variant.variantName.trim(),
          cost: MoneyConverter.yuanToMoney(data.costInCents),
          suggestedRetailPrice: MoneyConverter.yuanToMoney(data.suggestedRetailPriceInCents),
          retailPrice: MoneyConverter.yuanToMoney(data.retailPriceInCents),
          promotionalPrice: MoneyConverter.yuanToMoney(data.promotionalPriceInCents),
          stockWarningValue: data.stockWarningValue,
          shelfLife: data.shelfLife,
          shelfLifeUnit: ShelfLifeUnit.values.byName(data.shelfLifeUnit),
          enableBatchManagement: data.enableBatchManagement,
          remarks: data.remarks?.trim(),
          lastUpdated: DateTime.now(),
        );

        await ops.addProduct(product);
        ProductLogger.debug('创建变体: "${variant.variantName}"', tag: 'SubmitMultiVariants');

        // 保存单位配置
        await productUnitSyncService.syncProductUnits(product, data.productUnits);

        // 保存条码（如果变体有自己的条码）
        if (variant.barcode.trim().isNotEmpty) {
          await barcodeSyncService.syncMainBarcode(product, variant.barcode.trim());
        }

        successCount++;
      } catch (e) {
        ProductLogger.error(
          '创建变体失败: "${variant.variantName}"',
          tag: 'SubmitMultiVariants',
          error: e,
        );
        errors.add('${variant.variantName}: $e');
      }
    }

    // 构建结果消息
    if (successCount == 0) {
      return ProductOperationResult.failure('创建失败: ${errors.join(', ')}');
    }

    final message = successCount == data.variants.length
        ? '成功创建 $successCount 个变体商品'
        : '成功创建 $successCount 个变体商品，${errors.length} 个失败';

    return ProductOperationResult.success(message: message);
  }

  /// 刷新相关 Provider
  void _invalidateProviders() {
    _ref.invalidate(allProductsProvider);
    _ref.invalidate(categoryListProvider);
    _ref.invalidate(allProductGroupsProvider);
  }
}

/// SubmitMultiVariantsUseCase Provider
final submitMultiVariantsUseCaseProvider = Provider<SubmitMultiVariantsUseCase>((ref) {
  return SubmitMultiVariantsUseCase(ref);
});
