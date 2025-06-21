import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stocko_app/features/product/presentation/widgets/async_value_widget.dart';
import 'package:stocko_app/features/product/presentation/widgets/product_details_dialog.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product.dart';
import '../../../../core/shared_widgets/error_widget.dart';
import '../../../../core/shared_widgets/loading_widget.dart';
import '../widgets/product_list_tile.dart';
import '../../../../core/constants/app_routes.dart';

/// 产品列表页面
/// 展示如何使用 ProductListTile 组件
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);
    final controllerState = ref.watch(productControllerProvider);

    // 监听操作结果
    ref.listen<ProductControllerState>(productControllerProvider, (
      previous,
      next,
    ) {
      if (!context.mounted) return; // 在回调开始时检查

      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功'), backgroundColor: Colors.green),
        );
      } else if (next.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? '操作失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('产品列表'),
        // go_router会自动显示返回按钮并支持手势导航
        actions: [
          IconButton(
            onPressed: () {
              context.go(AppRoutes.productNew);
            },
            icon: const Icon(Icons.add),
            tooltip: '添加产品',
          ),
        ],
      ),
      body: Column(
        children: [
          controllerState.isLoading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(), // 使用 SizedBox.shrink() 代替 if
          // 产品列表
          Expanded(
            child: AsyncValueWidget<List<Product>>(
              value: productsAsyncValue,
              data: (products) => _buildProductList(context, ref, products),
              loading: const LoadingWidget(message: '加载产品列表中...'),
              error: (error, stackTrace) => CustomErrorWidget(
                message: '加载产品列表失败',
                onRetry: () => ref.invalidate(allProductsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建产品列表
  Widget _buildProductList(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) {
    if (products.isEmpty) {
      return const EmptyStateWidget(
        message: '暂无产品数据',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductListTile(
            product: product,
            onTap: () => _showProductDetails(context, product),
            onEdit: () => _editProduct(context, product),
            onDelete: () => _deleteProduct(context, ref, product),
          );
        },
      ),
    );
  }

  /// 显示产品详情
  void _showProductDetails(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(product: product),
    );
  }

  /// 编辑产品
  void _editProduct(BuildContext context, Product product) {
    context.go(AppRoutes.productEditPath(product.id));
  }

  /// 删除产品
  void _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    print('🖥️ UI层：开始删除产品 "${product.name}"，ID: ${product.id}');

    if (!context.mounted) return; // 在异步操作前检查
    // 显示确认对话框
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除产品 "${product.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    print('🖥️ UI层：用户确认结果: $shouldDelete');
    if (shouldDelete == true) {
      print('🖥️ UI层：开始执行删除操作...');
      final controller = ref.read(productControllerProvider.notifier);

      // 执行删除操作
      await controller.deleteProduct(product.id);

      print('🖥️ UI层：删除操作完成，开始刷新列表');
    } else {
      print('🖥️ UI层：删除操作被取消或产品ID为空');
    }
  }
}

/// 产品详情对话框

/// 产品网格列表（可选的展示方式）
class ProductGridPage extends ConsumerWidget {
  const ProductGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('产品网格')),
      body: AsyncValueWidget<List<Product>>(
        value: productsAsyncValue,
        data: (products) {
          // 如果产品列表为空，显示空状态
          if (products.isEmpty) {
            return const EmptyStateWidget(
              message: '暂无产品数据',
              icon: Icons.inventory_2_outlined,
            );
          }

          // 否则显示网格列表
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return SimpleProductListTile(
                product: product,
                onTap: () => context.go(AppRoutes.productEditPath(product.id)),
              );
            },
          );
        },
        loading: const LoadingWidget(message: '加载产品列表中...'),
        error: (error, stackTrace) => CustomErrorWidget(
          message: '加载产品列表失败',
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
      ),
    );
  }
}
