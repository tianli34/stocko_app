import 'package:flutter/material.dart';
import '../../domain/model/aggregated_inventory.dart';
import '../../../../core/widgets/cached_image_widget.dart';

/// 简单库存卡片组件
/// 用于展示单条记录的货品（不可展开）
/// 样式与原始卡片一致
class SimpleInventoryCard extends StatelessWidget {
  final AggregatedInventoryItem item;

  const SimpleInventoryCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    // 断言：此组件仅用于单条记录
    assert(
      !item.isExpandable,
      'SimpleInventoryCard should only be used for items with single record',
    );

    final detail = item.details.first; // 只有一条记录

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 商品图片
            _buildProductImage(),
            const SizedBox(width: 16),

            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名称
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 分类和店铺信息
                  Text(
                    '${item.categoryName} · ${detail.shopName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  // 保质期信息
                  if (detail.remainingDays != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail.remainingDaysDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getShelfLifeColor(detail),
                        fontWeight: detail.isExpired || detail.isExpiringSoon
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 库存数量（无展开图标，样式与原始卡片一致）
                  Row(
                    children: [
                      Text(
                        '${item.totalQuantity}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),

                      // 库存状态指示器
                      _buildStatusIndicator(item.totalQuantity),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建商品图片
  Widget _buildProductImage() {
    if (item.productImage != null && item.productImage!.isNotEmpty) {
      return ProductThumbnailImage(imagePath: item.productImage!);
    } else {
      return Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 30,
        ),
      );
    }
  }

  /// 获取保质期颜色
  Color _getShelfLifeColor(InventoryDetail detail) {
    switch (detail.shelfLifeColorStatus) {
      case 'expired':
        return Colors.red;
      case 'critical':
        return Colors.orange;
      case 'warning':
        return Colors.amber.shade700;
      case 'normal':
      default:
        return Colors.grey.shade700;
    }
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(int quantity) {
    if (quantity <= 0) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      );
    } else if (quantity <= 10) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
