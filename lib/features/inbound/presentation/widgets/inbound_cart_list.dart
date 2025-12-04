import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/provider/inbound_list_provider.dart';
import 'empty_inbound_state.dart';
import 'inbound_item_card.dart';

/// 入库购物车列表组件
/// 根据购物车状态显示商品列表或空状态
class InboundCartList extends ConsumerWidget {
  final bool showPriceInfo;
  final List<FocusNode> quantityFocusNodes;
  final List<FocusNode> amountFocusNodes;
  final void Function(int index)? onAmountSubmitted;

  const InboundCartList({
    super.key,
    this.showPriceInfo = true,
    required this.quantityFocusNodes,
    required this.amountFocusNodes,
    this.onAmountSubmitted,
  });

  // EmptyInboundState 的最小高度
  static const double _minHeight = 538.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboundItemIds = ref.watch(
      inboundListProvider.select((items) => items.map((e) => e.id).toList()),
    );

    if (inboundItemIds.isEmpty) {
      return const EmptyInboundState();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Column(
        children: inboundItemIds.asMap().entries.map((entry) {
          final index = entry.key;
          final itemId = entry.value;
          return InboundItemCard(
            key: ValueKey(itemId),
            itemId: itemId,
            showPriceInfo: showPriceInfo,
            quantityFocusNode:
                quantityFocusNodes.length > index ? quantityFocusNodes[index] : null,
            amountFocusNode:
                amountFocusNodes.length > index ? amountFocusNodes[index] : null,
            onAmountSubmitted: () => onAmountSubmitted?.call(index),
          );
        }).toList(),
      ),
    );
  }
}
