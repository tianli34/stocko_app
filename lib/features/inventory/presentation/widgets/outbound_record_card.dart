import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory_transaction.dart';
import 'package:stocko_app/features/product/application/provider/product_providers.dart';
import 'package:stocko_app/features/inventory/presentation/widgets/inbound_record_card.dart';

class OutboundRecordCard extends ConsumerWidget {
  final InventoryTransactionModel record;

  const OutboundRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(record.productId));
    final shopAsync = ref.watch(shopByIdProvider(record.shopId));

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = record.createdAt != null
        ? dateFormatter.format(record.createdAt!)
        : '未知日期';

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productAsync.when(
              data: (product) => Text(
                '产品: ${product?.name ?? '未知产品'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              loading: () => const Text(
                '产品: 加载中...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              error: (e, s) => Text(
                '产品: 加载失败',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Text('数量: ${record.quantity}'),
            const SizedBox(height: 8),
            shopAsync.when(
              data: (shop) => Text('店铺: ${shop?.name ?? '未知'}'),
              loading: () => const Text('店铺: 加载中...'),
              error: (_, __) => const Text('店铺: 加载失败'),
            ),
            const SizedBox(height: 8),
            Text('时间: $formattedDate'),
          ],
        ),
      ),
    );
  }
}