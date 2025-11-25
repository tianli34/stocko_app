import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/application/provider/product_unit_providers.dart';
import '../../../product/application/provider/unit_providers.dart';

class InboundRecordItemTile extends ConsumerWidget {
  final InboundItemData item;

  const InboundRecordItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 先获取unitProduct以获得productId和unitId
    final unitProductAsync = ref.watch(productUnitByIdProvider(item.unitProductId));
    
    return unitProductAsync.when(
      data: (unitProduct) {
        if (unitProduct == null) {
          return ListTile(
            title: Text('未找到产品单位配置: ${item.unitProductId}'),
          );
        }
        
        final productAsync = ref.watch(productByIdProvider(unitProduct.productId));
        final unitAsync = ref.watch(unitByIdProvider(unitProduct.unitId));
        
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
                    product?.name ?? '货品ID: ${unitProduct.productId}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  loading: () => const Text('加载中...'),
                  error: (err, stack) => Text(
                    '加载货品失败',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              unitAsync.when(
                data: (unit) => Text(
                  unit?.name ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
          trailing: Text(
            item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
            style: const TextStyle(fontSize: 16),
          ),
        );
      },
      loading: () => const ListTile(
        title: Text('加载中...'),
      ),
      error: (err, stack) => ListTile(
        title: Text(
          '加载失败',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
