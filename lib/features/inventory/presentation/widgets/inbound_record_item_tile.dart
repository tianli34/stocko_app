import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../application/provider/batch_providers.dart';

class InboundRecordItemTile extends ConsumerWidget {
  final InboundItemData item;

  const InboundRecordItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));
    final batchAsync = ref.watch(batchByNumberProvider(item.id));

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
      subtitle: Text('批号: ${item.id}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '数量: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}',
          ),
          batchAsync.when(
              data: (batch) {
                if (batch?.productionDate == null) return const SizedBox.shrink();
                return Text(
                  '生产日期: ${DateFormat('yyyy-MM-dd').format(batch!.productionDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
              loading: () => const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, s) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}