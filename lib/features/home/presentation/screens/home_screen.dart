import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/flavor_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../product/presentation/screens/unit_selection_screen.dart';
import '../../../product/presentation/screens/category_selection_screen.dart';
import '../../../product/presentation/screens/product_group_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Removed unused method _scanAndShowProductDialog - functionality may be implemented elsewhere

  // 隐私弹窗已由 AppInitializer 统一处理，这里不再重复处理。

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final flavorConfig = ref.watch(flavorConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('铺得清 - 首页')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '欢迎使用 铺得清 库存管理系统',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '请选择功能模块',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.products),
                    child: const Text('货品列表'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.productNew),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('新增货品'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.productRanking),
                    child: const Text('产品排行'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inventory),
                    child: const Text('库存管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inboundCreate),
                    child: const Text('新建入库单'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.purchase),
                    child: const Text('采购管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.sales),
                    child: const Text('销售管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.saleCreate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('收银台'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.customers),
                    child: const Text('客户管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showProductManagementDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('产品管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('设置'),
                  ),
                  if (flavorConfig.featureFlags[Feature.showDatabaseTools] == true) ...[
                    ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.databaseManagement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('数据库管理'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.databaseViewer),
                      child: const Text('数据库查看器'),
                    ),
                  ],
                  // ElevatedButton(
                  //   onPressed: () =>
                  //       context.push(AppRoutes.categoryTest),
                  //   child: const Text('类别管理测试'),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showProductManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('产品管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.straighten, color: Colors.blue),
              title: const Text('单位管理'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UnitSelectionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: const Text('类别管理'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategorySelectionScreen(isSelectionMode: false),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.green),
              title: const Text('商品组管理'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductGroupListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}