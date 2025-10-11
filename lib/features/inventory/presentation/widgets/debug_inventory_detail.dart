import 'package:flutter/material.dart';
import '../../domain/model/aggregated_inventory.dart';

/// 调试用：显示库存详细信息的原始数据
class DebugInventoryDetail extends StatelessWidget {
  final InventoryDetail detail;

  const DebugInventoryDetail({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '调试信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Divider(),
            _buildRow('店铺名称', detail.shopName),
            _buildRow('生产日期', detail.productionDate?.toString() ?? 'null'),
            _buildRow('保质期数值', detail.shelfLifeDays?.toString() ?? 'null'),
            _buildRow('保质期单位', detail.shelfLifeUnit ?? 'null'),
            _buildRow('计算的剩余天数', detail.remainingDays?.toString() ?? 'null'),
            _buildRow('显示文本', detail.remainingDaysDisplayText),
            const Divider(),
            Text(
              '如果显示不对，请检查数据库中的实际值',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
