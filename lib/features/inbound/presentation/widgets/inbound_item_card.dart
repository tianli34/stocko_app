import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../../core/widgets/custom_date_picker.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../application/provider/inbound_list_provider.dart';
import '../../domain/model/inbound_item.dart';

/// 入库单商品项卡片
/// 显示商品信息、价格、数量和金额输入等
class InboundItemCard extends ConsumerStatefulWidget {
  final String itemId;
  final FocusNode? quantityFocusNode;
  final FocusNode? amountFocusNode;
  final VoidCallback? onAmountSubmitted;
  final bool showPriceInfo;

  const InboundItemCard({
    // 使用ValueKey确保Widget与数据项的正确绑定
    required super.key,
    required this.itemId,
    this.quantityFocusNode,
    this.amountFocusNode,
    this.onAmountSubmitted,
    this.showPriceInfo = true,
  });

  @override
  ConsumerState<InboundItemCard> createState() => _InboundItemCardState();
}

class _InboundItemCardState extends ConsumerState<InboundItemCard> {
  final _unitPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();

  // 为内部管理的文本框创建FocusNode
  final _unitPriceFocusNode = FocusNode();

  bool _isUpdatingFromAmount = false; // 标记是否从金额更新其他字段

  void _onQuantityFocus() {
    if (widget.quantityFocusNode?.hasFocus == true) {
      _quantityController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    // 监听器在initState中添加
    widget.quantityFocusNode?.addListener(_onQuantityFocus);
  }

  @override
  void didUpdateWidget(InboundItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果FocusNode实例发生变化，需要重新添加监听器
    if (widget.quantityFocusNode != oldWidget.quantityFocusNode) {
      oldWidget.quantityFocusNode?.removeListener(_onQuantityFocus);
      widget.quantityFocusNode?.addListener(_onQuantityFocus);
    }
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _unitPriceFocusNode.dispose(); // 清理本地FocusNode
    widget.quantityFocusNode?.removeListener(_onQuantityFocus);
    super.dispose();
  }

  void _updateItem(InboundItem item, {DateTime? newProductionDate}) {
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final amount = unitPrice * quantity;

    if (!_isUpdatingFromAmount) {
      _amountController.text = amount.toStringAsFixed(2);
    }

    final updatedItem = item.copyWith(
      unitPrice: unitPrice,
      quantity: quantity,
      amount: _isUpdatingFromAmount
          ? (double.tryParse(_amountController.text) ?? amount)
          : amount,
      productionDate: newProductionDate ?? item.productionDate,
    );

    ref.read(inboundListProvider.notifier).updateItem(updatedItem);
  }

  void _updateFromAmount(InboundItem item) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    if (quantity > 0) {
      final unitPrice = amount / quantity;

      _isUpdatingFromAmount = true;
      _unitPriceController.text = unitPrice.toStringAsFixed(2);

      final updatedItem = item.copyWith(
        unitPrice: unitPrice,
        quantity: quantity,
        amount: amount,
      );

      ref.read(inboundListProvider.notifier).updateItem(updatedItem);

      _isUpdatingFromAmount = false;
    }
  }

  Future<void> _selectProductionDate(InboundItem item) async {
    final DateTime? picked = await CustomDatePicker.show(
      context: context,
      initialDate: item.productionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: '选择生产日期',
    );

    if (picked != null && picked != item.productionDate) {
      _updateItem(item, newProductionDate: picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '请选择日期';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 订阅单个item的状态，当这个item变化时，只有这个card会重建
    final item = ref.watch(
      inboundListProvider.select(
        (items) => items.firstWhere((it) => it.id == widget.itemId),
      ),
    );

    // --- 同步Controller与State ---
    // 只有在非焦点且文本不同时才更新，避免覆盖用户输入
    if (!_unitPriceFocusNode.hasFocus &&
        _unitPriceController.text != item.unitPrice.toStringAsFixed(2)) {
      _unitPriceController.text = item.unitPrice.toStringAsFixed(2);
    }
    if (widget.quantityFocusNode?.hasFocus == false &&
        _quantityController.text != item.quantity.toStringAsFixed(0)) {
      _quantityController.text = item.quantity.toStringAsFixed(0);
    }
    if (widget.amountFocusNode?.hasFocus == false &&
        !_isUpdatingFromAmount &&
        _amountController.text != item.amount.toStringAsFixed(2)) {
      _amountController.text = item.amount.toStringAsFixed(2);
    }
    // --------------------------

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final productAsync = ref.watch(
                  productByIdProvider(item.productId),
                );
                return productAsync.when(
                  data: (product) {
                    if (product?.image?.isNotEmpty == true) {
                      return SizedBox(
                        width: 60,
                        height: 80,
                        child: CachedImageWidget(
                          imagePath: product!.image!,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const SizedBox(
                      width: 60,
                      height: 80,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    );
                  },
                  error: (e, st) => const SizedBox(
                    width: 60,
                    height: 80,
                    child: Center(
                      child: Icon(Icons.error, color: Colors.red, size: 30),
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 60,
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：商品名称 + 单位 + 删除按钮
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!widget.showPriceInfo) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          height: 30,
                          child: TextFormField(
                            controller: _quantityController,
                            focusNode: widget.quantityFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '数量',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => _quantityController.clear(),
                            onChanged: (value) => _updateItem(item),
                            onFieldSubmitted: (value) =>
                                widget.onAmountSubmitted?.call(),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        item.unitName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => ref
                            .read(inboundListProvider.notifier)
                            .removeItem(widget.itemId),
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          minimumSize: const Size(24, 24),
                          padding: EdgeInsets.zero,
                        ),
                        tooltip: '删除',
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Second row: Price, Quantity, Amount (only for purchase inbound)
                  if (widget.showPriceInfo)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 27, // Set fixed height
                            child: TextFormField(
                              controller: _unitPriceController,
                              focusNode: _unitPriceFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: '单价',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                prefixText: '¥',
                              ),
                              onTap: () => _unitPriceController.clear(),
                              onChanged: (value) => _updateItem(item),
                            ),
                          ),
                        ),
                        const SizedBox.square(dimension: 12.0),
                        Expanded(
                          child: SizedBox(
                            height: 27, // Set fixed height
                            child: TextFormField(
                              controller: _quantityController,
                              focusNode: widget.quantityFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: '数量',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                              ),
                              onTap: () => _quantityController.clear(),
                              onChanged: (value) => _updateItem(item),
                              onFieldSubmitted: (value) {
                                if (widget.amountFocusNode != null) {
                                  widget.amountFocusNode!.requestFocus();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _amountController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox.square(dimension: 12.0),
                        Expanded(
                          child: SizedBox(
                            height: 27, // Set fixed height
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: widget.amountFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: '金额',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                prefixText: '¥',
                              ),
                              onTap: () => _amountController.clear(),
                              onChanged: (value) => _updateFromAmount(item),
                              onFieldSubmitted: (value) =>
                                  widget.onAmountSubmitted?.call(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // 第三行：生产日期选择（根据enableBatchManagement决定是否显示）
                  Consumer(
                    builder: (context, ref, child) {
                      final productAsync = ref.watch(
                        productByIdProvider(item.productId),
                      );
                      return productAsync.when(
                        data: (product) {
                          if (product?.enableBatchManagement == true) {
                            return Row(
                              children: [
                                const Text(
                                  '生产日期',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectProductionDate(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _formatDate(item.productionDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: item.productionDate == null
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
                            );
                          }
                          return const SizedBox.shrink(); // 不显示生产日期选择器
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
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
