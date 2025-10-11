import 'package:flutter/material.dart';
import '../../domain/model/aggregated_inventory.dart';
import '../../../../core/widgets/cached_image_widget.dart';

/// 聚合库存卡片组件
/// 用于在未筛选店铺时展示同一货品的汇总信息
/// 支持展开/收起查看详细库存明细
class AggregatedInventoryCard extends StatefulWidget {
  final AggregatedInventoryItem item;

  const AggregatedInventoryCard({super.key, required this.item});

  @override
  State<AggregatedInventoryCard> createState() =>
      _AggregatedInventoryCardState();
}

class _AggregatedInventoryCardState extends State<AggregatedInventoryCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 断言：此组件仅用于可展开的项（多条记录）
    assert(
      widget.item.isExpandable,
      'AggregatedInventoryCard should only be used for items with multiple records',
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // 收起状态：显示货品基本信息和总库存
          _buildCollapsedHeader(context),

          // 展开状态：显示详细库存列表
          if (_isExpanded)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedDetails(context),
            ),
        ],
      ),
    );
  }

  /// 构建收起状态的头部
  Widget _buildCollapsedHeader(BuildContext context) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(12),
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
                    widget.item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 分类信息
                  Text(
                    widget.item.categoryName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  // 如果有即将过期或已过期的批次，显示警告
                  if (widget.item.hasExpired ||
                      widget.item.hasExpiringSoon) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: widget.item.hasExpired
                              ? Colors.red
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.hasExpired ? '含已过期批次' : '含即将过期批次',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.item.hasExpired
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 总库存（醒目显示）
                  Row(
                    children: [
                      Text(
                        '${widget.item.totalQuantity}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.unit,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      // 显示详细记录数量
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.item.details.length}条记录',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const Spacer(),

                      // 展开/收起图标
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.expand_more, color: Colors.grey[600]),
                      ),
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
    if (widget.item.productImage != null &&
        widget.item.productImage!.isNotEmpty) {
      return ProductThumbnailImage(imagePath: widget.item.productImage!);
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

  /// 构建展开状态的详细信息
  Widget _buildExpandedDetails(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade100),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '店铺',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '生产日期',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '剩余保质期',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '数量',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // 详细记录列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.item.details.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final detail = widget.item.details[index];
              return _buildDetailRow(context, detail);
            },
          ),
        ],
      ),
    );
  }

  /// 构建单条详细记录行
  Widget _buildDetailRow(BuildContext context, InventoryDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 店铺名称
          Expanded(
            flex: 2,
            child: Text(
              detail.shopName,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 生产日期
          Expanded(
            flex: 2,
            child: Text(
              detail.batchDisplayText,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 剩余保质期
          Expanded(
            flex: 2,
            child: GestureDetector(
              onLongPress: () {
                // 长按显示调试信息
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('调试信息'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('生产日期: ${detail.productionDate}'),
                        Text('保质期天数: ${detail.shelfLifeDays}'),
                        Text('保质期单位: ${detail.shelfLifeUnit}'),
                        Text('计算的剩余天数: ${detail.remainingDays}'),
                        Text('显示文本: ${detail.remainingDaysDisplayText}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                detail.remainingDaysDisplayText,
                style: TextStyle(
                  fontSize: 13,
                  color: _getShelfLifeColor(detail),
                  fontWeight: detail.isExpired || detail.isExpiringSoon
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 库存数量
          Expanded(
            flex: 1,
            child: Text(
              '${detail.quantity}${widget.item.unit}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
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
}
