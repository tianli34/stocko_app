import 'package:flutter/material.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';
import 'package:stocko_app/core/widgets/full_screen_image_viewer.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

class ProductDetailsDialog extends StatelessWidget {
  final Product product;

  const ProductDetailsDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16), // 产品图片
            if (product.image != null && product.image!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FullScreenImageViewer(
                            imagePath: product.image!,
                            heroTag:
                                'product_dialog_image_${product.id}_${product.image!}',
                          ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 300),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 200,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'product_dialog_image_${product.id}_${product.image!}',
                  child: ProductDialogImage(imagePath: product.image!),
                ),
              ),

            // 产品详情            if (product.sku != null)
            _buildDetailItem(context, 'SKU', product.sku!),

            // 条码信息 - 已移除，现在条码存储在独立的条码表中
            // 如果需要显示条码，需要单独查询条码表
            if (product.effectivePrice != null)
              _buildDetailItem(
                context,
                '价格',
                '￥${product.effectivePrice!.toStringAsFixed(2)}',
              ),

            if (product.stockWarningValue != null)
              _buildDetailItem(
                context,
                '库存预警值',
                '${product.stockWarningValue}',
              ),
            if (product.shelfLife != null)
              _buildDetailItem(
                context,
                '保质期',
                _formatShelfLife(
                  product.shelfLife,
                  _getProductShelfLifeUnit(product),
                ),
              ),

            _buildDetailItem(
              context,
              '批次管理',
              product.enableBatchManagement ? '已启用' : '未启用',
            ),

            if (product.remarks != null)
              _buildDetailItem(context, '备注', product.remarks!),

            if (product.lastUpdated != null)
              _buildDetailItem(
                context,
                '最后更新',
                _formatDateTime(product.lastUpdated!),
              ),

            const SizedBox(height: 24),

            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化保质期显示
  String _formatShelfLife(int? shelfLife, String? unit) {
    if (shelfLife == null) return '';

    final unitText = _getShelfLifeUnitDisplayName(unit ?? 'months');
    return '$shelfLife$unitText';
  }

  /// 获取保质期单位显示名称
  String _getShelfLifeUnitDisplayName(String unit) {
    switch (unit) {
      case 'days':
        return '天';
      case 'months':
        return '个月';
      case 'years':
        return '年';
      default:
        return '个月';
    }
  }

  /// 获取产品的保质期单位
  String _getProductShelfLifeUnit(Product product) {
    // 返回产品实际的保质期单位
    return product.shelfLifeUnit;
  }
}
