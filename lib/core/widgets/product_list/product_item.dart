import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/inventory/presentation/widgets/adjust_inventory_dialog.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/application/provider/unit_providers.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';
import 'package:flutter/services.dart';

class ProductItem extends ConsumerStatefulWidget {
  final ProductModel item;
  final String mode;
  final bool isSelected;
  final Function(dynamic)? onToggleSelect;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final Function(ProductModel)? onAdjustInventory;
  final VoidCallback? onHideActions;

  const ProductItem({
    super.key,
    required this.item,
    required this.mode,
    required this.isSelected,
    this.onToggleSelect,
    this.onEdit,
    this.onDelete,
    this.onAdjustInventory,
    this.onHideActions,
  });

  @override
  ConsumerState<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends ConsumerState<ProductItem> {
  String? _unitName;
  bool _unitLoaded = false;
  int? _lastBaseUnitId;

  @override
  void initState() {
    super.initState();
    _lastBaseUnitId = widget.item.baseUnitId;
  }

  @override
  void didUpdateWidget(covariant ProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.baseUnitId != oldWidget.item.baseUnitId) {
      _lastBaseUnitId = widget.item.baseUnitId;
      _unitLoaded = false;
    }
  }

  Future<void> _loadUnitName(WidgetRef ref) async {
    if (!_unitLoaded && _lastBaseUnitId != null) {
      try {
        final unit = await ref
            .read(unitControllerProvider.notifier)
            .getUnitById(_lastBaseUnitId!);
        if (mounted) {
          setState(() {
            _unitName = unit?.name;
            _unitLoaded = true;
          });
        }
      } catch (e) {
        print('❌ 获取单位信息失败: $e');
        if (mounted) {
          setState(() {
            _unitLoaded = true;
          });
        }
      }
    }
  }

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
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('编辑'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('删除', style: TextStyle(color: Colors.red)),
        ),
        const PopupMenuItem<String>(
          value: 'adjust_inventory',
          child: Text('调整库存'),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        widget.onEdit?.call(widget.item);
      } else if (value == 'delete') {
        widget.onDelete?.call(widget.item);
      } else if (value == 'adjust_inventory') {
        showDialog(
          context: context,
          builder: (context) => AdjustInventoryDialog(product: widget.item),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 在build方法中加载单位名称，确保ref.read()在正确的上下文中使用
    if (!_unitLoaded) {
      _loadUnitName(ref);
    }
    
    return GestureDetector(
      onTap: () {
        if (widget.mode == 'select') {
          widget.onToggleSelect?.call(widget.item.id);
        }
      },
      onLongPressStart: (details) {
        if (widget.mode == 'display') {
          HapticFeedback.mediumImpact();
          _showMenu(context, details);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.grey.shade300,
            width: widget.isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            if (widget.item.image != null && widget.item.image!.isNotEmpty)
              ProductThumbnailImage(imagePath: widget.item.image!)
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.item.formattedPrice),
                  if (_unitName != null)
                    Text(
                      '单位: $_unitName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
