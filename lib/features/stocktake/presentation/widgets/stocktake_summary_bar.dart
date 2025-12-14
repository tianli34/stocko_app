import 'package:flutter/material.dart';
import '../../domain/model/stocktake_item.dart';

/// 盘点汇总栏
class StocktakeSummaryBar extends StatelessWidget {
  final StocktakeSummary summary;
  final bool showDiffDetail;

  const StocktakeSummaryBar({
    super.key,
    required this.summary,
    this.showDiffDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: showDiffDetail ? _buildDiffDetail() : _buildBasicSummary(),
    );
  }

  Widget _buildBasicSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('已盘点', '${summary.checkedItems}', Colors.blue),
        _buildSummaryItem('有差异', '${summary.diffItems}',
            summary.diffItems > 0 ? Colors.orange : Colors.grey),
        _buildSummaryItem(
          '完成率',
          '${(summary.completionRate * 100).toStringAsFixed(0)}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildDiffDetail() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('已盘点', '${summary.checkedItems}', Colors.blue),
            _buildSummaryItem('有差异', '${summary.diffItems}',
                summary.diffItems > 0 ? Colors.orange : Colors.grey),
          ],
        ),
        if (summary.diffItems > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDiffItem(
                '盘盈',
                summary.overageItems,
                summary.totalOverageQty,
                Colors.green,
              ),
              _buildDiffItem(
                '盘亏',
                summary.shortageItems,
                summary.totalShortageQty,
                Colors.red,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildDiffItem(String label, int count, int qty, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label == '盘盈' ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count项 (${label == '盘盈' ? '+' : '-'}$qty)',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
