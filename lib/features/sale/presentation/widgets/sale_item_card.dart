import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/application/provider/batch_providers.dart';
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
  // 新增：用于加载批次（按产品+店铺）
  final int? shopId;

  const SaleItemCard({
    required super.key,
    required this.itemId,
    this.quantityFocusNode,
    this.sellingPriceFocusNode,
    this.onSubmitted,
    this.showPriceInfo = true,
    this.shopId,
  });

  @override
  ConsumerState<SaleItemCard> createState() => _SaleItemCardState();
}

class _SaleItemCardState extends ConsumerState<SaleItemCard> {
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  final _sellingPriceFocusNode = FocusNode();

  // 统一获取当前使用的售价 FocusNode（外部优先，其次内部）
  FocusNode get _priceNode =>
      widget.sellingPriceFocusNode ?? _sellingPriceFocusNode;

  void _onSellingPriceFocusChange() {
    if (_priceNode.hasFocus) {
      _sellingPriceController.clear();
    } else {
      if (_sellingPriceController.text.isEmpty) {
        final item = ref
            .read(saleListProvider)
            .firstWhere((it) => it.id == widget.itemId);
        // 显示为元（分/100）
        _sellingPriceController.text = (item.sellingPriceInCents / 100)
            .toStringAsFixed(1);
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
    (widget.sellingPriceFocusNode ?? _sellingPriceFocusNode).removeListener(
      _onSellingPriceFocusChange,
    );
    _sellingPriceFocusNode.dispose();
    widget.quantityFocusNode?.removeListener(_onQuantityFocusChange);
    super.dispose();
  }

  void _updateItem(SaleCartItem item) {
    // 将输入的小数价格（元）转换为分
    final String priceText = _sellingPriceController.text.trim();
    final sellingPriceInCents = ((double.tryParse(priceText) ?? 0) * 100)
        .round();
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final amount = sellingPriceInCents / 100 * quantity;

    final updatedItem = item.copyWith(
      sellingPriceInCents: sellingPriceInCents,
      quantity: quantity.toDouble(),
      amount: amount,
    );

    ref.read(saleListProvider.notifier).updateItem(updatedItem);
  }

  void _updateItemBatch(SaleCartItem item, int? batchId) {
    final updatedItem = item.copyWith(batchId: batchId?.toString());
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
      _sellingPriceController.text = (item.sellingPriceInCents / 100)
          .toStringAsFixed(1);
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
                final productAsync = ref.watch(
                  productByIdProvider(item.productId),
                );

                return productAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(Icons.error, color: Colors.red, size: 30),
                    ),
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

                                  // 批次（生产日期）选择：仅当启用批次管理且存在店铺ID
                                  if (product?.enableBatchManagement == true &&
                                      widget.shopId != null) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 130,
                                      child: Consumer(
                                        builder: (context, ref, __) {
                                          final batchesAsync = ref.watch(
                                            batchesByProductAndShopProvider((
                                              productId: item.productId,
                                              shopId: widget.shopId!,
                                            )),
                                          );
                                          return batchesAsync.when(
                                            loading: () => const SizedBox(
                                              height: 30,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            error: (e, st) => const SizedBox(
                                              height: 30,
                                              child: Center(
                                                child: Icon(
                                                  Icons.error,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                            data: (list) {
                                              // 选项：显示生产日期（按 id 去重，防止出现重复 value）
                                              final options = list;
                                              final uniqueOptions = {
                                                for (final b in options)
                                                  b.id: b,
                                              }.values.toList();
                                              final selectedId = int.tryParse(
                                                item.batchId ?? '',
                                              );

                                              // 若当前选中批次不在新店铺的批次列表中，置空以避免 Dropdown 的断言错误
                                              final isValid =
                                                  selectedId != null &&
                                                  uniqueOptions.any(
                                                    (b) => b.id == selectedId,
                                                  );

                                              // 若无有效选择，则默认使用最早的生产日期
                                              int? defaultId;
                                              if (!isValid &&
                                                  uniqueOptions.isNotEmpty) {
                                                final sortedByDate =
                                                    [...uniqueOptions]..sort(
                                                      (a, b) => a.productionDate
                                                          .compareTo(
                                                            b.productionDate,
                                                          ),
                                                    );
                                                defaultId =
                                                    sortedByDate.first.id;
                                              }

                                              final effectiveValue = isValid
                                                  ? selectedId
                                                  : defaultId;

                                              // 异步将默认值写回（或在切换店铺后修正为有效默认值）
                                              if (!isValid &&
                                                  effectiveValue != null) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      _updateItemBatch(
                                                        item,
                                                        effectiveValue,
                                                      );
                                                    });
                                              }

                                              return DropdownButtonFormField<
                                                int
                                              >(
                                                isDense: true,
                                                value: effectiveValue,
                                                decoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 6,
                                                          ),
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                hint: const Text('生产日期'),
                                                items: uniqueOptions
                                                    .map(
                                                      (b) =>
                                                          DropdownMenuItem<int>(
                                                            value: b.id,
                                                            child: Text(
                                                              // 仅日期部分
                                                              b.productionDate
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(' ')
                                                                  .first,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                    )
                                                    .toList(),
                                                onChanged: (val) {
                                                  _updateItemBatch(item, val);
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // 显示价格信息时的完整行
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
                                          const Text(
                                            '售价',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller:
                                                  _sellingPriceController,
                                              focusNode: _priceNode,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 7,
                                                    ),
                                                // prefixText: '¥',
                                              ),
                                              onChanged: (value) =>
                                                  _updateItem(item),
                                              onFieldSubmitted: (value) {
                                                // 价格回车后，先跳到同卡片的数量；若无数量节点，则交给父层处理
                                                if (widget.quantityFocusNode !=
                                                    null) {
                                                  widget.quantityFocusNode!
                                                      .requestFocus();
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
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '数量',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: TextFormField(
                                              controller: _quantityController,
                                              focusNode:
                                                  widget.quantityFocusNode,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: false,
                                                  ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
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

                                    Padding(
                                      padding: const EdgeInsets.only(top: 24.0),
                                      child: Text(
                                        item.unitName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 22.0),

                                    Expanded(
                                      flex: 7,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '金额',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 27,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                    ),
                                                child: Text(
                                                  '¥${item.amount.toStringAsFixed(1)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              // 不显示价格信息时，仅显示数量和单位
                              if (!widget.showPriceInfo)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '数量:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: TextFormField(
                                        controller: _quantityController,
                                        focusNode: widget.quantityFocusNode,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: false,
                                            ),
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                        ),
                                        onChanged: (value) => _updateItem(item),
                                        onFieldSubmitted: (value) =>
                                            widget.onSubmitted?.call(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.unitName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
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
