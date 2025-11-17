import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/models/scanned_product_payload.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';

enum ProductInfoAction { sale, purchase, cancel }

Future<ProductInfoAction?> showProductInfoDialog(
  BuildContext context, {
  required ScannedProductPayload payload,
}) async {
  return showDialog<ProductInfoAction>(
    context: context,
    builder: (context) {
      return _ProductInfoDialog(payload: payload);
    },
  );
}

class _ProductInfoDialog extends ConsumerStatefulWidget {
  final ScannedProductPayload payload;

  const _ProductInfoDialog({required this.payload});

  @override
  ConsumerState<_ProductInfoDialog> createState() => _ProductInfoDialogState();
}

class _ProductInfoDialogState extends ConsumerState<_ProductInfoDialog> {
  late TextEditingController _averagePriceController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final averagePrice = widget.payload.averageUnitPriceInCents;
    _averagePriceController = TextEditingController(
      text: averagePrice != null ? (averagePrice / 100).toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _averagePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = ref.watch(inventoryServiceProvider);
    final product = widget.payload.product;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('货品信息'),
      content: SizedBox(
        width: 300,
        child: product.id == null
            ? _buildContent(null)
            : FutureBuilder<List<dynamic>>(
                future: inventoryService.getProductInventory(product.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildContent(null);
                  }
                  // 计算所有店铺的总库存
                  final totalQuantity = snapshot.data!.fold<int>(
                    0,
                    (sum, inventory) => sum + (inventory.quantity as int),
                  );
                  return _buildContent(totalQuantity);
                },
              ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        Wrap(
          spacing: 4,
          alignment: WrapAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ProductInfoAction.cancel),
              child: const Text('取消'),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _saveAveragePrice,
                child: const Text('保存'),
              ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(ProductInfoAction.purchase),
              child: const Text('采购'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ProductInfoAction.sale),
              child: const Text('销售'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveAveragePrice() async {
    final priceText = _averagePriceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的均价')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的价格')),
      );
      return;
    }

    final priceInCents = (price * 100).round();
    final product = widget.payload.product;

    if (product.id != null) {
      try {
        final inventoryService = ref.read(inventoryServiceProvider);
        await inventoryService.updateAverageUnitPrice(
          product.id!,
          priceInCents,
        );
        
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('均价已更新')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败：$e')),
          );
        }
      }
    }
  }

  Widget _buildContent(int? stockQuantity) {
    final product = widget.payload.product;

    // 判断是否为基本单位（conversionRate == 1）
    final isBaseUnit = widget.payload.conversionRate == 1;

    // 售价逻辑：
    // - 基本单位：使用 Product 表的 effectivePrice
    // - 辅助单位：使用 UnitProduct 表的 sellingPriceInCents
    int? sellingPriceInCents;
    if (isBaseUnit) {
      sellingPriceInCents = product.effectivePrice?.cents;
    } else {
      sellingPriceInCents = widget.payload.sellingPriceInCents;
    }

    // 计算采购价：优先使用 averageUnitPriceInCents * conversionRate，否则使用 wholesalePriceInCents
    int? purchasePriceInCents;
    String priceSource = '';
    if (widget.payload.averageUnitPriceInCents != null) {
      purchasePriceInCents =
          widget.payload.averageUnitPriceInCents! * widget.payload.conversionRate;
      priceSource = '(库存均价)';
    } else if (widget.payload.wholesalePriceInCents != null) {
      purchasePriceInCents = widget.payload.wholesalePriceInCents;
      priceSource = '(批发价)';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('名称：${product.name}'),
        const SizedBox(height: 8),
        Text('条码：${widget.payload.barcode}'),
        const SizedBox(height: 8),
        Text('单位：${widget.payload.unitName}'),
        const SizedBox(height: 8),
        Text(
          '售价：${sellingPriceInCents != null ? '¥${(sellingPriceInCents / 100).toStringAsFixed(2)}' : '-'}',
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('采购价：'),
            if (_isEditing)
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _averagePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    prefixText: '¥',
                  ),
                ),
              )
            else
              Flexible(
                child: Text(
                  purchasePriceInCents != null
                      ? '¥${(purchasePriceInCents / 100).toStringAsFixed(2)}$priceSource'
                      : '-',
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    // 取消编辑时恢复原值
                    final averagePrice = widget.payload.averageUnitPriceInCents;
                    _averagePriceController.text = averagePrice != null
                        ? (averagePrice / 100).toStringAsFixed(2)
                        : '';
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('库存：${stockQuantity != null ? '$stockQuantity' : '-'}'),
      ],
    );
  }
}
