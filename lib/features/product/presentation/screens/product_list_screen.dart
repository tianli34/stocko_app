import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product.dart';
import '../../../../core/shared_widgets/error_widget.dart';
import '../../../../core/shared_widgets/loading_widget.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/product_list_tile.dart';
import 'product_add_edit_screen.dart';

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
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.home),
          tooltip: '返回主页',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductAddEditScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: '添加产品',
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作状态指示器
          if (controllerState.isLoading) const LinearProgressIndicator(),

          // 产品列表
          Expanded(
            child: productsAsyncValue.when(
              data: (products) => _buildProductList(context, ref, products),
              loading: () => const LoadingWidget(message: '加载产品列表中...'),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductAddEditScreen(product: product),
      ),
    );
  }

  /// 删除产品
  void _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    print('🖥️ UI层：开始删除产品 "${product.name}"，ID: ${product.id}');

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

      // 强制刷新列表确保UI立即更新
      ref.invalidate(allProductsProvider);

      // 添加短暂延迟后再次刷新，确保数据完全同步
      await Future.delayed(const Duration(milliseconds: 150));
      print('🖥️ UI层：延迟后再次刷新列表');
      ref.invalidate(allProductsProvider);

      print('🖥️ UI层：删除流程完成');
    } else {
      print('🖥️ UI层：删除操作被取消或产品ID为空');
    }
  }
}

/// 产品详情对话框
class ProductDetailsDialog extends StatelessWidget {
  final Product product;

  const ProductDetailsDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 产品详情
            _buildDetailItem(context, '状态', product.isActive ? '启用' : '禁用'),

            if (product.sku != null)
              _buildDetailItem(context, 'SKU', product.sku!),

            if (product.barcode != null)
              _buildDetailItem(context, '条码', product.barcode!),

            if (product.brand != null)
              _buildDetailItem(context, '品牌', product.brand!),

            if (product.specification != null)
              _buildDetailItem(context, '规格', product.specification!),

            if (product.effectivePrice != null)
              _buildDetailItem(
                context,
                '价格',
                '￥${product.effectivePrice!.toStringAsFixed(2)}',
              ),

            if (product.stockWarningValue != null)
              _buildDetailItem(
                context,
                '库存预警值',
                '${product.stockWarningValue}',
              ),

            if (product.shelfLife != null)
              _buildDetailItem(context, '保质期', '${product.shelfLife}天'),

            if (product.ownership != null)
              _buildDetailItem(context, '归属', product.ownership!),

            if (product.remarks != null)
              _buildDetailItem(context, '备注', product.remarks!),

            if (product.lastUpdated != null)
              _buildDetailItem(
                context,
                '最后更新',
                _formatDateTime(product.lastUpdated!),
              ),

            const SizedBox(height: 24),

            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 产品网格列表（可选的展示方式）
class ProductGridPage extends ConsumerWidget {
  const ProductGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('产品网格')),
      body: productsAsyncValue.when(
        data: (products) => products.isEmpty
            ? const EmptyStateWidget(
                message: '暂无产品数据',
                icon: Icons.inventory_2_outlined,
              )
            : GridView.builder(
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductAddEditScreen(product: product),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(message: '加载产品列表中...'),
        error: (error, stackTrace) => CustomErrorWidget(
          message: '加载产品列表失败',
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
      ),
    );
  }
}
