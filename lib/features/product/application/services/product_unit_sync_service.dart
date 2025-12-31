// lib/features/product/application/services/product_unit_sync_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger/product_logger.dart';
import '../../domain/model/auxiliary_unit_data.dart';
import '../../domain/model/product.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/unit.dart';
import '../../presentation/state/product_form_ui_provider.dart';
import '../provider/barcode_providers.dart';
import '../provider/product_unit_providers.dart';
import '../provider/unit_edit_form_providers.dart';
import '../provider/unit_providers.dart';

/// 产品单位同步服务
/// 
/// 负责产品单位配置的保存与同步
class ProductUnitSyncService {
  final Ref _ref;

  ProductUnitSyncService(this._ref);

  /// 同步产品单位配置
  /// 
  /// [product] 产品模型
  /// [productUnits] 传入的产品单位列表（可选）
  Future<void> syncProductUnits(
    ProductModel product,
    List<UnitProduct>? productUnits,
  ) async {
    ProductLogger.separator('开始保存产品单位', isStart: true);
    ProductLogger.debug('产品ID: ${product.id}', tag: 'ProductUnitSync');
    ProductLogger.debug('传入单位数量: ${productUnits?.length ?? 0}', tag: 'ProductUnitSync');

    // 获取 UI 状态，检查是否进入过辅单位编辑页面
    final uiState = _ref.read(productFormUiProvider);
    final hasEnteredAuxUnitPage = uiState.hasEnteredAuxUnitPage;
    ProductLogger.debug('是否进入过辅单位页面: $hasEnteredAuxUnitPage', tag: 'ProductUnitSync');

    // 获取辅单位数据
    List<AuxiliaryUnitData> auxiliaryUnits;
    if (hasEnteredAuxUnitPage) {
      ProductLogger.debug('从表单状态获取辅单位数据', tag: 'ProductUnitSync');
      final formState = _ref.read(unitEditFormProvider);
      auxiliaryUnits = formState.auxiliaryUnits;
    } else if (product.id != null) {
      ProductLogger.debug('从数据库加载现有辅单位数据', tag: 'ProductUnitSync');
      auxiliaryUnits = await _loadExistingAuxiliaryUnits(product.id!);
    } else {
      ProductLogger.debug('新增模式，无辅单位数据', tag: 'ProductUnitSync');
      auxiliaryUnits = [];
    }

    ProductLogger.debug('辅单位数量: ${auxiliaryUnits.length}', tag: 'ProductUnitSync');

    // 构建产品单位列表
    final list = await _buildProductUnitList(product, auxiliaryUnits);

    // 保存到数据库
    final ctrl = _ref.read(productUnitControllerProvider.notifier);
    try {
      await ctrl.replaceProductUnits(product.id!, list);
      ProductLogger.debug('产品单位保存成功', tag: 'ProductUnitSync');
    } catch (e) {
      ProductLogger.error('产品单位保存失败', tag: 'ProductUnitSync', error: e);
      rethrow;
    }

    ProductLogger.separator('产品单位保存完成', isStart: false);
  }

  /// 构建产品单位列表
  Future<List<UnitProduct>> _buildProductUnitList(
    ProductModel product,
    List<AuxiliaryUnitData> auxiliaryUnits,
  ) async {
    final list = <UnitProduct>[];

    // 添加基础单位
    list.add(
      UnitProduct(
        productId: product.id!,
        unitId: product.baseUnitId,
        conversionRate: 1,
      ),
    );

    // 获取最新的单位列表
    final allUnits = await _ref.read(allUnitsProvider.future);
    ProductLogger.debug('单位总数: ${allUnits.length}', tag: 'ProductUnitSync');

    // 添加辅单位
    for (final auxUnit in auxiliaryUnits) {
      final unitName = auxUnit.unitName.trim();
      ProductLogger.debug(
        '处理辅单位: "$unitName", 换算率: ${auxUnit.conversionRate}',
        tag: 'ProductUnitSync',
      );

      if (unitName.isEmpty) {
        ProductLogger.debug('单位名称为空，跳过', tag: 'ProductUnitSync');
        continue;
      }

      // 查找单位
      Unit? unit;
      try {
        unit = allUnits
            .where((u) => u.name.toLowerCase() == unitName.toLowerCase())
            .firstOrNull;
      } catch (e) {
        unit = null;
      }

      if (unit != null && unit.id != null) {
        list.add(
          UnitProduct(
            productId: product.id!,
            unitId: unit.id!,
            conversionRate: auxUnit.conversionRate,
            sellingPriceInCents: auxUnit.retailPriceInCents.trim().isNotEmpty
                ? int.tryParse(auxUnit.retailPriceInCents.trim())
                : null,
            wholesalePriceInCents: auxUnit.wholesalePriceInCents.trim().isNotEmpty
                ? int.tryParse(auxUnit.wholesalePriceInCents.trim())
                : null,
          ),
        );
        ProductLogger.debug(
          '添加辅单位: ${unit.name} (ID: ${unit.id}, 换算率: ${auxUnit.conversionRate})',
          tag: 'ProductUnitSync',
        );
      } else {
        ProductLogger.error('未找到单位: "$unitName"', tag: 'ProductUnitSync');
        throw Exception('保存产品单位失败：无法找到单位 "$unitName"。请检查单位是否已正确添加。');
      }
    }

    ProductLogger.debug('最终保存的单位数量: ${list.length}', tag: 'ProductUnitSync');
    return list;
  }

  /// 从数据库加载现有辅单位数据
  Future<List<AuxiliaryUnitData>> _loadExistingAuxiliaryUnits(int productId) async {
    try {
      final productUnitController = _ref.read(productUnitControllerProvider.notifier);
      final barcodeController = _ref.read(barcodeControllerProvider.notifier);

      // 获取所有产品单位
      final allProductUnits = await productUnitController.getProductUnitsByProductId(productId);

      // 过滤出辅单位（换算率不为1）
      final auxiliaryProductUnits = allProductUnits
          .where((pu) => pu.conversionRate != 1.0)
          .toList();

      if (auxiliaryProductUnits.isEmpty) {
        return [];
      }

      // 获取所有单位信息
      final allUnits = await _ref.read(allUnitsProvider.future);

      // 转换为 AuxiliaryUnitData 格式
      final List<AuxiliaryUnitData> auxiliaryUnitsData = [];

      for (final productUnit in auxiliaryProductUnits) {
        // 查找单位名称
        final unit = allUnits.firstWhere(
          (u) => u.id == productUnit.unitId,
          orElse: () => Unit(name: 'Unknown'),
        );

        // 查找条码
        final barcodes = await barcodeController.getBarcodesByProductUnitId(productUnit.id);
        final barcodeValue = barcodes.isNotEmpty ? barcodes.first.barcodeValue : '';

        // 转换价格
        final retailPrice = productUnit.sellingPriceInCents?.toString() ?? '';
        final wholesalePrice = productUnit.wholesalePriceInCents?.toString() ?? '';

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

        ProductLogger.debug(
          '加载辅单位: ${unit.name}, 换算率: ${productUnit.conversionRate}',
          tag: 'ProductUnitSync',
        );
      }

      return auxiliaryUnitsData;
    } catch (e) {
      ProductLogger.error('加载现有辅单位失败', tag: 'ProductUnitSync', error: e);
      return [];
    }
  }

  /// 处理辅单位 - 检查并插入新的辅单位到单位表
  Future<void> processAuxiliaryUnits() async {
    ProductLogger.separator('开始处理辅单位', isStart: true);

    // 获取辅单位表单数据
    final formState = _ref.read(unitEditFormProvider);
    ProductLogger.debug('表单中的辅单位数量: ${formState.auxiliaryUnits.length}', tag: 'ProductUnitSync');

    if (formState.auxiliaryUnits.isEmpty) {
      ProductLogger.debug('表单中没有辅单位数据，跳过处理', tag: 'ProductUnitSync');
      return;
    }

    final unitCtrl = _ref.read(unitControllerProvider.notifier);
    final units = _ref
        .read(allUnitsProvider)
        .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);

    ProductLogger.debug('当前数据库中的单位数量: ${units.length}', tag: 'ProductUnitSync');

    for (int i = 0; i < formState.auxiliaryUnits.length; i++) {
      final auxUnit = formState.auxiliaryUnits[i];
      final unitName = auxUnit.unitName.trim();

      ProductLogger.debug('处理辅单位 ${i + 1}: "$unitName"', tag: 'ProductUnitSync');

      if (unitName.isEmpty) {
        ProductLogger.debug('单位名称为空，跳过', tag: 'ProductUnitSync');
        continue;
      }

      // 检查单位是否已存在
      Unit? existingUnit;
      existingUnit = units
          .where((u) => u.name.toLowerCase() == unitName.toLowerCase())
          .firstOrNull;

      if (existingUnit != null) {
        ProductLogger.debug(
          '单位已存在: ID=${existingUnit.id}, 名称="${existingUnit.name}"',
          tag: 'ProductUnitSync',
        );
      } else {
        // 创建新单位
        ProductLogger.debug('创建新单位: "$unitName"', tag: 'ProductUnitSync');
        try {
          final newUnit = await unitCtrl.addUnit(Unit(name: unitName));
          ProductLogger.debug('新单位创建成功, ID: ${newUnit.id}', tag: 'ProductUnitSync');
          units.add(newUnit);
          _ref.invalidate(allUnitsProvider);
        } catch (e) {
          ProductLogger.error('新单位创建失败', tag: 'ProductUnitSync', error: e);
          throw Exception('创建单位失败: $unitName - $e');
        }
      }
    }

    // 最终刷新单位数据
    _ref.invalidate(allUnitsProvider);
    ProductLogger.separator('辅单位处理完成', isStart: false);
  }
}

/// ProductUnitSyncService Provider
final productUnitSyncServiceProvider = Provider<ProductUnitSyncService>((ref) {
  return ProductUnitSyncService(ref);
});
