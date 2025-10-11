import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/scan_product_service.dart';

/// 一个带底部导航栏的通用 Scaffold，用于配合 GoRouter 的 StatefulShellRoute 使用。
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(BuildContext context, int index) {
    // 跳过中间的占位符（index 2）
    if (index == 2) return;

    // 调整索引：index 3, 4 对应实际的分支 2, 3
    final branchIndex = index > 2 ? index - 1 : index;

    // 切换分支；如果点击当前分支，则返回该分支的初始路由
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
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
  static const _fabGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          NavigationBarTheme(
            data: const NavigationBarThemeData(
              indicatorColor: Colors.transparent,
              height: 64,
            ),
            child: NavigationBar(
              // 调整选中索引：分支 2, 3 对应显示索引 3, 4
              selectedIndex: navigationShell.currentIndex >= 2
                  ? navigationShell.currentIndex + 1
                  : navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
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
                // 占位符，为 FAB 留出空间
                NavigationDestination(icon: SizedBox(width: 64), label: ''),
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
              ],
            ),
          ),
          // 将 FAB 精确定位到导航栏，底部对齐
          Positioned(
            left: 0,
            right: 0,
            bottom: 16, // 底部对齐，与导航图标底部在同一水平线
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _fabGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => ScanProductService.scanAndShowProductDialog(
                      context,
                      ref,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
