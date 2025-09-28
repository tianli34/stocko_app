import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      contentPadding: const EdgeInsets.only(
        left: 3,
        right: 16,
        top: 0,
        bottom: 0,
      ),
      minVerticalPadding: 0,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      minLeadingWidth: 0,
      title: Row(
        children: [
          Text(' ${item.id}  ', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: productAsync.when(
              data: (product) => Text(
                product?.name ?? '货品ID: ${item.productId}',
                style: const TextStyle(fontSize: 16),
              ),
              loading: () => const Text('加载中...'),
              error: (err, stack) => Text(
                '加载货品失败',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '数量: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}',
          ),
          
        ],
      ),
    );
  }
}
