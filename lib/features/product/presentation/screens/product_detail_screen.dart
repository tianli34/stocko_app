import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/shared_widgets/loading_widget.dart';
import '../../../../core/shared_widgets/error_widget.dart';

/// 商品详情页面
class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        actions: [
          // 编辑按钮
          IconButton(
            onPressed: () {
              context.go(AppRoutes.productEditPath(productId));
            },
            icon: const Icon(Icons.edit),
            tooltip: '编辑商品',
          ),
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) {
          final product = products.where((p) => p.id == productId).firstOrNull;
          if (product == null) {
            return const Center(child: Text('商品不存在或已被删除'));
          }
          return _buildProductDetail(context, ref, product);
        },
        loading: () => const LoadingWidget(message: '加载商品详情中...'),
        error: (error, stackTrace) => CustomErrorWidget(
          message: '加载商品详情失败',
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
      ),
    );
  }

  Widget _buildProductDetail(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: product.isActive
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          product.isActive ? '启用' : '禁用',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 基本信息
                  if (product.sku != null)
                    _buildDetailItem(context, 'SKU', product.sku!),
                  if (product.barcode != null)
                    _buildDetailItem(context, '条码', product.barcode!),
                  if (product.brand != null)
                    _buildDetailItem(context, '品牌', product.brand!),
                  if (product.specification != null)
                    _buildDetailItem(context, '规格', product.specification!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 价格信息卡片
          if (product.effectivePrice != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '价格信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 有效价格
                    Row(
                      children: [
                        Icon(
                          Icons.price_change,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '当前价格',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          '￥${product.effectivePrice!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),

                    if (product.retailPrice != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.sell, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '零售价',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Text(
                            '￥${product.retailPrice!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],

                    if (product.promotionalPrice != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_offer, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '促销价',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            '￥${product.promotionalPrice!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 其他信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '其他信息',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.productEditPath(productId));
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑商品'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.products);
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('返回列表'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
