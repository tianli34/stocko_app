import 'package:flutter/material.dart';
import '../../domain/model/stocktake_item.dart';
import '../../domain/model/stocktake_status.dart';

/// 差异项卡片
class DiffItemCard extends StatelessWidget {
  final StocktakeItemModel item;
  final Function(String) onReasonChanged;

  const DiffItemCard({
    super.key,
    required this.item,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOverage = item.differenceQty > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverage
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品名称和差异标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName ?? '商品 #${item.productId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDiffBadge(item.differenceQty),
              ],
            ),
            const SizedBox(height: 12),

            // 数量对比
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuantityItem('系统库存', item.systemQuantity),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  _buildQuantityItem('实盘数量', item.actualQuantity,
                      highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 差异原因选择
            const Text(
              '差异原因',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DifferenceReason.values.map((reason) {
                final isSelected = item.differenceReason == reason.displayName;
                return ChoiceChip(
                  label: Text(reason.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onReasonChanged(reason.displayName);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),

            // 已调整标记
            if (item.isAdjusted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      '已调整',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiffBadge(int diff) {
    final isPositive = diff > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 2),
          Text(
            isPositive ? '+$diff' : '$diff',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityItem(String label, int value, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.blue : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
