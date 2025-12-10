import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/barcode_scanner_service.dart';
import '../utils/snackbar_helper.dart';
import '../utils/sound_helper.dart';
import '../widgets/universal_barcode_scanner.dart';
import '../../features/product/application/provider/product_providers.dart';

typedef ProductScanResult = ({
  dynamic product,
  int unitId,
  String unitName,
  int conversionRate,
  int? sellingPriceInCents,
  int? wholesalePriceInCents,
  String? barcode,
});

/// 货品扫码添加功能的通用工具类
class ProductScanMixin {
  static Future<ProductScanResult?> scanProduct({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
  }) async {
    final barcode = await BarcodeScannerService.scan(
      context,
      config: BarcodeScannerConfig(
        title: title,
        subtitle: subtitle,
      ),
    );
    if (barcode == null) return null;

    showAppSnackBar(context, message: '正在查询货品信息...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!context.mounted) return null;

      if (result != null) {
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
        return (
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          conversionRate: result.conversionRate,
          barcode: barcode,
          sellingPriceInCents: result.sellingPriceInCents,
          wholesalePriceInCents: result.wholesalePriceInCents,
        );
      } else {
        _showProductNotFoundDialog(context, barcode);
        return null;
      }
    } catch (e) {
      if (!context.mounted) return null;
      showAppSnackBar(context, message: '❌ 查询货品失败: $e', isError: true);
      return null;
    }
  }

  static void continuousScanProduct({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required void Function(ProductScanResult) onProductScanned,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerService.scannerBuilder(
          config: BarcodeScannerConfig(
            title: title,
            subtitle: subtitle,
            continuousMode: true,
            continuousDelay: 1500,
            showScanHistory: true,
            maxHistoryItems: 20,
          ),
          onBarcodeScanned: (barcode) => _handleContinuousProductScan(
            context: context,
            ref: ref,
            barcode: barcode,
            onProductScanned: onProductScanned,
          ),
          getProductInfo: (barcode) async {
            try {
              final productOperations = ref.read(productOperationsProvider.notifier);
              final result = await productOperations.getProductWithUnitByBarcode(barcode);
              if (result != null) {
                return (
                  name: result.product.name,
                  unitName: result.unitName,
                  conversionRate: result.conversionRate,
                );
              }
              return null;
            } catch (e) {
              return null;
            }
          },
        ),
      ),
    );
  }

  static void _handleContinuousProductScan({
    required BuildContext context,
    required WidgetRef ref,
    required String barcode,
    required void Function(ProductScanResult) onProductScanned,
  }) async {
    showAppSnackBar(context, message: '条码: $barcode...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!context.mounted) return;

      if (result != null) {
        onProductScanned((
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          conversionRate: result.conversionRate,
          barcode: barcode,
          sellingPriceInCents: result.sellingPriceInCents,
          wholesalePriceInCents: result.wholesalePriceInCents,
        ));
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        showAppSnackBar(
          context,
          message: '❌ 未找到条码对应的货品: $barcode',
          isError: true,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
    }
  }

  static void _showProductNotFoundDialog(BuildContext context, String barcode) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        return AlertDialog(
          title: Text('货品未找到', style: textTheme.titleLarge),
          content: Text(
            '条码 $barcode 对应的货品未在系统中找到。',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
