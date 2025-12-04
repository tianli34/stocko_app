import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/models/scanned_product_payload.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/product/data/repository/product_unit_repository.dart';
import 'package:stocko_app/features/product/data/repository/unit_repository.dart';

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
    final averagePrice = widget.payload.averageUnitPriceInSis;
    _averagePriceController = TextEditingController(
      text: averagePrice != null ? (averagePrice / 100).toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _averagePriceController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getProductInventoryWithUnits(int productId) async {
    final inventoryService = ref.read(inventoryServiceProvider);
    final inventories = await inventoryService.getProductInventory(productId);
    
    final totalQuantity = inventories.fold<int>(
      0,
      (sum, inventory) => sum + (inventory.quantity as int),
    );

    try {
      final productUnitRepository = ref.read(productUnitRepositoryProvider);
      final unitRepository = ref.read(unitRepositoryProvider);
      final allProductUnits = await productUnitRepository.getProductUnitsByProductId(productId);
      
      if (allProductUnits.isNotEmpty) {
        final largestUnit = allProductUnits.reduce((a, b) => 
          a.conversionRate > b.conversionRate ? a : b
        );
        
        if (largestUnit.conversionRate > 1) {
          final largestUnitData = await unitRepository.getUnitById(largestUnit.unitId);
          final baseUnitData = await unitRepository.getUnitById(widget.payload.product.baseUnitId);
          return {
            'totalQuantity': totalQuantity,
            'largestUnitConversionRate': largestUnit.conversionRate,
            'largestUnitName': largestUnitData?.name,
            'baseUnitName': baseUnitData?.name,
          };
        }
      }
    } catch (e) {
      // 如果获取单位失败，只返回总数量
    }

    return {
      'totalQuantity': totalQuantity,
      'largestUnitConversionRate': null,
      'largestUnitName': null,
      'baseUnitName': null,
    };
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
            ? _buildContent(null, null, null, null)
            : FutureBuilder<Map<String, dynamic>>(
                future: _getProductInventoryWithUnits(product.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildContent(null, null, null, null);
                  }
                  final data = snapshot.data!;
                  return _buildContent(
                    data['totalQuantity'] as int?,
                    data['largestUnitConversionRate'] as int?,
                    data['largestUnitName'] as String?,
                    data['baseUnitName'] as String?,
                  );
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

  Widget _buildContent(int? stockQuantity, int? largestUnitConversionRate, String? largestUnitName, String? baseUnitName) {
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

    // 计算采购价：优先使用 averageUnitPriceInSis * conversionRate，否则使用 wholesalePriceInCents
    int? purchasePriceInCents;
    String priceSource = '';
    if (widget.payload.averageUnitPriceInSis != null) {
      purchasePriceInCents =
          ((widget.payload.averageUnitPriceInSis! / 1000) * widget.payload.conversionRate).round();
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
                    final averagePrice = widget.payload.averageUnitPriceInSis;
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
        Row(
          children: [
            const Text('库存：'),
            if (stockQuantity != null)
              _buildStockDisplay(stockQuantity, largestUnitConversionRate, largestUnitName, baseUnitName)
            else
              const Text('-'),
          ],
        ),
      ],
    );
  }

  Widget _buildStockDisplay(int quantity, int? largestUnitConversionRate, String? largestUnitName, String? baseUnitName) {
    final displayBaseUnitName = baseUnitName ?? widget.payload.unitName;
    
    if (largestUnitConversionRate != null && largestUnitConversionRate > 1) {
      final largeUnitQty = quantity ~/ largestUnitConversionRate;
      final baseUnitQty = quantity % largestUnitConversionRate;
      
      if (largeUnitQty > 0 && baseUnitQty > 0) {
        return Row(
          children: [
            Text(
              '$largeUnitQty',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              largestUnitName ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '$baseUnitQty',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              displayBaseUnitName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      } else if (largeUnitQty > 0) {
        return Row(
          children: [
            Text(
              '$largeUnitQty',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              largestUnitName ?? displayBaseUnitName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      }
    }
    return Row(
      children: [
        Text(
          '$quantity',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          displayBaseUnitName,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
