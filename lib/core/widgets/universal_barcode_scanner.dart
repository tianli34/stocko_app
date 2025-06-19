import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    _cameraController.dispose();
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: _buildBottomContent(),
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
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.config.foregroundColor?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: widget.config.foregroundColor),
              iconSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: widget.config.foregroundColor,
              fontSize: 12,
            ),
          ),
        ],
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
    if (widget.config.enableScanSound) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (e) {
        // 在某些平台上可能不支持，忽略错误
        if (kDebugMode) {
          print('播放提示音失败: $e');
        }
      }
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
}
