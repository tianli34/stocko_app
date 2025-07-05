import 'package:flutter/material.dart';
import '../../../features/product/domain/model/product.dart';
import 'product_item.dart';

// 全局变量来管理活跃的商品项
class ProductItemManager {
  static void Function()? _hideAllActions;
  
  static void setHideAllActions(void Function() callback) {
    _hideAllActions = callback;
  }
  
  static void hideAllActions() {
    _hideAllActions?.call();
  }
}

class ProductList extends StatefulWidget {
  final List<Product> data;
  final String mode;
  final List<dynamic> selectedIds;
  final Function(List<dynamic>)? onSelectionChange;
  final Function(Product)? onEdit;
  final Function(Product)? onDelete;

  const ProductList({
    super.key,
    required this.data,
    this.mode = 'display',
    this.selectedIds = const [],
    this.onSelectionChange,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {

  void _handleToggleSelect(dynamic id) {
    final newSelectedIds = List<dynamic>.from(widget.selectedIds);
    if (newSelectedIds.contains(id)) {
      newSelectedIds.remove(id);
    } else {
      newSelectedIds.add(id);
    }
    widget.onSelectionChange?.call(newSelectedIds);
  }

  void _handleSelectAll() {
    final allIds = widget.data.map((item) => item.id).toList();
    widget.onSelectionChange?.call(allIds);
  }

  void _handleClearAll() {
    widget.onSelectionChange?.call([]);
  }

  void _hideAllActions() {
    ProductItemManager.hideAllActions();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideAllActions,
      child: Column(
        children: [
          if (widget.mode == 'select')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _handleSelectAll,
                  child: const Text('全选'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleClearAll,
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final item = widget.data[index];
                return ProductItem(
                  key: ValueKey(item.id),
                  item: item,
                  mode: widget.mode,
                  isSelected: widget.selectedIds.contains(item.id),
                  onToggleSelect: widget.mode == 'select' ? _handleToggleSelect : null,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onHideActions: _hideAllActions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}