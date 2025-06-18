import 'package:flutter/material.dart';
import '../../../../core/widgets/cached_image_widget.dart';

/// 库存商品卡片
/// 展示单个商品的库存信息
class InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> inventory; // 临时使用Map，后续替换为真实的Inventory模型

  const InventoryItemCard({super.key, required this.inventory});
  @override
  Widget build(BuildContext context) {
    final quantity = inventory['quantity'] as double? ?? 0.0;
    final productName = inventory['productName'] as String? ?? '';
    final productImage = inventory['productImage'] as String?;
    final unit = inventory['unit'] as String? ?? '件';
    final categoryName = inventory['categoryName'] as String? ?? '未分类';
    final shopName = inventory['shopName'] as String? ?? '未知店铺';

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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: productImage != null && productImage.isNotEmpty
                    ? CachedImageWidget(
                        imagePath: productImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        size: 30,
                        color: Colors.grey[400],
                      ),
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
                      const Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '库存: ${quantity.toInt()} ($unit)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),

                      // 库存状态指示器
                      _buildStatusIndicator(stockStatus),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 其他信息
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.store,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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

  /// 根据库存数量获取状态
  _StockStatus _getStockStatus(double quantity) {
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
