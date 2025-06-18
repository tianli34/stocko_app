import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 入库记录卡片
/// 展示单条入库记录的信息
class InboundRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const InboundRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final recordId = record['id'] as String? ?? '';
    final shopName = record['shopName'] as String? ?? '';
    final date = record['date'] as DateTime? ?? DateTime.now();
    final productCount = record['productCount'] as int? ?? 0;
    final totalQuantity = record['totalQuantity'] as double? ?? 0.0;

    // 格式化日期
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormatter.format(date);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: 导航到入库记录详情页面
          _showRecordDetails(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 主要信息区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：记录ID、店铺名称、日期
                    Row(
                      children: [
                        // 记录ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            recordId,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 店铺名称
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shopName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 日期
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第二行：统计信息
                    Row(
                      children: [
                        Text(
                          '总计: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$productCount种货品, ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '共${totalQuantity.toStringAsFixed(totalQuantity.truncateToDouble() == totalQuantity ? 0 : 1)}件',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 箭头图标
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示记录详情（临时实现）
  void _showRecordDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('入库记录详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录ID: ${record['id']}'),
            Text('店铺: ${record['shopName']}'),
            Text('日期: ${DateFormat('yyyy-MM-dd').format(record['date'])}'),
            Text('货品种类: ${record['productCount']}种'),
            Text(
              '总数量: ${(record['totalQuantity'] as double).toStringAsFixed((record['totalQuantity'] as double).truncateToDouble() == (record['totalQuantity'] as double) ? 0 : 1)}件',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
