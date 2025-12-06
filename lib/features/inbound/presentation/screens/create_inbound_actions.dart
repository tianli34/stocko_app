import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/sound_helper.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../../application/provider/inbound_list_provider.dart';
import '../../application/service/inbound_service.dart';
import 'create_inbound_controller.dart';

/// 入库页面操作方法 - 作为 mixin 使用
mixin CreateInboundActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  CreateInboundController get controller;
  bool get mounted;

  void addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    if (result == null || result.isEmpty) return;

    try {
      final productsWithUnit = await ref.read(allProductsWithUnitProvider.future);
      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        ref.read(inboundListProvider.notifier).addOrUpdateItem(
              product: p.product,
              unitId: p.unitId,
              unitName: p.unitName,
              conversionRate: p.conversionRate,
              wholesalePriceInCents: p.wholesalePriceInCents,
            );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: '添加货品失败: ${e.toString()}',
        isError: true,
      );
    }
  }

  void scanToAddProduct() async {
    final barcode = await BarcodeScannerService.scan(
      context,
      config: const BarcodeScannerConfig(
        title: '扫码添加货品',
        subtitle: '扫描货品条码以添加入库单',
      ),
    );
    if (barcode != null) {
      _handleSingleProductScan(barcode);
    }
  }

  void continuousScan() {
    controller.lastScannedBarcode = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerService.scannerBuilder(
          config: const BarcodeScannerConfig(
            title: '连续扫码',
            subtitle: '将条码对准扫描框，自动连续添加',
            continuousMode: true,
            continuousDelay: 1500,
            showScanHistory: true,
            maxHistoryItems: 20,
          ),
          onBarcodeScanned: _handleContinuousProductScan,
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

  void _handleSingleProductScan(String barcode) async {
    showAppSnackBar(context, message: '正在查询货品信息...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!mounted) return;

      if (result != null) {
        ref.read(inboundListProvider.notifier).addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              conversionRate: result.conversionRate,
              barcode: barcode,
              wholesalePriceInCents: result.wholesalePriceInCents,
            );
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: '❌ 查询货品失败: $e', isError: true);
    }
  }

  void _handleContinuousProductScan(String barcode) async {
    showAppSnackBar(context, message: '条码: $barcode...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!mounted) return;

      if (result != null) {
        ref.read(inboundListProvider.notifier).addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              conversionRate: result.conversionRate,
              barcode: barcode,
              wholesalePriceInCents: result.wholesalePriceInCents,
            );
        controller.lastScannedBarcode = barcode;
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        controller.lastScannedBarcode = null;
        showAppSnackBar(
          context,
          message: '❌ 未找到条码对应的货品: $barcode',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      controller.lastScannedBarcode = null;
      showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
    }
  }

  void _showProductNotFoundDialog(String barcode) {
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

  void confirmPurchaseOnly() async {
    if (controller.isProcessing) return;
    if (!controller.validateForm()) return;

    _setProcessing(true);
    _showProcessingDialog();

    try {
      final inboundService = ref.read(inboundServiceProvider);
      final supplierInfo = controller.getSupplierInfo();
      final inboundItems = ref.read(inboundListProvider);

      final orderNumber = await inboundService.processPurchaseOnly(
        shopId: controller.selectedShop!.id!,
        inboundItems: inboundItems,
        supplierId: supplierInfo.supplierId,
        supplierName: supplierInfo.supplierName,
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 采购成功！采购单号：$orderNumber');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.inventoryPurchaseRecords);
        }
      });
    } catch (e, st) {
      Navigator.of(context).pop();
      debugPrint('❌ 采购失败: $e');
      debugPrintStack(stackTrace: st);
      showAppSnackBar(
        context,
        message: '❌ 采购失败: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        _setProcessing(false);
      }
    }
  }

  void confirmInbound() async {
    if (controller.isProcessing) return;
    if (!controller.validateForm()) return;

    _setProcessing(true);
    _showProcessingDialog();

    try {
      final inboundService = ref.read(inboundServiceProvider);
      final String source;
      final int? supplierId;
      final String? supplierName;
      final bool isPurchaseMode = controller.currentMode == InboundMode.purchase;

      if (isPurchaseMode) {
        source = '采购';
        final supplierInfo = controller.getSupplierInfo();
        supplierId = supplierInfo.supplierId;
        supplierName = supplierInfo.supplierName;
      } else {
        source = controller.sourceController.text.trim().isEmpty
            ? '非采购'
            : controller.sourceController.text.trim();
        supplierId = null;
        supplierName = null;
      }

      final inboundItems = ref.read(inboundListProvider);

      final receiptNumber = await inboundService.processOneClickInbound(
        shopId: controller.selectedShop!.id!,
        inboundItems: inboundItems,
        remarks: controller.remarksController.text.isNotEmpty
            ? controller.remarksController.text
            : null,
        source: source,
        isPurchaseMode: isPurchaseMode,
        supplierId: supplierId,
        supplierName: supplierName,
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 一键入库成功！入库单号：$receiptNumber');

      ref.invalidate(inboundRecordsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.inventoryInboundRecords);
        }
      });
    } catch (e, st) {
      Navigator.of(context).pop();
      debugPrint('❌ 一键入库失败: $e');
      debugPrintStack(stackTrace: st);
      showAppSnackBar(
        context,
        message: '❌ 一键入库失败: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        _setProcessing(false);
      }
    }
  }

  void _setProcessing(bool value) {
    controller.isProcessing = value;
    if (mounted) {
      setState(() {});
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(width: 24),
              Text('正在处理...', style: theme.textTheme.titleMedium),
            ],
          ),
        );
      },
    );
  }
}
