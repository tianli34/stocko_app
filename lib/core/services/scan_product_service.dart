import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/product/application/provider/product_providers.dart';
import '../models/scanned_product_payload.dart';
import '../services/barcode_scanner_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/product_info_dialog.dart';
import '../constants/app_routes.dart';

/// 扫码产品服务，负责处理扫码、查询产品、展示对话框等业务逻辑
class ScanProductService {
  /// 扫码并显示产品信息对话框
  /// 
  /// 流程：
  /// 1. 调起扫码界面
  /// 2. 根据条码查询产品信息
  /// 3. 如果找到产品，显示产品信息对话框
  /// 4. 如果未找到，提示用户是否新增产品
  static Future<void> scanAndShowProductDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 1) 调起扫码
    final barcode = await BarcodeScannerService.quickScan(
      context,
      title: '扫描条码',
    );
    if (!context.mounted || barcode == null || barcode.isEmpty) return;

    // 2) 查询货品主要信息
    try {
      final operations = ref.read(productOperationsProvider.notifier);
      final result = await operations.getProductWithUnitByBarcode(barcode);

      if (!context.mounted) return;

      if (result == null) {
        // 未找到条码，显示对话框让用户选择
        await _handleProductNotFound(context, barcode);
        return;
      }

      // 3) 构建 payload 并展示复用对话框
      final payload = ScannedProductPayload(
        product: result.product,
        barcode: barcode,
        unitId: result.unitId,
        unitName: result.unitName,
        conversionRate: result.conversionRate,
        sellingPriceInCents: result.sellingPriceInCents,
        wholesalePriceInCents: result.wholesalePriceInCents,
        averageUnitPriceInSis: result.averageUnitPriceInSis,
      );

      await _handleProductFound(context, payload);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: '查询货品失败：$e', isError: true);
    }
  }

  /// 处理未找到产品的情况
  static Future<void> _handleProductNotFound(
    BuildContext context,
    String barcode,
  ) async {
    final shouldAddProduct = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未找到货品'),
        content: Text('未找到条码 "$barcode" 对应的货品，是否新增？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('新增货品'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (shouldAddProduct == true) {
      context.push(AppRoutes.productNew, extra: barcode);
    }
  }

  /// 处理找到产品的情况
  static Future<void> _handleProductFound(
    BuildContext context,
    ScannedProductPayload payload,
  ) async {
    final action = await showProductInfoDialog(context, payload: payload);
    if (!context.mounted) return;

    switch (action) {
      case ProductInfoAction.sale:
        context.push(AppRoutes.saleCreate, extra: payload);
        break;
      case ProductInfoAction.purchase:
        context.push(AppRoutes.inboundCreate, extra: payload);
        break;
      case ProductInfoAction.cancel:
      case null:
        break;
    }
  }
}
