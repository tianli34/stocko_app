import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:stocko_app/core/utils/snackbar_helper.dart';

/// 扫码结果回调类型定义
typedef OnBarcodeScanned = void Function(String barcode);
typedef OnScanError = void Function(String error);
typedef GetProductInfo = Future<({String? name, String? unitName, int? conversionRate})?> Function(String barcode);

/// 扫码历史记录项
class ScanHistoryItem {
  final int sequenceNumber; // 扫描序号
  final String barcode;
  final String? productName;
  final String? unitName; // 单位名称
  final int? conversionRate; // 换算率，1表示基本单位
  final DateTime timestamp;

  ScanHistoryItem({
    required this.sequenceNumber,
    required this.barcode,
    this.productName,
    this.unitName,
    this.conversionRate,
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
    this.maxHistoryItems = 20, // 默认显示最近20条
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
  final GetProductInfo? getProductInfo; // 获取商品信息的回调（包括名称和单位）
  final Widget? loadingWidget;
  final bool isLoading;

  const UniversalBarcodeScanner({
    super.key,
    required this.config,
    required this.onBarcodeScanned,
    this.onScanError,
    this.getProductInfo,
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
  String? _lastScannedBarcode; // 上一次扫描的条码，用于去重

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
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: _buildScannerView(),
              ),
            ),
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 相机扫描器
            MobileScanner(
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
            ),
            // 扫码历史信息叠加层（右侧三分之一区域）
            if (widget.config.showScanHistory)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: constraints.maxWidth / 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      stops: const [0.0, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
              child: Column(
                children: [
                  // 顶部统计信息（已扫与数量同行）
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '已扫',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalScans',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 历史记录列表（精简版，从上至下按序号从小到大排列）
                  Expanded(
                    child: _scanHistory.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _scanHistory.length.clamp(0, 20),
                              itemBuilder: (context, index) {
                                // _scanHistory[0] 是最新的（序号最大）
                                // 需要反向访问，使序号小的在上面
                                final reversedIndex = _scanHistory.length - 1 - index;
                                final item = _scanHistory[reversedIndex];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${item.sequenceNumber}.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: item.productName ?? '未知',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (item.unitName != null) ...[
                                                const TextSpan(
                                                  text: ' ',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: item.unitName,
                                                  style: TextStyle(
                                                    color: (item.conversionRate != null && item.conversionRate! > 1)
                                                        ? Colors.yellow // 非基本单位用黄色突出显示
                                                        : Colors.white.withValues(alpha: 0.7),
                                                    fontSize: 10,
                                                    fontWeight: (item.conversionRate != null && item.conversionRate! > 1)
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // 完成按钮（底部）
                  if (widget.config.continuousMode)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '完成',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
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
                  color: widget.config.foregroundColor?.withValues(alpha: 0.2),
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
    // 连续扫码模式下的去重：如果条码与上一个相同，则忽略
    if (widget.config.continuousMode && barcode == _lastScannedBarcode) {
      if (kDebugMode) {
        print('去重：忽略重复条码 $barcode');
      }
      return;
    }

    // 更新上一次扫描的条码
    _lastScannedBarcode = barcode;

    // 更新扫码总数
    final currentScanNumber = _totalScans + 1;
    setState(() {
      _totalScans = currentScanNumber;
    });

    // 如果启用了历史记录，添加到历史
    if (widget.config.showScanHistory) {
      String? productName;
      String? unitName;
      int? conversionRate;
      
      // 尝试获取商品信息（名称和单位）
      if (widget.getProductInfo != null) {
        try {
          final info = await widget.getProductInfo!(barcode);
          if (info != null) {
            productName = info.name;
            unitName = info.unitName;
            conversionRate = info.conversionRate;
          }
        } catch (e) {
          if (kDebugMode) {
            print('获取商品信息失败: $e');
          }
        }
      }

      setState(() {
        // 添加到历史记录开头
        _scanHistory.insert(
          0,
          ScanHistoryItem(
            sequenceNumber: currentScanNumber, // 使用绝对序号
            barcode: barcode,
            productName: productName,
            unitName: unitName,
            conversionRate: conversionRate,
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


}
