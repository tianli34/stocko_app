import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../application/provider/sale_list_provider.dart';
import '../../domain/model/sale_cart_item.dart';

/// 销售单商品项卡片
/// 显示商品信息、价格、数量和金额输入等
class SaleItemCard extends ConsumerStatefulWidget {
  final String itemId;
  final FocusNode? quantityFocusNode;
  // 新增：允许外部传入售价输入框的 FocusNode，用于跨卡片焦点链路
  final FocusNode? sellingPriceFocusNode;
  final VoidCallback? onSubmitted;
  final bool showPriceInfo;

  const SaleItemCard({
    required super.key,
    required this.itemId,
    this.quantityFocusNode,
    this.sellingPriceFocusNode,
    this.onSubmitted,
    this.showPriceInfo = true,
  });

  @override
  ConsumerState<SaleItemCard> createState() => _SaleItemCardState();
}

class _SaleItemCardState extends ConsumerState<SaleItemCard> {
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  final _sellingPriceFocusNode = FocusNode();

  // 统一获取当前使用的售价 FocusNode（外部优先，其次内部）
  FocusNode get _priceNode => widget.sellingPriceFocusNode ?? _sellingPriceFocusNode;


  void _onSellingPriceFocusChange() {
    if (_priceNode.hasFocus) {
      _sellingPriceController.clear();
    } else {
      if (_sellingPriceController.text.isEmpty) {
        final item = ref
            .read(saleListProvider)
            .firstWhere((it) => it.id == widget.itemId);
    // 显示为元（分/100）
    _sellingPriceController.text =
      (item.sellingPriceInCents / 100).toStringAsFixed(2);
      }
    }
  }

  void _onQuantityFocusChange() {
    if (widget.quantityFocusNode?.hasFocus == true) {
      _quantityController.clear();
    } else {
      if (_quantityController.text.isEmpty) {
        final item = ref
            .read(saleListProvider)
            .firstWhere((it) => it.id == widget.itemId);
        _quantityController.text = item.quantity.toStringAsFixed(0);
      }
    }
  }


  @override
  void initState() {
    super.initState();
  _priceNode.addListener(_onSellingPriceFocusChange);
    widget.quantityFocusNode?.addListener(_onQuantityFocusChange);
  }

  @override
  void didUpdateWidget(SaleItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantityFocusNode != oldWidget.quantityFocusNode) {
      oldWidget.quantityFocusNode?.removeListener(_onQuantityFocusChange);
      widget.quantityFocusNode?.addListener(_onQuantityFocusChange);
    }
    if (widget.sellingPriceFocusNode != oldWidget.sellingPriceFocusNode) {
      // 切换外部售价 FocusNode 时，迁移监听
      (oldWidget.sellingPriceFocusNode ?? _sellingPriceFocusNode)
          .removeListener(_onSellingPriceFocusChange);
      _priceNode.addListener(_onSellingPriceFocusChange);
    }
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _quantityController.dispose();
  // 仅移除监听；仅销毁内部节点
  (widget.sellingPriceFocusNode ?? _sellingPriceFocusNode)
    .removeListener(_onSellingPriceFocusChange);
  _sellingPriceFocusNode.dispose();
    widget.quantityFocusNode?.removeListener(_onQuantityFocusChange);
    super.dispose();
  }

  void _updateItem(SaleCartItem item) {
  // 将输入的小数价格（元）转换为分
  final String priceText = _sellingPriceController.text.trim();
  final sellingPriceInCents = ((double.tryParse(priceText) ?? 0) * 100).round();
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final amount = sellingPriceInCents / 100 * quantity;

    final updatedItem = item.copyWith(
      sellingPriceInCents: sellingPriceInCents,
      quantity: quantity.toDouble(),
      amount: amount,
    );

    ref.read(saleListProvider.notifier).updateItem(updatedItem);
  }



  @override
  Widget build(BuildContext context) {
    final item = ref.watch(
      saleListProvider.select(
        (items) => items.firstWhere((it) => it.id == widget.itemId),
      ),
    );

  if (!_priceNode.hasFocus &&
    _sellingPriceController.text !=
      (item.sellingPriceInCents / 100).toStringAsFixed(2)) {
    // 同步控制器文本为元（分/100）
    _sellingPriceController.text =
      (item.sellingPriceInCents / 100).toStringAsFixed(2);
    }
    if (widget.quantityFocusNode?.hasFocus == false &&
        _quantityController.text != item.quantity.toStringAsFixed(0)) {
      _quantityController.text = item.quantity.toStringAsFixed(0);
    }

    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(3),
            child: Consumer(
              builder: (context, ref, _) {
                final productAsync =
                    ref.watch(productByIdProvider(item.productId));

                return productAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => const SizedBox(
                    height: 80,
                    child: Center(
                        child: Icon(Icons.error, color: Colors.red, size: 30)),
                  ),
                  data: (product) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                            widget.onSubmitted?.call(),
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
                                          const Text('售价',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller:
                                                  _sellingPriceController,
                                              focusNode: _priceNode,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              textInputAction: TextInputAction.next,
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
                                              onFieldSubmitted: (value) {
                                                // 价格回车后，先跳到同卡片的数量；若无数量节点，则交给父层处理
                                                if (widget.quantityFocusNode != null) {
                                                  widget.quantityFocusNode!.requestFocus();
                                                } else {
                                                  widget.onSubmitted?.call();
                                                }
                                              },
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
                                              onFieldSubmitted: (value) =>
                                                  widget.onSubmitted?.call(),
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
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0),
                                                child: Text(
                                                  '¥${item.amount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
                  ref.read(saleListProvider.notifier).removeItem(widget.itemId),
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