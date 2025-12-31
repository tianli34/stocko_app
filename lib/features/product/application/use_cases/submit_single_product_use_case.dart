// lib/features/product/application/use_cases/submit_single_product_use_case.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/converters/money_converter.dart';
import '../../core/logger/product_logger.dart';
import '../../domain/model/product.dart';
import '../../presentation/models/product_form_data.dart';
import '../../presentation/models/product_operation_result.dart';
import '../category_notifier.dart';
import '../provider/barcode_providers.dart';
import '../provider/product_providers.dart';
import '../services/barcode_sync_service.dart';
import '../services/category_resolver_service.dart';
import '../services/product_unit_sync_service.dart';
import '../services/unit_resolver_service.dart';

/// 提交单个商品用例
/// 
/// 编排单个商品的创建/更新流程
class SubmitSingleProductUseCase {
  final Ref _ref;

  SubmitSingleProductUseCase(this._ref);

  /// 执行用例
  /// 
  /// [data] 表单数据
  /// 返回操作结果
  Future<ProductOperationResult> execute(ProductFormData data) async {
    ProductLogger.separator('提交单个商品', isStart: true);

    try {
      // 1. 解析类别
      final categoryResolver = _ref.read(categoryResolverServiceProvider);
      final categoryId = await categoryResolver.resolve(
        selectedCategoryId: data.selectedCategoryId,
        newCategoryName: data.newCategoryName,
      );
      ProductLogger.debug('类别ID: $categoryId', tag: 'SubmitSingleProduct');

      // 2. 解析单位
      final unitResolver = _ref.read(unitResolverServiceProvider);
      final unitId = await unitResolver.resolve(
        selectedUnitId: data.selectedUnitId,
        newUnitName: data.newUnitName,
      );

      if (unitId == null) {
        ProductLogger.error('未选择计量单位', tag: 'SubmitSingleProduct');
        return ProductOperationResult.failure('请选择计量单位');
      }
      ProductLogger.debug('单位ID: $unitId', tag: 'SubmitSingleProduct');

      // 3. 处理辅单位（确保新单位已创建）
      final productUnitSyncService = _ref.read(productUnitSyncServiceProvider);
      await productUnitSyncService.processAuxiliaryUnits();

      // 4. 构建产品对象
      final product = _buildProductModel(data, categoryId, unitId);
      ProductLogger.debug(
        '产品: name="${product.name}", categoryId=$categoryId, unitId=$unitId',
        tag: 'SubmitSingleProduct',
      );

      // 5. 保存产品
      final ops = _ref.read(productOperationsProvider.notifier);
      if (data.isCreateMode) {
        await ops.addProduct(product);
        ProductLogger.debug('产品创建成功', tag: 'SubmitSingleProduct');
      } else {
        await ops.updateProduct(product);
        ProductLogger.debug('产品更新成功', tag: 'SubmitSingleProduct');
      }

      // 6. 保存单位配置
      await productUnitSyncService.syncProductUnits(product, data.productUnits);

      // 7. 保存条码
      final barcodeSyncService = _ref.read(barcodeSyncServiceProvider);
      await barcodeSyncService.syncMainBarcode(product, data.barcode);
      await barcodeSyncService.syncAuxiliaryBarcodes(product);

      // 8. 刷新相关 Provider
      _invalidateProviders(product);

      ProductLogger.separator('提交单个商品完成', isStart: false);

      return ProductOperationResult.success(
        message: data.isCreateMode ? '创建成功' : '更新成功',
        product: product,
      );
    } catch (e) {
      ProductLogger.error('保存失败', tag: 'SubmitSingleProduct', error: e);
      return ProductOperationResult.failure('保存失败: ${e.toString()}');
    }
  }

  /// 构建产品模型
  ProductModel _buildProductModel(
    ProductFormData data,
    int? categoryId,
    int unitId,
  ) {
    return ProductModel(
      id: data.productId ?? DateTime.now().millisecondsSinceEpoch,
      name: data.name.trim(),
      image: data.imagePath,
      categoryId: categoryId,
      baseUnitId: unitId,
      groupId: data.groupId,
      variantName: data.variantName?.trim(),
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
  }

  /// 刷新相关 Provider
  void _invalidateProviders(ProductModel product) {
    _ref.invalidate(allProductsProvider);
    _ref.invalidate(mainBarcodeProvider(product.id!));
    _ref.invalidate(categoryListProvider);
  }
}

/// SubmitSingleProductUseCase Provider
final submitSingleProductUseCaseProvider = Provider<SubmitSingleProductUseCase>((ref) {
  return SubmitSingleProductUseCase(ref);
});
