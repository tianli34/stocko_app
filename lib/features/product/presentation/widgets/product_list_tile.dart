import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product.dart';
import '../../application/provider/product_providers.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';

/// 产品列表项组件
/// 用于在产品列表中显示单个产品的信息
class ProductListTile extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showPrice;

  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(productControllerProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息：图片、名称和状态
              Row(
                children: [
                  // 产品图片
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _buildProductImage(context),
                  ),
                  Expanded(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 产品详细信息
              _buildProductInfo(context),

              // 价格信息
              if (showPrice && _hasPrice()) ...[
                const SizedBox(height: 8),
                _buildPriceInfo(context),
              ],

              // 操作按钮
              if (showActions) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context, ref, controllerState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建产品信息
  Widget _buildProductInfo(BuildContext context) {
    final infoItems = <Widget>[]; // SKU 信息
    if (product.sku != null) {
      infoItems.add(_buildInfoItem(context, label: 'SKU', value: product.sku!));
    }

    // 条码信息
    if (product.barcode != null) {
      infoItems.add(
        _buildInfoItem(context, label: '条码', value: product.barcode!),
      );
    }

    // 品牌信息
    if (product.brand != null) {
      infoItems.add(
        _buildInfoItem(context, label: '品牌', value: product.brand!),
      );
    }

    // 规格信息
    if (product.specification != null) {
      infoItems.add(
        _buildInfoItem(context, label: '规格', value: product.specification!),
      );
    }

    return infoItems.isEmpty
        ? const SizedBox.shrink()
        : Wrap(spacing: 16, runSpacing: 4, children: infoItems);
  }

  /// 构建信息项
  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// 检查是否有价格信息
  bool _hasPrice() {
    return product.effectivePrice != null;
  }

  /// 构建价格信息
  Widget _buildPriceInfo(BuildContext context) {
    final effectivePrice = product.effectivePrice;
    if (effectivePrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 有效价格（促销价 > 零售价 > 建议零售价）
                Text(
                  '￥${effectivePrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 价格类型标签
                if (product.hasPromotionalPrice)
                  Text(
                    '促销价',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (product.retailPrice != null)
                  Text(
                    '零售价',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  )
                else
                  Text(
                    '建议零售价',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // 显示原价（如果有促销价）
          if (product.hasPromotionalPrice && product.retailPrice != null)
            Text(
              '原价: ￥${product.retailPrice!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ProductControllerState controllerState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 编辑按钮
        if (onEdit != null)
          TextButton.icon(
            onPressed: controllerState.isLoading ? null : onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('编辑'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),

        const SizedBox(width: 8), // 删除按钮
        if (onDelete != null)
          TextButton.icon(
            onPressed: controllerState.isLoading ? null : onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
          ),
      ],
    );
  }

  /// 构建产品图片
  Widget _buildProductImage(BuildContext context) {
    if (product.image != null && product.image!.isNotEmpty) {
      return GestureDetector(
        onTap: onTap, // 单击跳转到详情页
        onLongPress: () {
          // 长按打开全屏查看器
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FullScreenImageViewer(
                    imagePath: product.image!,
                    heroTag:
                        'product_thumbnail_${product.id}_${product.image!}',
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        child: Hero(
          tag: 'product_thumbnail_${product.id}_${product.image!}',
          child: CachedImageWidget(
            imagePath: product.image!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(6),
            quality: 75,
            placeholder: _buildImagePlaceholder(),
            errorWidget: _buildImagePlaceholder(),
          ),
        ),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }

  /// 构建图片占位符
  Widget _buildImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 30),
    );
  }
}

/// 产品列表项的简化版本
/// 适用于只需要显示基本信息的场景
class SimpleProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const SimpleProductListTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.sku != null) Text('SKU: ${product.sku}'),
          if (product.effectivePrice != null)
            Text(
              '￥${product.effectivePrice!.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
