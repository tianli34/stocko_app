import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database.dart';
import 'inbound_record_card.dart';
import '../providers/outbound_receipts_provider.dart';
import 'outbound_record_item_tile.dart';

class OutboundRecordCard extends ConsumerWidget {
  final OutboundReceiptData record;

  const OutboundRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(outboundReceiptItemsProvider(record.id));
    final shopAsync = ref.watch(shopByIdProvider(record.shopId));

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormatter.format(record.createdAt);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),

        title: Text(
          '单号: ${record.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日期: $formattedDate'),
            shopAsync.when(
              data: (shop) => Text('店铺: ${shop?.name ?? '未知'}'),
              loading: () => const Text('店铺: 加载中...'),
              error: (_, __) => const Text('店铺: 加载失败'),
            ),
            if (record.reason.isNotEmpty) Text('原因: ${record.reason}'),
          ],
        ),
        trailing: itemsAsync.when(
          data: (items) {
            final totalQuantity = items.fold<int>(
              0,
              (sum, it) => sum + it.quantity,
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${items.length} 种',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalQuantity 件',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error, color: Colors.red),
        ),
        children: [
          itemsAsync.when(
            data: (items) => Column(
              children: items
                  .map((item) => OutboundRecordItemTile(item: item))
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('加载明细失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
