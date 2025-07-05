import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/product_list/index.dart';
import '../../application/provider/product_providers.dart';

class ProductSelectionScreen extends ConsumerStatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  ConsumerState<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends ConsumerState<ProductSelectionScreen> {
  List<dynamic> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('选择货品 (已选择${selectedIds.length}种)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(selectedIds);
            },
            child: const Text('确定'),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final productsAsync = ref.watch(allProductsProvider);
          return productsAsync.when(
            data: (products) => ProductList(
              data: products,
              mode: 'select',
              selectedIds: selectedIds,
              onSelectionChange: (newSelectedIds) {
                setState(() {
                  selectedIds = newSelectedIds;
                });
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          );
        },
      ),
    );
  }
}