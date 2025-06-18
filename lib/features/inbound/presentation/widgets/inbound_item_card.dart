import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/model/inbound_item.dart';

/// 入库项目卡片组件
class InboundItemCard extends StatefulWidget {
  final InboundItem item;
  final Function(InboundItem) onUpdate;
  final VoidCallback onRemove;

  const InboundItemCard({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<InboundItemCard> createState() => _InboundItemCardState();
}

class _InboundItemCardState extends State<InboundItemCard> {
  late TextEditingController _quantityController;
  late DateTime? _selectedProductionDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.inboundQuantity.toString(),
    );
    _selectedProductionDate = widget.item.productionDate;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final updatedItem = widget.item.copyWith(quantity: quantity);
    widget.onUpdate(updatedItem);
  }

  void _selectProductionDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedProductionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedProductionDate = selectedDate;
      });
      final updatedItem = widget.item.copyWith(productionDate: selectedDate);
      widget.onUpdate(updatedItem);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 商品信息和删除按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 商品图片
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.item.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.item.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey, size: 30),
                ),

                const SizedBox(width: 12),

                // 商品信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.item.productName} - ${widget.item.productSpec}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // 采购数和入库数
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 采购数量显示
                          Text(
                            '采购数: ${(widget.item.purchaseQuantity != null && widget.item.purchaseQuantity! > 0) ? widget.item.purchaseQuantity : '--'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 本次入库数量输入
                          Row(
                            children: [
                              const Text(
                                '本次入库*:',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _updateQuantity(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 删除按钮
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
          ), // 生产日期（如果需要的话 - 基于产品是否启用批量管理）
          if (widget.item.productionDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('生产日期:', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _selectProductionDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedProductionDate != null
                                  ? _formatDate(_selectedProductionDate)
                                  : '请选择日期',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedProductionDate != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
