import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_routes.dart';
import '../../features/test/test_page.dart';
import '../../features/product/presentation/screens/product_list_screen.dart';
import '../../features/product/presentation/screens/product_add_edit_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/product/presentation/screens/category_selection_screen.dart';
import '../../features/product/presentation/pages/category_test_page.dart';
import '../../features/product/application/provider/product_providers.dart';
import '../../features/database/presentation/screens/database_viewer_screen.dart';
import '../../features/debug/screens/database_management_screen.dart';
import '../../features/inbound/presentation/screens/screens.dart';
import '../../features/inventory/presentation/screens/screens.dart';
import '../../features/purchase/presentation/screens/screens.dart';

// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Stocko - 首页')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '欢迎使用 Stocko 库存管理系统',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('请选择功能模块', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.products),
                        child: const Text('产品管理'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.categories),
                        child: const Text('类别管理'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.inventory),
                        child: const Text('库存管理'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.inboundCreate),
                        child: const Text('新建入库单'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.purchase),
                        child: const Text('采购管理'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.sales),
                        child: const Text('销售管理'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.test),
                        child: const Text('数据库测试'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.categoryTest),
                        child: const Text('类别管理测试'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.databaseViewer),
                        child: const Text('数据库查看器'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push(AppRoutes.databaseManagement),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('数据库管理'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          // 新增商品页面 - 必须放在 :id 路由之前
          GoRoute(
            path: 'new',
            name: 'product-new',
            builder: (context, state) => const ProductAddEditScreen(),
          ),
          // 商品详情页面
          GoRoute(
            path: ':id',
            name: 'product-detail',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return ProductDetailScreen(productId: productId);
            },
            routes: [
              // 商品编辑页面
              GoRoute(
                path: 'edit',
                name: 'product-edit',
                builder: (context, state) {
                  final productId = state.pathParameters['id']!;
                  // 需要获取商品数据以传递给编辑页面
                  return Consumer(
                    builder: (context, ref, child) {
                      final productsAsyncValue = ref.watch(allProductsProvider);
                      return productsAsyncValue.when(
                        data: (products) {
                          final product = products
                              .where((p) => p.id == productId)
                              .firstOrNull;
                          return ProductAddEditScreen(product: product);
                        },
                        loading: () => const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => Scaffold(
                          appBar: AppBar(title: const Text('错误')),
                          body: Center(child: Text('加载商品失败: $error')),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        builder: (context, state) =>
            const CategorySelectionScreen(isSelectionMode: false),
        routes: [
          GoRoute(
            path: 'test',
            name: 'category-test',
            builder: (context, state) => const CategoryTestPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.inventory,
        name: 'inventory',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('库存管理')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '库存管理功能',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.inboundCreate),
                    child: const Text('新建入库单'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push(AppRoutes.inventoryInboundRecords),
                    child: const Text('入库记录'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inventoryQuery),
                    child: const Text('库存查询'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.inboundCreate,
        name: 'inbound-create',
        builder: (context, state) => const CreateInboundScreen(),
      ),
      GoRoute(
        path: AppRoutes.purchase,
        name: 'purchase',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('采购管理')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('采购管理功能', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.purchaseCreate),
                    child: const Text('新建采购单'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.purchaseRecords),
                    child: const Text('采购记录'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.purchaseCreate,
        name: 'purchase-create',
        builder: (context, state) => const CreatePurchaseScreen(),
      ),
      GoRoute(
        path: AppRoutes.purchaseRecords,
        name: 'purchase-records',
        builder: (context, state) => const PurchaseRecordsScreen(),
      ),
      GoRoute(
        path: AppRoutes.purchaseDetail,
        name: 'purchase-detail',
        builder: (context, state) {
          final purchaseNumber = state.pathParameters['purchaseNumber']!;
          return PurchaseDetailScreen(purchaseNumber: purchaseNumber);
        },
      ),
      GoRoute(
        path: AppRoutes.inventoryQuery,
        name: 'inventory-query',
        builder: (context, state) => const InventoryQueryScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryInboundRecords,
        name: 'inventory-inbound-records',
        builder: (context, state) => const InboundRecordsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sales,
        name: 'sales',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('销售管理')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Placeholder(child: Text('销售管理页面')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.test,
        name: 'test',
        builder: (context, state) => const TestPage(),
      ),
      GoRoute(
        path: AppRoutes.databaseViewer,
        name: 'database-viewer',
        builder: (context, state) => const DatabaseViewerScreen(),
      ),
      GoRoute(
        path: AppRoutes.databaseManagement,
        name: 'database-management',
        builder: (context, state) => const DatabaseManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('错误: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
