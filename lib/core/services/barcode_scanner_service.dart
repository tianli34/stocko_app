import 'package:flutter/material.dart';
import '../widgets/universal_barcode_scanner.dart';

/// 扫码服务类
class BarcodeScannerService {
  /// 通用扫码方法
  /// 返回扫描到的条码字符串，如果取消则返回null
  static Future<String?> scan(
    BuildContext context, {
    BarcodeScannerConfig? config,
    Widget? loadingWidget,
    bool isLoading = false,
  }) async {
    final scannerConfig = config ?? const BarcodeScannerConfig();

    return await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => UniversalBarcodeScanner(
          config: scannerConfig,
          onBarcodeScanned: (barcode) {
            Navigator.of(context).pop(barcode);
          },
          loadingWidget: loadingWidget,
          isLoading: isLoading,
        ),
      ),
    );
  }

  /// 简单扫码（使用默认配置）
  static Future<String?> quickScan(
    BuildContext context, {
    String? title,
  }) async {
    return await scan(
      context,
      config: BarcodeScannerConfig(title: title ?? '扫描条码'),
    );
  }

  /// 产品条码扫描（针对产品管理优化）
  static Future<String?> scanForProduct(
    BuildContext context, {
    bool continuousMode = false,
  }) async {
    return await scan(
      context,
      config: BarcodeScannerConfig(
        title: '扫描产品条码',
        subtitle: '将产品条码对准扫描框',
        enableManualInput: true,
        enableGalleryPicker: true,
        continuousMode: continuousMode,
        continuousDelay: 1000,
      ),
    );
  }

  /// 入库扫码（支持异步处理状态）
  static Future<T?> scanForInbound<T>(
    BuildContext context, {
    required Future<T?> Function(String barcode) onBarcodeScanned,
    Widget? loadingWidget,
  }) async {
    T? result;
    bool isLoading = false;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return UniversalBarcodeScanner(
              config: const BarcodeScannerConfig(
                title: '扫码添加商品',
                subtitle: '将商品条码对准扫描框',
                enableManualInput: true,
                enableGalleryPicker: true,
              ),
              onBarcodeScanned: (barcode) async {
                setState(() {
                  isLoading = true;
                });

                try {
                  result = await onBarcodeScanned(barcode);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    setState(() {
                      isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('处理失败: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              loadingWidget: loadingWidget,
              isLoading: isLoading,
            );
          },
        ),
      ),
    );

    return result;
  }

  /// 采购扫码（支持连续扫码）
  static Future<List<String>> scanForPurchase(
    BuildContext context, {
    bool continuousMode = false,
    int? maxScans,
  }) async {
    final scannedCodes = <String>[];

    if (!continuousMode) {
      final code = await scan(
        context,
        config: const BarcodeScannerConfig(
          title: '扫码添加商品',
          subtitle: '将商品条码对准扫描框',
        ),
      );
      if (code != null) {
        scannedCodes.add(code);
      }
      return scannedCodes;
    }

    // 连续扫码模式的实现会在后续完善
    // 这里先返回单次扫码结果
    final code = await scan(
      context,
      config: const BarcodeScannerConfig(
        title: '连续扫码模式',
        subtitle: '扫描完成后点击返回按钮结束',
      ),
    );
    if (code != null) {
      scannedCodes.add(code);
    }

    return scannedCodes;
  }
}
