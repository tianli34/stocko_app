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
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '欢迎使用 Stocko 库存管理系统',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                const Text('请选择功能模块', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.products),
                  child: const Text('产品管理'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.categories),
                  child: const Text('类别管理'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.inventory),
                  child: const Text('库存管理'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.sales),
                  child: const Text('销售管理'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.test),
                  child: const Text('数据库测试'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.categoryTest),
                  child: const Text('类别管理测试'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
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
          // 新增商品页面
          GoRoute(
            path: 'new',
            name: 'product-new',
            builder: (context, state) => const ProductAddEditScreen(),
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
                const Placeholder(child: Text('库存管理页面')),
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
