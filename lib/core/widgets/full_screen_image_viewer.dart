import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全屏图片查看器
/// 支持缩放、平移、旋转等功能
class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.heroTag,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 监听缩放变化
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if (scale != _currentScale) {
        setState(() {
          _currentScale = scale;
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _resetZoom,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要的图片查看区域
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: true,
              scaleEnabled: true,
              onInteractionStart: (_) {
                // 开始交互时隐藏状态栏
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
              },
              onInteractionEnd: (_) {
                // 结束交互后显示状态栏
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                  }
                });
              },
              child: _buildImageContent(),
            ),
          ),

          // 底部控制栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 40,
                top: 20,
              ),
              child: _buildBottomControls(),
            ),
          ),

          // 缩放级别指示器
          if (_currentScale != 1.0)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(_currentScale * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    Widget imageWidget;

    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: _buildImage());
    } else {
      imageWidget = _buildImage();
    }

    return imageWidget;
  }

  Widget _buildImage() {
    return Image.file(
      File(widget.imagePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 60, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text(
                '图片加载失败',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.zoom_out,
          label: '缩小',
          onPressed: _zoomOut,
        ),
        _buildControlButton(
          icon: Icons.zoom_in,
          label: '放大',
          onPressed: _zoomIn,
        ),
        _buildControlButton(
          icon: Icons.fit_screen,
          label: '适应屏幕',
          onPressed: _fitToScreen,
        ),
        _buildControlButton(
          icon: Icons.refresh,
          label: '重置',
          onPressed: _resetZoom,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    final double newScale = (_currentScale * 1.5).clamp(_minScale, _maxScale);
    _animateToScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentScale / 1.5).clamp(_minScale, _maxScale);
    _animateToScale(newScale);
  }

  void _fitToScreen() {
    _animateToScale(1.0);
  }

  void _resetZoom() {
    _animateToTransform(Matrix4.identity());
  }

  void _animateToScale(double scale) {
    final Matrix4 newMatrix = Matrix4.identity()..scale(scale);
    _animateToTransform(newMatrix);
  }

  void _animateToTransform(Matrix4 transform) {
    _animation?.removeListener(_onAnimationUpdate);
    _animationController.reset();

    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: transform,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animation!.addListener(_onAnimationUpdate);
    _animationController.forward();
  }

  void _onAnimationUpdate() {
    _transformationController.value = _animation!.value;
  }
}
