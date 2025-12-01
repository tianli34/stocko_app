import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stocko_app/core/utils/snackbar_helper.dart';
import '../widgets/universal_barcode_scanner.dart';

/// 扫码服务类
class BarcodeScannerService {
  /// 可注入的扫描器Widget构建器（用于测试替换）
  /// 生产环境默认构建 UniversalBarcodeScanner
  static Widget Function({
    required BarcodeScannerConfig config,
    required OnBarcodeScanned onBarcodeScanned,
    GetProductInfo? getProductInfo,
    Widget? loadingWidget,
    bool isLoading,
  }) scannerBuilder = ({
    required BarcodeScannerConfig config,
    required OnBarcodeScanned onBarcodeScanned,
    GetProductInfo? getProductInfo,
    Widget? loadingWidget,
    bool isLoading = false,
  }) => UniversalBarcodeScanner(
        config: config,
        onBarcodeScanned: onBarcodeScanned,
        getProductInfo: getProductInfo,
        loadingWidget: loadingWidget,
        isLoading: isLoading,
      );

  /// 通用扫码方法
  /// 返回扫描到的条码字符串，如果取消则返回null
  static Future<String?> scan(
    BuildContext context, {
    BarcodeScannerConfig? config,
    GetProductInfo? getProductInfo,
    Widget? loadingWidget,
    bool isLoading = false,
  }) async {
    final scannerConfig = config ?? const BarcodeScannerConfig();

    return await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => scannerBuilder(
          config: scannerConfig,
          onBarcodeScanned: (barcode) {
            Navigator.of(context).pop(barcode);
          },
          getProductInfo: getProductInfo,
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


}
