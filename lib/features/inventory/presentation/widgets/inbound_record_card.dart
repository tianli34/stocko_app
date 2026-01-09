import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database.dart';
import '../providers/inbound_records_provider.dart';
import '../providers/inventory_query_providers.dart';
import 'inbound_record_item_tile.dart';
import '../../../inbound/application/service/inbound_service.dart';

// This might need to be created if it doesn't exist.
// For now, let's create a simple one.
final shopByIdProvider =
    FutureProvider.family<ShopData?, int>((ref, id) {
  final database = ref.watch(appDatabaseProvider);
  return database.shopDao.getShopById(id);
});


/// Inbound Record Card
/// Displays a single inbound record with an expandable list of items.
class InboundRecordCard extends ConsumerWidget {
  final InboundReceiptData record;

  const InboundRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inboundRecordItemsProvider(record.id));
    final shopAsync = ref.watch(shopByIdProvider(record.shopId));

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormatter.format(record.createdAt);

    final isVoided = record.status == 'voided';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isVoided ? Colors.red.shade100 : Colors.grey.shade300, width: 1),
      ),
      color: isVoided ? Colors.red.shade50 : null,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '单号: ${record.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isVoided ? TextDecoration.lineThrough : null,
                  color: isVoided ? Colors.red : null,
                ),
              ),
            ),
            if (isVoided)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已撤销',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日期: $formattedDate'),
            shopAsync.when(
              data: (shop) => Text('店铺: ${shop?.name ?? '未知'}'),
              loading: () => const Text('店铺: 加载中...'),
              error: (_, _) => const Text('店铺: 加载失败'),
            ),
            if (record.source.isNotEmpty) Text('来源: ${record.source}'),
            if (record.remarks?.isNotEmpty == true) Text('备注: ${record.remarks}'),
          ],
        ),
        trailing: itemsAsync.when(
          data: (items) {
            final totalQuantity = items.fold<double>(
              0,
              (sum, item) => sum + item.quantity,
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${items.length} 种',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalQuantity.toStringAsFixed(totalQuantity.truncateToDouble() == totalQuantity ? 0 : 1)} 件',
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
                  .map((item) => InboundRecordItemTile(item: item))
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
          if (!isVoided)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRevokeDialog(context, ref),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('撤销入库'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRevokeDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认撤销'),
        content: const Text(
          '撤销操作将：\n'
          '1. 扣减已入库的库存\n'
          '2. 回滚库存成本价\n'
          '3. 作废或重置关联的采购单\n\n'
          '确定要执行此操作吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定撤销'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(inboundServiceProvider).revokeInbound(record.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('撤销成功')),
          );
          // 刷新列表
          ref.invalidate(inboundRecordsProvider);
          // 刷新库存查询页面
          ref.invalidate(inventoryQueryProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('撤销失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
