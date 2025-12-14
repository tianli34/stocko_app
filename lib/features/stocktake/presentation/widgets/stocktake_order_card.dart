import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/model/stocktake_order.dart';
import '../../domain/model/stocktake_status.dart';

/// 盘点单卡片
class StocktakeOrderCard extends StatelessWidget {
  final StocktakeOrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const StocktakeOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：单号和状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),

              // 信息行
              Row(
                children: [
                  _buildInfoItem(
                    Icons.store,
                    order.shopName ?? '店铺 #${order.shopId}',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    Icons.category,
                    order.type.displayName,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 时间和操作
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.createdAt != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt!)
                        : '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (order.status == StocktakeStatus.draft && onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: Colors.red[400],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              // 统计信息（如果有）
              if (order.itemCount != null || order.diffCount != null) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    if (order.itemCount != null)
                      _buildStatItem('盘点项', '${order.itemCount}'),
                    if (order.diffCount != null && order.diffCount! > 0) ...[
                      const SizedBox(width: 24),
                      _buildStatItem('差异项', '${order.diffCount}',
                          color: Colors.orange),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(StocktakeStatus status) {
    Color color;
    switch (status) {
      case StocktakeStatus.draft:
        color = Colors.grey;
        break;
      case StocktakeStatus.inProgress:
        color = Colors.blue;
        break;
      case StocktakeStatus.completed:
        color = Colors.orange;
        break;
      case StocktakeStatus.audited:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
