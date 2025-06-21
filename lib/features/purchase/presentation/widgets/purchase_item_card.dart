import 'package:flutter/material.dart';
import '../../domain/model/purchase_item.dart';

/// 采购单商品项卡片
/// 显示商品信息、价格、数量和金额输入等
class PurchaseItemCard extends StatefulWidget {
  final PurchaseItem item;
  final ValueChanged<PurchaseItem> onUpdate;
  final VoidCallback onRemove;

  const PurchaseItemCard({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<PurchaseItemCard> createState() => _PurchaseItemCardState();
}

class _PurchaseItemCardState extends State<PurchaseItemCard> {
  late TextEditingController _unitPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _amountController;
  DateTime? _selectedProductionDate;
  bool _isUpdatingFromAmount = false; // 标记是否从金额更新其他字段
  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(0),
    );
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(2),
    );
    _selectedProductionDate = widget.item.productionDate;
  }

  @override
  void didUpdateWidget(PurchaseItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当widget更新时，同步更新控制器的值
    if (oldWidget.item.unitPrice != widget.item.unitPrice) {
      _unitPriceController.text = widget.item.unitPrice.toStringAsFixed(2);
    }
    if (oldWidget.item.quantity != widget.item.quantity) {
      _quantityController.text = widget.item.quantity.toStringAsFixed(0);
    }
    if (oldWidget.item.amount != widget.item.amount) {
      _amountController.text = widget.item.amount.toStringAsFixed(2);
    }
    if (oldWidget.item.productionDate != widget.item.productionDate) {
      _selectedProductionDate = widget.item.productionDate;
    }
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final amount = unitPrice * quantity;

    // 更新金额显示（如果不是从金额字段触发的更新）
    if (!_isUpdatingFromAmount) {
      _amountController.text = amount.toStringAsFixed(2);
    }

    final updatedItem = widget.item.copyWith(
      unitPrice: unitPrice,
      quantity: quantity,
      amount: _isUpdatingFromAmount
          ? (double.tryParse(_amountController.text) ?? amount)
          : amount,
      productionDate: _selectedProductionDate,
    );

    widget.onUpdate(updatedItem);
  }

  void _updateFromAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    // 避免除零错误
    if (quantity > 0) {
      final unitPrice = amount / quantity;

      setState(() {
        _isUpdatingFromAmount = true;
        _unitPriceController.text = unitPrice.toStringAsFixed(2);
      });

      final updatedItem = widget.item.copyWith(
        unitPrice: unitPrice,
        quantity: quantity,
        amount: amount,
        productionDate: _selectedProductionDate,
      );

      widget.onUpdate(updatedItem);

      // 重置标记
      _isUpdatingFromAmount = false;
    }
  }

  void _selectProductionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedProductionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // 限制最晚选择日期为当前日期
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null && picked != _selectedProductionDate) {
      setState(() {
        _selectedProductionDate = picked;
      });
      _updateItem();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '请选择日期';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：商品名称 + 单位 + 删除按钮
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.item.unitName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    minimumSize: const Size(32, 32),
                  ),
                  tooltip: '删除',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 第二行：单价、数量、金额输入框
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '单价',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixText: '¥',
                    ),
                    onChanged: (value) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '数量',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '金额',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixText: '¥',
                    ),
                    onChanged: (value) => _updateFromAmount(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 第三行：生产日期选择
            Row(
              children: [
                const Text('生产日期', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectProductionDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatDate(_selectedProductionDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedProductionDate == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
