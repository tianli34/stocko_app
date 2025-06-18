import 'package:flutter/material.dart';
import 'home_button.dart';

/// 页面包装器，为页面添加主页按钮
/// 这是一个可选的辅助组件，可以快速为页面添加主页按钮
class PageWithHomeButton extends StatelessWidget {
  /// 页面的主体内容
  final Widget child;

  /// 页面的AppBar
  final PreferredSizeWidget? appBar;

  /// 主页按钮的位置
  final HomeButtonPosition position;

  /// 主页按钮的样式
  final HomeButtonStyle buttonStyle;

  /// 是否显示主页按钮
  final bool showHomeButton;

  /// 浮动按钮（如果有的话）
  final Widget? floatingActionButton;

  /// 浮动按钮位置
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const PageWithHomeButton({
    super.key,
    required this.child,
    this.appBar,
    this.position = HomeButtonPosition.bottom,
    this.buttonStyle = HomeButtonStyle.bottom,
    this.showHomeButton = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (!showHomeButton) {
      return Scaffold(
        appBar: appBar,
        body: child,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    switch (position) {
      case HomeButtonPosition.bottom:
        return Scaffold(
          appBar: appBar,
          body: child,
          bottomNavigationBar: HomeButton(style: buttonStyle),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );

      case HomeButtonPosition.floating:
        return Scaffold(
          appBar: appBar,
          body: child,
          floatingActionButton: _buildFloatingButtons(context),
          floatingActionButtonLocation: floatingActionButtonLocation,
        );

      case HomeButtonPosition.embedded:
        return Scaffold(
          appBar: appBar,
          body: Column(
            children: [
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.all(16),
                child: HomeButton(style: buttonStyle, width: double.infinity),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
    }
  }

  Widget _buildFloatingButtons(BuildContext context) {
    if (floatingActionButton != null) {
      // 如果页面已有浮动按钮，创建一个按钮组
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HomeButton.floating(),
          const SizedBox(height: 16),
          floatingActionButton!,
        ],
      );
    } else {
      return const HomeButton.floating();
    }
  }
}

/// 主页按钮位置枚举
enum HomeButtonPosition {
  /// 底部固定位置
  bottom,

  /// 浮动位置
  floating,

  /// 嵌入页面内容中
  embedded,
}
