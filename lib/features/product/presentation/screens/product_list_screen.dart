import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product.dart';
import '../../../../core/widgets/product_list/product_list.dart';
import '../../../../core/constants/app_routes.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除货品「${product.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(productOperationsProvider.notifier).deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('货品列表'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.productNew),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) {
          print('📊 产品列表数据:');
          for (final product in products) {
            print('  - ${product.name}: unitId=${product.unitId}');
          }
          final sortedProducts = [...products]..sort((a, b) => 
            (b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(int.tryParse(b.id) ?? 0))
            .compareTo(a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(int.tryParse(a.id) ?? 0)));
          return ProductList(
            data: sortedProducts,
            onEdit: (product) => context.push(AppRoutes.productEditPath(product.id)),
            onDelete: (product) => _showDeleteConfirmDialog(context, ref, product),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(allProductsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}