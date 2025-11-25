import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/product_group_providers.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product.dart';

/// 商品组详情页面 - 展示组内所有变体商品
class ProductGroupDetailScreen extends ConsumerWidget {
  final int groupId;

  const ProductGroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allProductGroupsProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return groupsAsync.when(
      data: (groups) {
        final group = groups.where((g) => g.id == groupId).firstOrNull;
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('商品组详情')),
            body: const Center(child: Text('商品组不存在')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '添加变体商品',
                onPressed: () => _showAddVariantDialog(context, ref, group),
              ),
            ],
          ),
          body: productsAsync.when(
            data: (products) {
              final variants = products
                  .where((p) => p.groupId == groupId)
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              if (variants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('该商品组暂无变体商品',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角 + 添加变体商品',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // 商品组信息卡片
                  _GroupInfoCard(group: group, variantCount: variants.length),
                  const Divider(height: 1),
                  // 变体商品列表
                  Expanded(
                    child: ListView.builder(
                      itemCount: variants.length,
                      itemBuilder: (context, index) {
                        final product = variants[index];
                        return _VariantProductTile(
                          product: product,
                          onTap: () => context.push(
                            AppRoutes.productEditPath(product.id.toString()),
                          ),
                          onRemove: () =>
                              _confirmRemoveFromGroup(context, ref, product),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('商品组详情')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('商品组详情')),
        body: Center(child: Text('加载失败: $e')),
      ),
    );
  }

  /// 显示添加变体商品对话框
  Future<void> _showAddVariantDialog(
    BuildContext context,
    WidgetRef ref,
    ProductGroupData group,
  ) async {
    final products = await ref.read(allProductsProvider.future);
    // 筛选出未关联任何商品组的商品
    final availableProducts =
        products.where((p) => p.groupId == null).toList();

    if (availableProducts.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('提示'),
          content: const Text('没有可添加的商品，所有商品都已关联到商品组。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final variantNameController = TextEditingController();
    ProductModel? selectedProduct;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('添加变体到「${group.name}」'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择商品：'),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductModel>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('请选择商品'),
                  items: availableProducts.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (p) => setState(() => selectedProduct = p),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: variantNameController,
                  decoration: const InputDecoration(
                    labelText: '变体名称',
                    hintText: '如：黄瓜味、番茄味',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: selectedProduct == null
                  ? null
                  : () => Navigator.pop(ctx, {
                        'product': selectedProduct,
                        'variantName': variantNameController.text.trim(),
                      }),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final product = result['product'] as ProductModel;
      final variantName = result['variantName'] as String;

      // 更新商品的 groupId 和 variantName
      final updatedProduct = product.copyWith(
        groupId: groupId,
        variantName: variantName.isEmpty ? null : variantName,
      );

      await ref
          .read(productOperationsProvider.notifier)
          .updateProduct(updatedProduct);
    }
  }

  /// 确认从商品组移除
  Future<void> _confirmRemoveFromGroup(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除变体'),
        content: Text('确定要将「${product.name}」从商品组中移除吗？\n商品本身不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 清除 groupId 和 variantName
      final updatedProduct = ProductModel(
        id: product.id,
        name: product.name,
        sku: product.sku,
        image: product.image,
        baseUnitId: product.baseUnitId,
        categoryId: product.categoryId,
        groupId: null,
        variantName: null,
        specification: product.specification,
        brand: product.brand,
        suggestedRetailPrice: product.suggestedRetailPrice,
        retailPrice: product.retailPrice,
        promotionalPrice: product.promotionalPrice,
        stockWarningValue: product.stockWarningValue,
        shelfLife: product.shelfLife,
        shelfLifeUnit: product.shelfLifeUnit,
        enableBatchManagement: product.enableBatchManagement,
        status: product.status,
        remarks: product.remarks,
        lastUpdated: product.lastUpdated,
      );

      await ref
          .read(productOperationsProvider.notifier)
          .updateProduct(updatedProduct);
    }
  }
}

class _GroupInfoCard extends StatelessWidget {
  final ProductGroupData group;
  final int variantCount;

  const _GroupInfoCard({required this.group, required this.variantCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.folder,
                size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (group.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    group.description!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '$variantCount 个变体',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _VariantProductTile({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: product.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.image!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultIcon(context),
              ),
            )
          : _defaultIcon(context),
      title: Text(product.name),
      subtitle: product.variantName != null
          ? Text('变体：${product.variantName}')
          : Text(product.formattedPrice),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        tooltip: '从商品组移除',
        onPressed: onRemove,
      ),
      onTap: onTap,
    );
  }

  Widget _defaultIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.inventory_2, color: Colors.grey),
    );
  }
}
