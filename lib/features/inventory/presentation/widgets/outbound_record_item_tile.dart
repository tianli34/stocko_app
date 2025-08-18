import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../application/provider/batch_providers.dart';

class OutboundRecordItemTile extends ConsumerWidget {
  final OutboundItemData item;

  const OutboundRecordItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));
    final batchAsync = item.batchId != null
        ? ref.watch(batchByNumberProvider(item.batchId!))
        : null;

    return ListTile(
  contentPadding: const EdgeInsets.only(left: 3, right: 16, top: 0, bottom: 0),
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
                data: (product) => Text(product?.name ?? '货品ID: ${item.productId}', style: const TextStyle(fontSize: 16)),
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
        mainAxisSize: MainAxisSize.min, // 避免 trailing 拉伸导致整体变高
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('数量: ${item.quantity}') ,
          if (batchAsync != null)
            batchAsync.when(
              data: (batch) {
                if (batch?.productionDate == null) {
                  return const SizedBox.shrink();
                }
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
