import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_with_home_button.dart';
import '../../../core/widgets/home_button.dart';
import '../../../features/product/presentation/screens/product_list_screen.dart';

/// 使用页面包装器的产品列表页面示例
/// 展示如何快速为现有页面添加主页按钮
class ProductListWithHomeButtonExample extends ConsumerWidget {
  const ProductListWithHomeButtonExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageWithHomeButton(
      appBar: AppBar(
        title: const Text('产品列表（带主页按钮）'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
            tooltip: '添加产品',
          ),
        ],
      ),
      // 选择主页按钮的位置
      position: HomeButtonPosition.bottom,
      // 选择主页按钮的样式
      buttonStyle: HomeButtonStyle.bottom,
      // 页面主体内容
      child: const ProductListScreen(),
    );
  }
}

/// 使用嵌入式主页按钮的示例
class PageWithEmbeddedHomeButtonExample extends StatelessWidget {
  const PageWithEmbeddedHomeButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWithHomeButton(
      appBar: AppBar(title: const Text('嵌入式主页按钮示例')),
      position: HomeButtonPosition.embedded,
      buttonStyle: HomeButtonStyle.elevated,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('页面内容区域'),
            Text('主页按钮会嵌入在内容下方'),
          ],
        ),
      ),
    );
  }
}

/// 使用浮动主页按钮的示例
class PageWithFloatingHomeButtonExample extends StatelessWidget {
  const PageWithFloatingHomeButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWithHomeButton(
      appBar: AppBar(title: const Text('浮动主页按钮示例')),
      position: HomeButtonPosition.floating,
      // 如果页面已有浮动按钮，会自动组合
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('这是页面的功能按钮')));
        },
        child: const Icon(Icons.add),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flutter_dash, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('页面内容区域'),
            Text('主页按钮会浮动显示'),
          ],
        ),
      ),
    );
  }
}
