import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../domain/model/stocktake_item.dart';

/// 盘点项卡片
class StocktakeItemCard extends StatefulWidget {
  final StocktakeItemModel item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const StocktakeItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  State<StocktakeItemCard> createState() => _StocktakeItemCardState();
}

class _StocktakeItemCardState extends State<StocktakeItemCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.item.actualQuantity.toString());
  }

  @override
  void didUpdateWidget(StocktakeItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.actualQuantity != widget.item.actualQuantity &&
        !_isEditing) {
      _controller.text = widget.item.actualQuantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 商品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? '商品 #${item.productId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '系统库存: ${item.systemQuantity}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (item.hasDifference) ...[
                          const SizedBox(width: 8),
                          _buildDiffBadge(item.differenceQty),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 数量输入
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    // 减少按钮
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(_controller.text) ?? 0;
                        if (current > 0) {
                          _updateQuantity(current - 1);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    // 数量输入框
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        onTap: () => setState(() => _isEditing = true),
                        onSubmitted: (value) {
                          setState(() => _isEditing = false);
                          final qty = int.tryParse(value) ?? 0;
                          _updateQuantity(qty);
                        },
                        onTapOutside: (_) {
                          if (_isEditing) {
                            setState(() => _isEditing = false);
                            final qty = int.tryParse(_controller.text) ?? 0;
                            _updateQuantity(qty);
                          }
                        },
                      ),
                    ),

                    // 增加按钮
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(_controller.text) ?? 0;
                        _updateQuantity(current + 1);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateQuantity(int quantity) {
    if (quantity < 0) quantity = 0;
    _controller.text = quantity.toString();
    widget.onQuantityChanged(quantity);
  }

  Widget _buildDiffBadge(int diff) {
    final isPositive = diff > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPositive ? '+$diff' : '$diff',
        style: TextStyle(
          fontSize: 12,
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
