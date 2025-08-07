import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../product/data/repository/product_repository.dart';

class InboundRecordItemTile extends ConsumerWidget {
  final InboundReceiptItemsTableData item;

  const InboundRecordItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      title: productAsync.when(
        data: (product) => Text(product?.name ?? '货品ID: ${item.productId}'),
        loading: () => const Text('加载中...'),
        error: (err, stack) => Text(
          '加载货品失败',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      subtitle: Text('批号: ${item.batchNumber ?? '无'}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '数量: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}',
          ),
          if (item.productionDate != null)
            Text(
              '生产日期: ${item.productionDate!.toString().substring(0, 10)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}