import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

/// 主页按钮组件
/// 提供返回主页的快捷方式
class HomeButton extends StatelessWidget {
  /// 按钮样式
  final HomeButtonStyle style;

  /// 是否显示图标
  final bool showIcon;

  /// 是否显示文字
  final bool showLabel;

  /// 自定义文字
  final String? customLabel;

  /// 按钮宽度
  final double? width;

  /// 外边距
  final EdgeInsets? margin;

  const HomeButton({
    super.key,
    this.style = HomeButtonStyle.elevated,
    this.showIcon = true,
    this.showLabel = true,
    this.customLabel,
    this.width,
    this.margin,
  });

  /// 创建浮动样式的主页按钮
  const HomeButton.floating({
    super.key,
    this.showIcon = true,
    this.showLabel = false,
    this.customLabel,
    this.width,
    this.margin,
  }) : style = HomeButtonStyle.floating;

  /// 创建底部固定样式的主页按钮
  const HomeButton.bottom({
    super.key,
    this.showIcon = true,
    this.showLabel = true,
    this.customLabel,
    this.width,
    this.margin,
  }) : style = HomeButtonStyle.bottom;

  /// 创建紧凑样式的主页按钮
  const HomeButton.compact({
    super.key,
    this.showIcon = true,
    this.showLabel = false,
    this.customLabel,
    this.width,
    this.margin,
  }) : style = HomeButtonStyle.compact;

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: width,
      margin: margin,
      child: _buildButton(context),
    );

    return widget;
  }

  Widget _buildButton(BuildContext context) {
    final label = customLabel ?? '返回主页';

    switch (style) {
      case HomeButtonStyle.elevated:
        return _buildElevatedButton(context, label);
      case HomeButtonStyle.floating:
        return _buildFloatingButton(context, label);
      case HomeButtonStyle.bottom:
        return _buildBottomButton(context, label);
      case HomeButtonStyle.compact:
        return _buildCompactButton(context, label);
    }
  }

  Widget _buildElevatedButton(BuildContext context, String label) {
    if (showIcon && showLabel) {
      return ElevatedButton.icon(
        onPressed: () => _navigateToHome(context),
        icon: const Icon(Icons.home),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    } else if (showIcon) {
      return ElevatedButton(
        onPressed: () => _navigateToHome(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.home),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _navigateToHome(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(label),
      );
    }
  }

  Widget _buildFloatingButton(BuildContext context, String label) {
    return FloatingActionButton(
      onPressed: () => _navigateToHome(context),
      tooltip: label,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(Icons.home),
    );
  }

  Widget _buildBottomButton(BuildContext context, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _navigateToHome(context),
          icon: showIcon ? const Icon(Icons.home) : const SizedBox.shrink(),
          label: showLabel ? Text(label) : const SizedBox.shrink(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton(BuildContext context, String label) {
    return OutlinedButton.icon(
      onPressed: () => _navigateToHome(context),
      icon: showIcon
          ? const Icon(Icons.home, size: 18)
          : const SizedBox.shrink(),
      label: showLabel
          ? Text(label, style: const TextStyle(fontSize: 14))
          : const SizedBox.shrink(),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        side: BorderSide(color: Theme.of(context).primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // 检查当前是否已经在主页
    final currentLocation = GoRouterState.of(context).uri.toString();
    if (currentLocation == AppRoutes.home) {
      // 如果已经在主页，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前已在主页'), duration: Duration(seconds: 1)),
      );
      return;
    }

    // 导航到主页
    context.go(AppRoutes.home);
  }
}

/// 主页按钮样式枚举
enum HomeButtonStyle {
  /// 标准的ElevatedButton样式
  elevated,

  /// 浮动按钮样式
  floating,

  /// 底部固定样式
  bottom,

  /// 紧凑样式
  compact,
}
