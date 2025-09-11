import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 一个带底部导航栏的通用 Scaffold，用于配合 GoRouter 的 StatefulShellRoute 使用。
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    // 切换分支；如果点击当前分支，则返回该分支的初始路由
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // 渐变方案（每个 Tab 一套）
  static const _homeGradient = LinearGradient(
    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
  );
  static const _productsGradient = LinearGradient(
    colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
  );
  static const _salesGradient = LinearGradient(
    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
  );
  static const _inventoryGradient = LinearGradient(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  );
  static const _settingsGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          indicatorColor: Colors.transparent, // 让选中态的渐变胶囊更清晰
          height: 64,
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: _GradientIcon(
                icon: Icons.dashboard_outlined,
                gradient: _homeGradient,
              ),
              selectedIcon: _GradientPillIcon(
                icon: Icons.dashboard_rounded,
                gradient: _homeGradient,
              ),
              label: '首页',
            ),
            NavigationDestination(
              icon: _GradientIcon(
                icon: Icons.inventory_2_outlined,
                gradient: _productsGradient,
              ),
              selectedIcon: _GradientPillIcon(
                icon: Icons.inventory_2_rounded,
                gradient: _productsGradient,
              ),
              label: '货品',
            ),
            NavigationDestination(
              icon: _GradientIcon(
                icon: Icons.shopping_bag_outlined,
                gradient: _salesGradient,
              ),
              selectedIcon: _GradientPillIcon(
                icon: Icons.shopping_bag_rounded,
                gradient: _salesGradient,
              ),
              label: '销售',
            ),
            NavigationDestination(
              icon: _GradientIcon(
                icon: Icons.warehouse_outlined,
                gradient: _inventoryGradient,
              ),
              selectedIcon: _GradientPillIcon(
                icon: Icons.warehouse_rounded,
                gradient: _inventoryGradient,
              ),
              label: '库存',
            ),
            NavigationDestination(
              icon: _GradientIcon(
                icon: Icons.tune_outlined,
                gradient: _settingsGradient,
              ),
              selectedIcon: _GradientPillIcon(
                icon: Icons.tune_rounded,
                gradient: _settingsGradient,
              ),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

// 未选中态：渐变着色图标
class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon, required this.gradient});
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
}

// 选中态：渐变胶囊背景 + 纯白图标
class _GradientPillIcon extends StatelessWidget {
  const _GradientPillIcon({required this.icon, required this.gradient});
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }
}
