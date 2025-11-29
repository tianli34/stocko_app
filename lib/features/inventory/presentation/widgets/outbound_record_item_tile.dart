import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/application/provider/product_unit_providers.dart';
import '../../../product/domain/model/product.dart';
import '../../application/provider/batch_providers.dart';

class OutboundRecordItemTile extends ConsumerWidget {
  final OutboundItemData item;

  const OutboundRecordItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 通过 unitProductId 获取 unitProduct，然后获取 productId
    final unitProductAsync = ref.watch(productUnitByIdProvider(item.unitProductId));
    
    return unitProductAsync.when(
      data: (unitProduct) {
        if (unitProduct == null) {
          return _buildErrorTile(context, '未找到产品单位');
        }
        
        final productAsync = ref.watch(productByIdProvider(unitProduct.productId));
        final batchAsync = item.batchId != null
            ? ref.watch(batchByNumberProvider(item.batchId!))
            : null;
        
        return _buildTile(context, productAsync, batchAsync);
      },
      loading: () => _buildLoadingTile(context),
      error: (err, stack) => _buildErrorTile(context, '加载失败'),
    );
  }
  
  Widget _buildTile(BuildContext context, AsyncValue<ProductModel?> productAsync, AsyncValue<ProductBatchData?>? batchAsync) {
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
              data: (product) => Text(product?.name ?? '单位产品ID: ${item.unitProductId}', style: const TextStyle(fontSize: 16)),
              loading: () => const Text('加载中...'),
              error: (err, stack) => Text(
                '加载货品失败',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
      trailing: Text('数量: ${item.quantity}'),
    );
  }
  
  Widget _buildLoadingTile(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.only(left: 3, right: 16, top: 0, bottom: 0),
      minVerticalPadding: 0,
      dense: true,
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      title: Text('加载中...'),
    );
  }
  
  Widget _buildErrorTile(BuildContext context, String message) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 3, right: 16, top: 0, bottom: 0),
      minVerticalPadding: 0,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      title: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
