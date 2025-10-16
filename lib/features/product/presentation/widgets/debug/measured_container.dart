import 'package:flutter/material.dart';

/// 可测量高度的容器组件（用于调试）
/// 在红色边框的右上角显示容器内容的高度
class MeasuredContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? label; // 可选标签，用于区分不同的容器

  const MeasuredContainer({
    super.key,
    required this.child,
    this.padding,
    this.label,
  });

  @override
  State<MeasuredContainer> createState() => _MeasuredContainerState();
}

class _MeasuredContainerState extends State<MeasuredContainer> {
  final GlobalKey _containerKey = GlobalKey();
  double? _height;

  @override
  void initState() {
    super.initState();
    // 在首帧渲染后测量高度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeight();
    });
  }

  void _measureHeight() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _height = renderBox.size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: _containerKey,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: widget.child,
        ),
        // 显示高度标签
        if (_height != null)
          Positioned(
            top: -10,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.label != null
                    ? '${widget.label}: ${_height!.toStringAsFixed(1)}px'
                    : '${_height!.toStringAsFixed(1)}px',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
