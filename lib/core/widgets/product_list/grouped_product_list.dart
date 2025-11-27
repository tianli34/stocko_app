import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/product/application/provider/product_providers.dart';
import '../../../features/product/domain/model/product.dart';
import '../cached_image_widget.dart';

/// 按商品组聚合展示的商品列表
class GroupedProductList extends ConsumerWidget {
  final List<ProductGroupAggregate> data;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final Function(ProductModel)? onAdjustInventory;

  const GroupedProductList({
    super.key,
    required this.data,
    this.onEdit,
    this.onDelete,
    this.onAdjustInventory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final aggregate = data[index];
        if (aggregate.isGroup) {
          return _GroupedProductCard(
            aggregate: aggregate,
            onEdit: onEdit,
            onDelete: onDelete,
            onAdjustInventory: onAdjustInventory,
          );
        } else {
          return _SingleProductCard(
            product: aggregate.products.first,
            onEdit: onEdit,
            onDelete: onDelete,
            onAdjustInventory: onAdjustInventory,
          );
        }
      },
    );
  }
}

/// 商品组卡片 - 可展开显示组内商品
class _GroupedProductCard extends StatefulWidget {
  final ProductGroupAggregate aggregate;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final Function(ProductModel)? onAdjustInventory;

  const _GroupedProductCard({
    required this.aggregate,
    this.onEdit,
    this.onDelete,
    this.onAdjustInventory,
  });

  @override
  State<_GroupedProductCard> createState() => _GroupedProductCardState();
}


class _GroupedProductCardState extends State<_GroupedProductCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: theme.primaryColor.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          // 商品组头部
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 商品组图片
                  _buildGroupImage(),
                  const SizedBox(width: 12),
                  // 商品组信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.folder_outlined, 
                                size: 16, color: theme.primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.aggregate.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.aggregate.priceRange,
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.aggregate.products.length} 个变体',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 展开/收起图标
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // 展开的商品列表
          if (_isExpanded) ...[
            const Divider(height: 1),
            ...widget.aggregate.products.map((product) => _VariantItem(
              product: product,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              onAdjustInventory: widget.onAdjustInventory,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupImage() {
    final image = widget.aggregate.displayImage;
    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ProductThumbnailImage(imagePath: image),
      );
    }
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.folder,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        size: 30,
      ),
    );
  }
}

/// 组内变体商品项
class _VariantItem extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final Function(ProductModel)? onAdjustInventory;

  const _VariantItem({
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onAdjustInventory,
  });

  void _showMenu(BuildContext context, LongPressStartDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        overlay.size.width - details.globalPosition.dx,
        overlay.size.height - details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('删除', style: TextStyle(color: Colors.red)),
        ),
        const PopupMenuItem<String>(value: 'adjust_inventory', child: Text('调整库存')),
      ],
    ).then((value) {
      if (value == 'edit') {
        onEdit?.call(product);
      } else if (value == 'delete') {
        onDelete?.call(product);
      } else if (value == 'adjust_inventory') {
        onAdjustInventory?.call(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        _showMenu(context, details);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // 变体图片
            if (product.image != null && product.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ProductThumbnailImage(imagePath: product.image!),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.image_outlined, 
                    color: Colors.grey.shade400, size: 20),
              ),
            const SizedBox(width: 12),
            // 变体信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.variantName ?? product.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => onEdit?.call(product),
              color: Colors.grey[600],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}


/// 单个商品卡片（未分组的商品）
class _SingleProductCard extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final Function(ProductModel)? onAdjustInventory;

  const _SingleProductCard({
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onAdjustInventory,
  });

  void _showMenu(BuildContext context, LongPressStartDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        overlay.size.width - details.globalPosition.dx,
        overlay.size.height - details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('删除', style: TextStyle(color: Colors.red)),
        ),
        const PopupMenuItem<String>(value: 'adjust_inventory', child: Text('调整库存')),
      ],
    ).then((value) {
      if (value == 'edit') {
        onEdit?.call(product);
      } else if (value == 'delete') {
        onDelete?.call(product);
      } else if (value == 'adjust_inventory') {
        onAdjustInventory?.call(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        _showMenu(context, details);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // 商品图片
            if (product.image != null && product.image!.isNotEmpty)
              ProductThumbnailImage(imagePath: product.image!)
            else
              Container(
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
            const SizedBox(width: 12),
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
