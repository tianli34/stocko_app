import 'package:flutter/material.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';

/// 库存商品卡片
/// 展示单个商品的库存信息
class InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> inventory; // 临时使用Map，后续替换为真实的Inventory模型

  const InventoryItemCard({super.key, required this.inventory});
  @override
  Widget build(BuildContext context) {
    final quantity = (inventory['quantity'] as num? ?? 0).toInt();
    final productName = inventory['productName'] as String? ?? '';
    final productImage = inventory['productImage'] as String?;
    final unit = inventory['unit'] as String? ?? '件';

    // 根据库存数量确定状态
    final stockStatus = _getStockStatus(quantity);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 商品图片
            productImage != null
                ? ProductThumbnailImage(imagePath: productImage)
                : Container(
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
                  ),
            const SizedBox(width: 16),

            // 商品信息和库存
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名称
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 库存信息
                  Row(
                    children: [
                      
                      const SizedBox(width: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // 库存状态指示器
                      _buildStatusIndicator(stockStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据库存数量获取状态
  _StockStatus _getStockStatus(int quantity) {
    if (quantity <= 0) {
      return _StockStatus.outOfStock;
    } else if (quantity <= 10) {
      // 假设低库存阈值为10
      return _StockStatus.lowStock;
    } else {
      return _StockStatus.normal;
    }
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(_StockStatus status) {
    Widget indicator;

    switch (status) {
      case _StockStatus.outOfStock:
        indicator = Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
        break;
      case _StockStatus.lowStock:
        indicator = Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        );
        break;
      case _StockStatus.normal:
        indicator = const SizedBox.shrink(); // 正常库存不显示指示器
        break;
    }

    return indicator;
  }
}

/// 库存状态枚举
enum _StockStatus {
  normal, // 正常
  lowStock, // 低库存
  outOfStock, // 缺货
}
