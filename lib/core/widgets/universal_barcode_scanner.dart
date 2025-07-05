import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

/// 扫码结果回调类型定义
typedef OnBarcodeScanned = void Function(String barcode);
typedef OnScanError = void Function(String error);

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
  final Widget? loadingWidget;
  final bool isLoading;

  const UniversalBarcodeScanner({
    super.key,
    required this.config,
    required this.onBarcodeScanned,
    this.onScanError,
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
            _playSuccessSound();
            widget.onBarcodeScanned(code);

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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(context).pop();
                  widget.onBarcodeScanned(code);

                  // 连续扫码模式下，延迟后重新启用扫码
                  if (widget.config.continuousMode) {
                    Future.delayed(
                      Duration(
                        milliseconds: widget.config.continuousDelay ?? 1000,
                      ),
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
              },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该功能暂不可用，请使用相机扫描'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 播放扫码成功提示音
  void _playSuccessSound() {
    if (!widget.config.enableScanSound) {
      if (kDebugMode) {
        print('扫码声音被禁用 (enableScanSound = false)');
      }
      return;
    }

    if (kDebugMode) {
      print('开始播放扫码成功音效...');
    }

    // 首先尝试播放音频文件
    _playAudioFile()
        .catchError((e) {
          if (kDebugMode) {
            print('播放音频文件失败: $e');
          }
          // 如果音频文件播放失败，回退到系统声音
          return _playSystemSound();
        })
        .catchError((systemError) {
          if (kDebugMode) {
            print('播放系统声音也失败: $systemError');
          }
        });
  }

  /// 播放音频文件
  Future<void> _playAudioFile() async {
    try {
      // 停止之前的播放
      await _audioPlayer.stop();

      // 播放扫码成功音效
      await _audioPlayer.play(AssetSource('sounds/scan_success2.mp3'));

      if (kDebugMode) {
        print('✓ 成功播放扫码音效: sounds/scan_success2.mp3');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 播放音频文件异常: $e');
      }
      rethrow;
    }
  }

  /// 播放系统声音作为回退
  Future<void> _playSystemSound() async {
    try {
      SystemSound.play(SystemSoundType.click);
      if (kDebugMode) {
        print('✓ 播放系统声音作为回退');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 播放系统声音失败: $e');
      }
      rethrow;
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
}
