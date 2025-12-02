import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/provider/sale_list_provider.dart';
import 'empty_cart_state.dart';
import 'sale_item_card.dart';

/// 销售购物车列表组件
/// 根据购物车状态显示商品列表或空状态
class SaleCartList extends ConsumerWidget {
  final int? shopId;
  final bool showPriceInfo;
  final List<FocusNode> priceFocusNodes;
  final List<FocusNode> quantityFocusNodes;
  final void Function(int index)? onItemSubmitted;

  const SaleCartList({
    super.key,
    this.shopId,
    this.showPriceInfo = true,
    required this.priceFocusNodes,
    required this.quantityFocusNodes,
    this.onItemSubmitted,
  });

  // EmptyCartState 的最小高度（vertical padding 123*2 + 内容约 100）
  static const double _minHeight = 376.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleItemIds = ref.watch(
      saleListProvider.select((items) => items.map((e) => e.id).toList()),
    );

    if (saleItemIds.isEmpty) {
      return const EmptyCartState();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Column(
        children: saleItemIds.asMap().entries.map((entry) {
          final index = entry.key;
          final itemId = entry.value;
          return SaleItemCard(
            key: ValueKey(itemId),
            itemId: itemId,
            shopId: shopId,
            showPriceInfo: showPriceInfo,
            sellingPriceFocusNode:
                priceFocusNodes.length > index ? priceFocusNodes[index] : null,
            quantityFocusNode:
                quantityFocusNodes.length > index ? quantityFocusNodes[index] : null,
            onSubmitted: () => onItemSubmitted?.call(index),
          );
        }).toList(),
      ),
    );
  }
}
