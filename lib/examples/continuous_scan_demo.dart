import 'package:flutter/material.dart';
import 'package:stocko_app/core/services/barcode_scanner_service.dart';
import 'package:stocko_app/core/widgets/universal_barcode_scanner.dart';

/// 连续扫码示例页面
class ContinuousScanDemo extends StatefulWidget {
  const ContinuousScanDemo({super.key});

  @override
  State<ContinuousScanDemo> createState() => _ContinuousScanDemoState();
}

class _ContinuousScanDemoState extends State<ContinuousScanDemo> {
  final List<String> _scannedCodes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连续扫码演示'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 按钮区域
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _startSingleScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('单次扫码'),
                ),
                ElevatedButton.icon(
                  onPressed: _startContinuousScan,
                  icon: const Icon(Icons.repeat),
                  label: const Text('连续扫码'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('清空结果'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 结果区域
            Text(
              '扫码结果 (${_scannedCodes.length} 条)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _scannedCodes.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无扫码结果\n请点击上方按钮开始扫码',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _scannedCodes.length,
                      itemBuilder: (context, index) {
                        final code = _scannedCodes[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text('第 ${index + 1} 次扫码'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeCode(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 开始单次扫码
  void _startSingleScan() async {
    final result = await BarcodeScannerService.scanForProduct(
      context,
      continuousMode: false, // 单次扫码
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _scannedCodes.add(result);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ 扫码成功: $result'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 开始连续扫码
  void _startContinuousScan() async {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UniversalBarcodeScanner(
              config: const BarcodeScannerConfig(
                title: '连续扫码演示',
                subtitle: '扫码后会自动继续，点击返回键结束',
                continuousMode: true, // 启用连续扫码
                continuousDelay: 800, // 800毫秒后重新启用扫码
                enableManualInput: true,
                enableGalleryPicker: false,
                enableFlashlight: true,
                enableCameraSwitch: true,
                enableScanSound: true,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onBarcodeScanned: (barcode) {
                // 添加到结果列表
                _scannedCodes.add(barcode);

                // 显示成功提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ 已扫描: $barcode'),
                    backgroundColor: Colors.green,
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
          ),
        )
        .then((_) {
          // 连续扫码结束后刷新界面
          setState(() {});
        });
  }

  /// 清空结果
  void _clearResults() {
    setState(() {
      _scannedCodes.clear();
    });
  }

  /// 删除指定位置的结果
  void _removeCode(int index) {
    setState(() {
      _scannedCodes.removeAt(index);
    });
  }
}
