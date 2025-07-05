import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/product/domain/model/product.dart';
import '../../../features/product/application/provider/unit_providers.dart';
import '../../widgets/cached_image_widget.dart';
import 'package:flutter/services.dart';
import 'product_list.dart';

class ProductItem extends ConsumerStatefulWidget {
  final Product item;
  final String mode;
  final bool isSelected;
  final Function(dynamic)? onToggleSelect;
  final Function(Product)? onEdit;
  final Function(Product)? onDelete;
  final VoidCallback? onHideActions;

  const ProductItem({
    super.key,
    required this.item,
    required this.mode,
    required this.isSelected,
    this.onToggleSelect,
    this.onEdit,
    this.onDelete,
    this.onHideActions,
  });

  @override
  ConsumerState<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends ConsumerState<ProductItem> {
  static _ProductItemState? _activeItem;
  bool _showActions = false;
  String? _unitName;
  bool _unitLoaded = false;

  @override
  void initState() {
    super.initState();
    ProductItemManager.setHideAllActions(() {
      _activeItem?.hideActions();
      _activeItem = null;
    });
    _loadUnitName();
  }

  Future<void> _loadUnitName() async {
    print('🔍 产品 ${widget.item.name} 的 unitId: ${widget.item.unitId}');
    if (widget.item.unitId != null && !_unitLoaded) {
      try {
        print('🔍 正在获取单位信息，unitId: ${widget.item.unitId}');
        final unit = await ref.read(unitControllerProvider.notifier).getUnitById(widget.item.unitId!);
        print('🔍 获取到的单位: ${unit?.name}');
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
    } else {
      print('🔍 产品 ${widget.item.name} 没有 unitId 或已加载');
    }
  }

  void hideActions() {
    if (_showActions) {
      setState(() => _showActions = false);
    }
  }

  static void hideAllActions() {
    _activeItem?.hideActions();
    _activeItem = null;
  }



  @override
  void dispose() {
    if (_activeItem == this) {
      _activeItem = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.mode == 'select') {
          widget.onToggleSelect?.call(widget.item.id);
        } else if (widget.mode == 'display') {
          ProductItemManager.hideAllActions();
        }
      },
      onLongPress: () {
        if (widget.mode == 'display') {
          HapticFeedback.mediumImpact();
          // 隐藏其他按钮
          if (_activeItem != null && _activeItem != this) {
            _activeItem!.hideActions();
          }
          setState(() => _showActions = !_showActions);
          _activeItem = _showActions ? this : null;
          print('长按触发，_showActions: $_showActions');
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
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                if (widget.item.image != null && widget.item.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: widget.item.image != null && widget.item.image!.isNotEmpty
                        ? CachedImageWidget(
                            imagePath: widget.item.image!,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
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
            if (_showActions && widget.mode == 'display')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => widget.onEdit?.call(widget.item),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onDelete?.call(widget.item),
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        label: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
