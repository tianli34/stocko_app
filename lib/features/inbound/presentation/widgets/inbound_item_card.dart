import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../../core/widgets/custom_date_picker.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../application/provider/inbound_list_provider.dart';

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

  void _onUnitPriceFocusChange() {
    if (_unitPriceFocusNode.hasFocus) {
      // 获取焦点时清空，方便重新输入
      _unitPriceController.clear();
    } else {
      // 失去焦点时，如果为空，则恢复为原来的值
      if (_unitPriceController.text.isEmpty) {
        final item = ref
            .read(inboundListProvider)
            .firstWhere((it) => it.id == widget.itemId);
        _unitPriceController.text = (item.unitPriceInCents / 100).toStringAsFixed(2);
      }
    }
  }

  void _onQuantityFocusChange() {
    if (widget.quantityFocusNode?.hasFocus == true) {
      _quantityController.clear();
    } else {
      if (_quantityController.text.isEmpty) {
        final item = ref
            .read(inboundListProvider)
            .firstWhere((it) => it.id == widget.itemId);
        _quantityController.text = item.quantity.toStringAsFixed(0);
      }
    }
  }

  void _onAmountFocusChange() {
    if (widget.amountFocusNode?.hasFocus == true) {
      _amountController.clear();
    } else {
      if (_amountController.text.isEmpty) {
        final item = ref
            .read(inboundListProvider)
            .firstWhere((it) => it.id == widget.itemId);
        _amountController.text = (item.amountInCents / 100).toStringAsFixed(2);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 监听器在initState中添加
    _unitPriceFocusNode.addListener(_onUnitPriceFocusChange);
    widget.quantityFocusNode?.addListener(_onQuantityFocusChange);
    widget.amountFocusNode?.addListener(_onAmountFocusChange);
  }

  @override
  void didUpdateWidget(InboundItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果FocusNode实例发生变化，需要重新添加监听器
    if (widget.quantityFocusNode != oldWidget.quantityFocusNode) {
      oldWidget.quantityFocusNode?.removeListener(_onQuantityFocusChange);
      widget.quantityFocusNode?.addListener(_onQuantityFocusChange);
    }
    if (widget.amountFocusNode != oldWidget.amountFocusNode) {
      oldWidget.amountFocusNode?.removeListener(_onAmountFocusChange);
      widget.amountFocusNode?.addListener(_onAmountFocusChange);
    }
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _unitPriceFocusNode.removeListener(_onUnitPriceFocusChange);
    _unitPriceFocusNode.dispose(); // 清理本地FocusNode
    widget.quantityFocusNode?.removeListener(_onQuantityFocusChange);
    widget.amountFocusNode?.removeListener(_onAmountFocusChange);
    super.dispose();
  }

  void _updateItem(InboundItemState item, {DateTime? newProductionDate}) {
    final unitPrice = (double.tryParse(_unitPriceController.text) ?? 0.0) * 100;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final amount = unitPrice * quantity / 100;

    if (!_isUpdatingFromAmount) {
      _amountController.text = (amount / 100).toStringAsFixed(2);
    }

    final updatedItem = item.copyWith(
      unitPriceInCents: unitPrice.toInt(),
      quantity: quantity,
      productionDate: newProductionDate ?? item.productionDate,
    );

    ref.read(inboundListProvider.notifier).updateItem(updatedItem);
  }

  void _updateFromAmount(InboundItemState item) {
    final amount = (double.tryParse(_amountController.text) ?? 0.0) * 100;
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (quantity > 0) {
      final unitPriceInCents = amount / quantity;

      _isUpdatingFromAmount = true;
      _unitPriceController.text = (unitPriceInCents / 100).toStringAsFixed(2);

      final updatedItem = item.copyWith(
        unitPriceInCents: unitPriceInCents.toInt(),
        quantity: quantity,
      );

      ref.read(inboundListProvider.notifier).updateItem(updatedItem);

      _isUpdatingFromAmount = false;
    }
  }

  Future<void> _selectProductionDate(InboundItemState item) async {
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
        _unitPriceController.text != (item.unitPriceInCents / 100).toStringAsFixed(2)) {
      _unitPriceController.text = (item.unitPriceInCents / 100).toStringAsFixed(2);
    }
    if (widget.quantityFocusNode?.hasFocus == false &&
        _quantityController.text != item.quantity.toStringAsFixed(0)) {
      _quantityController.text = item.quantity.toStringAsFixed(0);
    }
    if (widget.amountFocusNode?.hasFocus == false &&
        !_isUpdatingFromAmount &&
        _amountController.text != (item.amountInCents / 100).toStringAsFixed(2)) {
      _amountController.text = (item.amountInCents / 100).toStringAsFixed(2);
    }
    // --------------------------

    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(3),
            child: Consumer(
              builder: (context, ref, _) {
                // 将product provider的监听提升到顶层，以便在多个地方共享其状态
                final productAsync =
                    ref.watch(productByIdProvider(item.productId));

                return productAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => SizedBox(
                    height: 80,
                    child: Center(
                        child: Icon(Icons.error, color: Colors.red, size: 30)),
                  ),
                  data: (product) {
                    // 根据产品是否需要批次管理，决定日期选择器是否可见
                    final bool isDatePickerVisible =
                        product?.enableBatchManagement == true;

                    // 根据日期选择器的可见性，动态调整垂直对齐方式
                    return Row(
                      crossAxisAlignment: isDatePickerVisible
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        // --- 左侧图片 ---
                        SizedBox(
                          width: 60,
                          height: 80,
                          child: product?.image?.isNotEmpty == true
                              ? CachedImageWidget(
                                  imagePath: product!.image!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),

                        // --- 右侧信息列 ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 第一行：商品名称 + (数量) + 单位
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
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
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: false,
                                        ),
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          hintText: '数量',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (value) =>
                                            _updateItem(item),
                                        onFieldSubmitted: (value) =>
                                            widget.onAmountSubmitted?.call(),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text(
                                    item.unitName,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 55),
                                ],
                              ),

                              const SizedBox(height: 3),

                              // 第二行：价格、数量、金额 (仅采购入库)
                              if (widget.showPriceInfo)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('单价',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller:
                                                  _unitPriceController,
                                              focusNode: _unitPriceFocusNode,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration:
                                                  const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets
                                                    .symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                prefixText: '¥',
                                              ),
                                              onChanged: (value) =>
                                                  _updateItem(item),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox.square(dimension: 12.0),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('数量',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller:
                                                  _quantityController,
                                              focusNode:
                                                  widget.quantityFocusNode,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: false,
                                              ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration:
                                                  const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets
                                                    .symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                              ),
                                              onChanged: (value) =>
                                                  _updateItem(item),
                                              onFieldSubmitted: (value) {
                                                if (widget.amountFocusNode !=
                                                    null) {
                                                  widget.amountFocusNode!
                                                      .requestFocus();
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    _amountController
                                                        .clear();
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox.square(dimension: 12.0),
                                    Expanded(
                                      flex: 7,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('金额',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller: _amountController,
                                              focusNode:
                                                  widget.amountFocusNode,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              textInputAction:
                                                  TextInputAction.done,
                                              decoration:
                                                  const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets
                                                    .symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                prefixText: '¥',
                                              ),
                                              onChanged: (value) =>
                                                  _updateFromAmount(item),
                                              onFieldSubmitted: (value) =>
                                                  widget.onAmountSubmitted
                                                      ?.call(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 6),

                              // 第三行：生产日期 (条件显示)
                              if (isDatePickerVisible)
                                Row(
                                  children: [
                                    const Text(
                                      '生产日期',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () =>
                                            _selectProductionDate(item),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                _formatDate(
                                                    item.productionDate),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: item.productionDate ==
                                                          null
                                                      ? Colors.grey[600]
                                                      : Colors.black,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
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
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: -15,
            right: -15,
            child: IconButton(
              onPressed: () =>
                  ref.read(inboundListProvider.notifier).removeItem(widget.itemId),
              icon: const Icon(Icons.close, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
              tooltip: '删除',
            ),
          ),
        ],
      ),
    );
  }
}
