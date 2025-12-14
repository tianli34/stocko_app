import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_routes.dart';
import '../widgets/scaffold_with_nav_bar.dart';
import '../widgets/privacy_policy_checker.dart';
import '../../features/product/presentation/screens/product_list_screen.dart';
import '../../features/product/presentation/screens/product_add_edit_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/product/presentation/screens/product_ranking_screen.dart';
import '../../features/product/presentation/screens/product_group_list_screen.dart';
import '../../features/product/presentation/screens/category_selection_screen.dart';
import '../../features/product/application/provider/product_providers.dart';
import '../../features/database/presentation/screens/database_viewer_screen.dart';
import '../../features/debug/screens/database_management_screen.dart';
import '../../features/inbound/presentation/screens/screens.dart';
import '../../features/inventory/presentation/screens/screens.dart';
import '../../features/sale/presentation/screens/create_sale_screen.dart';
import '../../features/sale/presentation/screens/sales_records_screen.dart';
import '../../features/purchase/presentation/screens/purchase_records_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/terms_of_service_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/sale/presentation/screens/customer_selection_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../core/models/scanned_product_payload.dart';
import '../../debug/product_restore_debug_page.dart';
import '../../features/outbound/presentation/screens/non_sale_outbound_screen.dart';
import '../../features/stocktake/presentation/screens/stocktake_list_screen.dart';
import '../../features/stocktake/presentation/screens/create_stocktake_screen.dart';
import '../../features/stocktake/presentation/screens/stocktake_entry_screen.dart';
import '../../features/stocktake/presentation/screens/stocktake_diff_screen.dart';
import '../../features/stocktake/presentation/screens/stocktake_detail_screen.dart';
import '../../features/sale/presentation/screens/sales_return_list_screen.dart';
import '../../features/sale/presentation/screens/create_sales_return_screen.dart';

// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // 底部导航栏承载的 4 个主分支
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PrivacyPolicyChecker(
          child: ScaffoldWithNavBar(navigationShell: navigationShell),
        ),
        branches: [
          // 首页
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // 货品
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                name: 'products',
                builder: (context, state) => const ProductListScreen(),
                routes: [
                  GoRoute(
                    path: 'ranking',
                    name: 'product-ranking',
                    builder: (context, state) => const ProductRankingScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'product-detail',
                    builder: (context, state) {
                      final productId = int.parse(state.pathParameters['id']!);
                      return ProductDetailScreen(productId: productId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 销售
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sales,
                name: 'sales',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('销售管理')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '销售管理功能',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.saleCreate),
                            child: const Text('新建销售单'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.push(AppRoutes.saleRecords),
                            child: const Text('销售记录'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.push(AppRoutes.saleReturns),
                            child: const Text('退货记录'),
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
                routes: [
                  GoRoute(
                    path: 'records',
                    name: 'sale-records',
                    builder: (context, state) => const SalesRecordsScreen(),
                  ),
                  GoRoute(
                    path: 'returns',
                    name: 'sale-returns',
                    builder: (context, state) => const SalesReturnListScreen(),
                  ),
                  GoRoute(
                    path: 'return/create',
                    name: 'sale-return-create',
                    builder: (context, state) {
                      final transactionId = int.parse(state.uri.queryParameters['transactionId'] ?? '0');
                      final shopId = int.parse(state.uri.queryParameters['shopId'] ?? '0');
                      return CreateSalesReturnScreen(
                        salesTransactionId: transactionId,
                        shopId: shopId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 库存
          StatefulShellBranch(
            routes: [
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.go(AppRoutes.inboundCreate),
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
                            onPressed: () => context.push('/inventory-query'),
                            child: const Text('库存查询'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.stocktakeList),
                            child: const Text('库存盘点'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => context.push('/inventory/purchase'),
                            child: const Text('采购管理'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.nonSaleOutbound),
                            child: const Text('非售出库'),
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
                routes: [
                  GoRoute(
                    path: 'inbound-records',
                    name: 'inventory-inbound-records',
                    builder: (context, state) {
                      final showOutbound = state.uri.queryParameters['showOutbound'] == 'true';
                      return InventoryRecordsScreen(showOutbound: showOutbound);
                    },
                  ),
                  GoRoute(
                    path: 'purchase-records',
                    name: 'inventory-purchase-records',
                    builder: (context, state) => const PurchaseRecordsScreen(),
                  ),
                  GoRoute(
                    path: 'purchase',
                    name: 'purchase',
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('采购管理')),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '采购管理功能',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () => context.push(AppRoutes.inventoryPurchaseRecords),
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
                ],
              ),
            ],
          ),
        ],
      ),

      // 其余（不在底部导航中的）功能路由
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'user-agreement',
            name: 'user-agreement',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          GoRoute(
            path: 'privacy-policy',
            name: 'privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/product/new',
        name: 'product-new',
        builder: (context, state) {
          final barcode = state.extra is String ? state.extra as String : null;
          return ProductAddEditScreen(initialBarcode: barcode);
        },
      ),
      GoRoute(
        path: '/product/:id/edit',
        name: 'product-edit',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
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
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        builder: (context, state) =>
            const CategorySelectionScreen(isSelectionMode: false),
        routes: [],
      ),
      GoRoute(
        path: AppRoutes.productGroups,
        name: 'product-groups',
        builder: (context, state) => const ProductGroupListScreen(),
      ),
      GoRoute(
        path: AppRoutes.inboundCreate,
        name: 'inbound-create',
        builder: (context, state) {
          final payload = state.extra is ScannedProductPayload
              ? state.extra as ScannedProductPayload
              : null;
          return CreateInboundScreen(payload: payload);
        },
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
      GoRoute(
        path: AppRoutes.customers,
        name: 'customers',
        builder: (context, state) => const CustomerSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.saleCreate,
        name: 'sale-create',
        builder: (context, state) {
          final payload = state.extra is ScannedProductPayload
              ? state.extra as ScannedProductPayload
              : null;
          return CreateSaleScreen(payload: payload);
        },
      ),
      GoRoute(
        path: AppRoutes.inventoryQuery,
        name: 'inventory-query',
        builder: (context, state) => const InventoryQueryScreen(),
      ),
      GoRoute(
        path: AppRoutes.productRestoreDebug,
        name: 'product-restore-debug',
        builder: (context, state) => const ProductRestoreDebugPage(),
      ),
      GoRoute(
        path: AppRoutes.nonSaleOutbound,
        name: 'non-sale-outbound',
        builder: (context, state) => const NonSaleOutboundScreen(),
      ),
      // 盘点相关路由
      GoRoute(
        path: AppRoutes.stocktakeList,
        name: 'stocktake-list',
        builder: (context, state) => const StocktakeListScreen(),
      ),
      GoRoute(
        path: AppRoutes.stocktakeCreate,
        name: 'stocktake-create',
        builder: (context, state) => const CreateStocktakeScreen(),
      ),
      GoRoute(
        path: '/stocktake/:id/entry',
        name: 'stocktake-entry',
        builder: (context, state) {
          final stocktakeId = int.parse(state.pathParameters['id']!);
          return StocktakeEntryScreen(stocktakeId: stocktakeId);
        },
      ),
      GoRoute(
        path: '/stocktake/:id/diff',
        name: 'stocktake-diff',
        builder: (context, state) {
          final stocktakeId = int.parse(state.pathParameters['id']!);
          return StocktakeDiffScreen(stocktakeId: stocktakeId);
        },
      ),
      GoRoute(
        path: '/stocktake/:id',
        name: 'stocktake-detail',
        builder: (context, state) {
          final stocktakeId = int.parse(state.pathParameters['id']!);
          return StocktakeDetailScreen(stocktakeId: stocktakeId);
        },
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
