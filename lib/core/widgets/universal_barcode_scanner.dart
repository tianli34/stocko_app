import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:stocko_app/core/utils/snackbar_helper.dart';

/// 扫码结果回调类型定义
typedef OnBarcodeScanned = void Function(String barcode);
typedef OnScanError = void Function(String error);
typedef GetProductName = Future<String?> Function(String barcode);

/// 扫码历史记录项
class ScanHistoryItem {
  final String barcode;
  final String? productName;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.barcode,
    this.productName,
    required this.timestamp,
  });
}

/// 扫码配置类
class BarcodeScannerConfig {
  final String title;
  final String subtitle;
  final bool enableManualInput;
  final bool enableGalleryPicker;
  final bool enableFlashlight;
  final bool enableCameraSwitch;
  final bool enableScanSound;
  final bool continuousMode; // 连续扫码模式
  final int? continuousDelay; // 连续扫码延迟（毫秒）
  final bool showScanHistory; // 显示扫码历史
  final int maxHistoryItems; // 最大历史记录数
  final List<Widget>? additionalActions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const BarcodeScannerConfig({
    this.title = '扫描条码',
    this.subtitle = '将条码对准扫描框',
    this.enableManualInput = true,
    this.enableGalleryPicker = true,
    this.enableFlashlight = true,
    this.enableCameraSwitch = true,
    this.enableScanSound = true,
    this.continuousMode = false,
    this.continuousDelay = 1000, // 默认1秒延迟
    this.showScanHistory = false, // 默认不显示历史
    this.maxHistoryItems = 10, // 默认显示最近10条
    this.additionalActions,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
  });
}

/// 通用条码扫描器组件
class UniversalBarcodeScanner extends StatefulWidget {
  final BarcodeScannerConfig config;
  final OnBarcodeScanned onBarcodeScanned;
  final OnScanError? onScanError;
  final GetProductName? getProductName; // 获取商品名称的回调
  final Widget? loadingWidget;
  final bool isLoading;

  const UniversalBarcodeScanner({
    super.key,
    required this.config,
    required this.onBarcodeScanned,
    this.onScanError,
    this.getProductName,
    this.loadingWidget,
    this.isLoading = false,
  });

  @override
  State<UniversalBarcodeScanner> createState() =>
      _UniversalBarcodeScannerState();
}

class _UniversalBarcodeScannerState extends State<UniversalBarcodeScanner> {
  late MobileScannerController _cameraController;
  late AudioPlayer _audioPlayer;
  bool _isScanning = true;
  final List<ScanHistoryItem> _scanHistory = []; // 扫码历史记录
  int _totalScans = 0; // 扫码总数量

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
    _audioPlayer = AudioPlayer();
    _initializeAudioPlayer();
  }

  /// 初始化音频播放器
  void _initializeAudioPlayer() {
    try {
      // 设置音频播放器的模式，允许与其他音频混合
      _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      if (kDebugMode) {
        print('AudioPlayer 初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioPlayer 初始化失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
        backgroundColor: widget.config.backgroundColor,
        foregroundColor: widget.config.foregroundColor,
        elevation: 0,
        actions: _buildAppBarActions(),
      ),
      backgroundColor: widget.config.backgroundColor,
      body: Column(
        children: [
          // 扫描器区域
          Expanded(
            flex: widget.config.showScanHistory ? 3 : 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: _buildScannerView(),
              ),
            ),
          ),
          // 扫码历史区域（如果启用）
          if (widget.config.showScanHistory) _buildScanHistorySection(),
          // 底部操作区域
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: _buildBottomContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AppBar操作按钮
  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];

    if (widget.config.enableFlashlight) {
      actions.add(
        IconButton(
          color: widget.config.foregroundColor,
          icon: const Icon(Icons.flash_on),
          iconSize: 32.0,
          onPressed: () => _cameraController.toggleTorch(),
        ),
      );
    }

    if (widget.config.enableCameraSwitch) {
      actions.add(
        IconButton(
          color: widget.config.foregroundColor,
          icon: const Icon(Icons.flip_camera_ios),
          iconSize: 32.0,
          onPressed: () => _cameraController.switchCamera(),
        ),
      );
    }

    if (widget.config.additionalActions != null) {
      actions.addAll(widget.config.additionalActions!);
    }

    return actions;
  }

  /// 构建扫描器视图
  Widget _buildScannerView() {
    if (kIsWeb || const bool.fromEnvironment('flutter.test')) {
      return Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Text(
            '相机预览\n(测试模式)',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return MobileScanner(
      controller: _cameraController,
      onDetect: (capture) {
        if (!_isScanning) return;
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final String? code = barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            setState(() {
              _isScanning = false;
            });
            _handleBarcodeScanned(code);

            // 连续扫码模式下，延迟后重新启用扫码
            if (widget.config.continuousMode) {
              Future.delayed(
                Duration(milliseconds: widget.config.continuousDelay ?? 1000),
                () {
                  if (mounted) {
                    setState(() {
                      _isScanning = true;
                    });
                  }
                },
              );
            }
          }
        }
      },
    );
  }

  /// 构建底部内容
  Widget _buildBottomContent() {
    if (widget.isLoading) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.config.subtitle,
          style: TextStyle(
            color: widget.config.foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  /// 构建默认加载Widget
  Widget _buildDefaultLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: widget.config.foregroundColor),
        const SizedBox(height: 16),
        Text(
          '正在处理中...',
          style: TextStyle(color: widget.config.foregroundColor, fontSize: 16),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    if (widget.config.enableManualInput) {
      buttons.add(
        _buildActionButton(
          icon: Icons.keyboard,
          label: '手动输入',
          onPressed: _showManualInputDialog,
        ),
      );
    }

    if (widget.config.enableGalleryPicker) {
      buttons.add(
        _buildActionButton(
          icon: Icons.photo_library,
          label: '从相册选择',
          onPressed: _pickFromGallery,
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Flexible(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.config.foregroundColor?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: widget.config.foregroundColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: widget.config.foregroundColor,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示手动输入对话框
  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();

    // 定义确定按钮的点击逻辑，方便复用
    void onConfirm() {
      final code = controller.text.trim();
      if (code.isNotEmpty) {
        Navigator.of(context).pop();
        _handleBarcodeScanned(code);

        // 连续扫码模式下，延迟后重新启用扫码
        if (widget.config.continuousMode) {
          Future.delayed(
            Duration(milliseconds: widget.config.continuousDelay ?? 1000),
            () {
              if (mounted) {
                setState(() {
                  _isScanning = true;
                });
              }
            },
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('手动输入条码'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: '条码',
              hintText: '请输入条码',
              border: OutlineInputBorder(),
            ),
            // 添加回车键监听
            onSubmitted: (value) => onConfirm(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 从相册选择（占位符功能）
  void _pickFromGallery() {
    final error = '该功能暂不可用，请使用相机扫描';
    if (widget.onScanError != null) {
      widget.onScanError!(error);
    } else {
      showAppSnackBar(context, message: '该功能暂不可用，请使用相机扫描', isError: true);
    }
  }

  /// 重置扫描状态
  void resetScanningState() {
    if (mounted) {
      setState(() {
        _isScanning = true;
      });
    }
  }

  /// 手动启用/禁用扫码
  void setScanningEnabled(bool enabled) {
    if (mounted) {
      setState(() {
        _isScanning = enabled;
      });
    }
  }

  /// 处理扫码结果
  Future<void> _handleBarcodeScanned(String barcode) async {
    // 更新扫码总数
    setState(() {
      _totalScans++;
    });

    // 如果启用了历史记录，添加到历史
    if (widget.config.showScanHistory) {
      String? productName;
      
      // 尝试获取商品名称
      if (widget.getProductName != null) {
        try {
          productName = await widget.getProductName!(barcode);
        } catch (e) {
          if (kDebugMode) {
            print('获取商品名称失败: $e');
          }
        }
      }

      setState(() {
        // 添加到历史记录开头
        _scanHistory.insert(
          0,
          ScanHistoryItem(
            barcode: barcode,
            productName: productName,
            timestamp: DateTime.now(),
          ),
        );

        // 保持最大记录数限制
        if (_scanHistory.length > widget.config.maxHistoryItems) {
          _scanHistory.removeRange(
            widget.config.maxHistoryItems,
            _scanHistory.length,
          );
        }
      });
    }

    // 调用原始回调
    widget.onBarcodeScanned(barcode);
  }

  /// 构建扫码历史区域
  Widget _buildScanHistorySection() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: widget.config.foregroundColor?.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: widget.config.foregroundColor?.withValues(alpha: 0.2) ?? Colors.white24,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '扫码记录',
                  style: TextStyle(
                    color: widget.config.foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '总计: $_totalScans',
                  style: TextStyle(
                    color: widget.config.foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 历史记录列表
          Expanded(
            child: _scanHistory.isEmpty
                ? Center(
                    child: Text(
                      '暂无扫码记录',
                      style: TextStyle(
                        color: widget.config.foregroundColor?.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _scanHistory.length,
                    itemBuilder: (context, index) {
                      final item = _scanHistory[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: widget.config.foregroundColor?.withValues(alpha: 0.1) ?? Colors.white12,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // 序号
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.config.foregroundColor?.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: widget.config.foregroundColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 商品信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? '未知商品',
                                    style: TextStyle(
                                      color: widget.config.foregroundColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.barcode,
                                    style: TextStyle(
                                      color: widget.config.foregroundColor?.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
