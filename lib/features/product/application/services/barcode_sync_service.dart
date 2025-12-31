// lib/features/product/application/services/barcode_sync_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger/product_logger.dart';
import '../../data/repository/product_unit_repository.dart';
import '../../domain/model/auxiliary_unit_data.dart';
import '../../domain/model/barcode.dart';
import '../../domain/model/product.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/unit.dart';
import '../../presentation/state/product_form_ui_provider.dart';
import '../provider/barcode_providers.dart';
import '../provider/product_unit_providers.dart';
import '../provider/unit_edit_form_providers.dart';
import '../provider/unit_providers.dart';

/// 条码同步服务
/// 
/// 负责主条码和辅单位条码的同步逻辑
class BarcodeSyncService {
  final Ref _ref;

  BarcodeSyncService(this._ref);

  /// 同步主条码
  /// 
  /// [product] 产品模型
  /// [barcode] 条码值
  Future<void> syncMainBarcode(ProductModel product, String barcode) async {
    ProductLogger.debug('开始同步主条码: "$barcode"', tag: 'BarcodeSync');

    final code = barcode.trim();
    final barcodeCtrl = _ref.read(barcodeControllerProvider.notifier);
    final productUnitRepository = _ref.read(productUnitRepositoryProvider);

    // 1. 找到基础产品单位ID
    final productUnitController = _ref.read(productUnitControllerProvider.notifier);
    final productUnits = await productUnitController.getProductUnitsByProductId(product.id!);
    final baseProductUnit = productUnits
        .where((pu) => pu.conversionRate == 1.0)
        .firstOrNull;

    if (baseProductUnit == null) {
      ProductLogger.error('未找到基础产品单位', tag: 'BarcodeSync');
      throw Exception('保存主条码失败：未找到基础产品单位。');
    }

    final baseUnitProductId = baseProductUnit.id!;
    ProductLogger.debug('基础产品单位ID: $baseUnitProductId', tag: 'BarcodeSync');

    // 2. 查找与输入条码匹配的现有条码
    final existingBarcode = code.isEmpty
        ? null
        : await barcodeCtrl.getBarcodeByValue(code);

    // 3. 验证条码是否被其他货品占用
    if (existingBarcode != null) {
      final productUnit = await productUnitRepository.getProductUnitById(
        existingBarcode.unitProductId,
      );
      if (productUnit != null && productUnit.productId != product.id) {
        ProductLogger.error('条码被其他货品占用: "$code"', tag: 'BarcodeSync');
        throw Exception('条码 "$code" 已被其他货品使用，无法重复添加。');
      }
    }

    // 4. 同步主条码
    if (code.isEmpty) {
      // 如果输入为空，删除现有的主条码
      if (existingBarcode != null &&
          existingBarcode.unitProductId == baseUnitProductId) {
        await barcodeCtrl.deleteBarcode(existingBarcode.id!);
        ProductLogger.debug('已删除主条码', tag: 'BarcodeSync');
      }
    } else {
      // 输入不为空
      if (existingBarcode != null) {
        // 条码已存在，更新其 unitProductId
        if (existingBarcode.unitProductId != baseUnitProductId) {
          await barcodeCtrl.updateBarcode(
            existingBarcode.copyWith(unitProductId: baseUnitProductId),
          );
          ProductLogger.debug('已更新主条码关联', tag: 'BarcodeSync');
        }
      } else {
        // 条码不存在，添加新条码
        await barcodeCtrl.addBarcode(
          BarcodeModel(unitProductId: baseUnitProductId, barcodeValue: code),
        );
        ProductLogger.debug('已添加新主条码: "$code"', tag: 'BarcodeSync');
      }
    }
  }

  /// 同步辅单位条码
  /// 
  /// [product] 产品模型
  Future<void> syncAuxiliaryBarcodes(ProductModel product) async {
    ProductLogger.separator('开始保存辅单位条码', isStart: true);

    // 获取 UI 状态
    final uiState = _ref.read(productFormUiProvider);
    final hasEnteredAuxUnitPage = uiState.hasEnteredAuxUnitPage;
    ProductLogger.debug('是否进入过辅单位页面: $hasEnteredAuxUnitPage', tag: 'BarcodeSync');

    // 获取辅单位数据
    List<AuxiliaryUnitData> auxiliaryUnits;
    if (hasEnteredAuxUnitPage) {
      ProductLogger.debug('从表单状态获取辅单位条码数据', tag: 'BarcodeSync');
      final formState = _ref.read(unitEditFormProvider);
      auxiliaryUnits = formState.auxiliaryUnits;
    } else if (product.id != null) {
      ProductLogger.debug('从数据库加载现有辅单位条码数据', tag: 'BarcodeSync');
      auxiliaryUnits = await _loadExistingAuxiliaryUnits(product.id!);
    } else {
      ProductLogger.debug('新增模式，无辅单位条码数据', tag: 'BarcodeSync');
      auxiliaryUnits = [];
    }

    if (auxiliaryUnits.isEmpty) {
      ProductLogger.debug('没有辅单位数据，跳过条码保存', tag: 'BarcodeSync');
      return;
    }

    // 获取已保存的产品单位信息
    final productUnitController = _ref.read(productUnitControllerProvider.notifier);
    final productUnits = await productUnitController.getProductUnitsByProductId(product.id!);

    final ctrl = _ref.read(barcodeControllerProvider.notifier);
    final barcodes = <BarcodeModel>[];

    // 获取所有单位
    final allUnits = _ref
        .read(allUnitsProvider)
        .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);

    for (final auxUnit in auxiliaryUnits) {
      final code = auxUnit.barcode.trim();
      if (code.isEmpty) {
        ProductLogger.debug('辅单位 "${auxUnit.unitName}" 条码为空，跳过', tag: 'BarcodeSync');
        continue;
      }

      // 查找对应的单位
      Unit? targetUnit;
      try {
        targetUnit = allUnits
            .where((u) => u.name.toLowerCase() == auxUnit.unitName.trim().toLowerCase())
            .firstOrNull;
      } catch (e) {
        targetUnit = null;
      }

      if (targetUnit != null) {
        // 查找匹配的产品单位
        UnitProduct? matchingProductUnit;
        matchingProductUnit = productUnits
            .where((pu) =>
                pu.unitId == targetUnit!.id &&
                pu.conversionRate == auxUnit.conversionRate)
            .firstOrNull;

        if (matchingProductUnit == null) {
          ProductLogger.error(
            '数据不一致：找不到单位 ${targetUnit.name} (换算率: ${auxUnit.conversionRate})',
            tag: 'BarcodeSync',
          );
          throw Exception(
            '数据不一致：在产品单位列表中找不到单位 ${targetUnit.name} (换算率: ${auxUnit.conversionRate})',
          );
        }

        if ((matchingProductUnit.id ?? 0) > 0) {
          barcodes.add(
            BarcodeModel(
              unitProductId: matchingProductUnit.id!,
              barcodeValue: code,
            ),
          );
          ProductLogger.debug(
            '添加辅单位条码: ${auxUnit.unitName} -> $code (ProductUnitId: ${matchingProductUnit.id})',
            tag: 'BarcodeSync',
          );
        }
      } else {
        ProductLogger.warning('未找到单位: ${auxUnit.unitName}', tag: 'BarcodeSync');
      }
    }

    if (barcodes.isNotEmpty) {
      await ctrl.addMultipleBarcodes(barcodes);
      ProductLogger.debug('成功保存 ${barcodes.length} 个辅单位条码', tag: 'BarcodeSync');
    } else {
      ProductLogger.debug('没有有效的辅单位条码需要保存', tag: 'BarcodeSync');
    }

    ProductLogger.separator('辅单位条码保存完成', isStart: false);
  }

  /// 从数据库加载现有辅单位数据
  Future<List<AuxiliaryUnitData>> _loadExistingAuxiliaryUnits(int productId) async {
    try {
      final productUnitController = _ref.read(productUnitControllerProvider.notifier);
      final barcodeController = _ref.read(barcodeControllerProvider.notifier);

      final allProductUnits = await productUnitController.getProductUnitsByProductId(productId);
      final auxiliaryProductUnits = allProductUnits
          .where((pu) => pu.conversionRate != 1.0)
          .toList();

      if (auxiliaryProductUnits.isEmpty) {
        return [];
      }

      final allUnits = await _ref.read(allUnitsProvider.future);
      final List<AuxiliaryUnitData> auxiliaryUnitsData = [];

      for (final productUnit in auxiliaryProductUnits) {
        final unit = allUnits.firstWhere(
          (u) => u.id == productUnit.unitId,
          orElse: () => Unit(name: 'Unknown'),
        );

        final barcodes = await barcodeController.getBarcodesByProductUnitId(productUnit.id);
        final barcodeValue = barcodes.isNotEmpty ? barcodes.first.barcodeValue : '';

        auxiliaryUnitsData.add(
          AuxiliaryUnitData(
            id: productUnit.id ?? 0,
            unitId: unit.id,
            unitName: unit.name,
            conversionRate: productUnit.conversionRate,
            barcode: barcodeValue,
            retailPriceInCents: productUnit.sellingPriceInCents?.toString() ?? '',
            wholesalePriceInCents: productUnit.wholesalePriceInCents?.toString() ?? '',
          ),
        );
      }

      return auxiliaryUnitsData;
    } catch (e) {
      ProductLogger.error('加载现有辅单位失败', tag: 'BarcodeSync', error: e);
      return [];
    }
  }
}

/// BarcodeSyncService Provider
final barcodeSyncServiceProvider = Provider<BarcodeSyncService>((ref) {
  return BarcodeSyncService(ref);
});
