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

class _ProductInfoDialog extends ConsumerWidget {
  final ScannedProductPayload payload;

  const _ProductInfoDialog({required this.payload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryService = ref.watch(inventoryServiceProvider);
    final product = payload.product;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('货品信息'),
      content: product.id == null
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ProductInfoAction.cancel),
          child: const Text('取消'),
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
    );
  }

  Widget _buildContent(int? stockQuantity) {
    final product = payload.product;

    // 判断是否为基本单位（conversionRate == 1）
    final isBaseUnit = payload.conversionRate == 1;

    // 售价逻辑：
    // - 基本单位：使用 Product 表的 effectivePrice
    // - 辅助单位：使用 UnitProduct 表的 sellingPriceInCents
    int? sellingPriceInCents;
    if (isBaseUnit) {
      sellingPriceInCents = product.effectivePrice?.cents;
    } else {
      sellingPriceInCents = payload.sellingPriceInCents;
    }

    // 计算采购价：优先使用 averageUnitPriceInCents * conversionRate，否则使用 wholesalePriceInCents
    int? purchasePriceInCents;
    String priceSource = '';
    if (payload.averageUnitPriceInCents != null) {
      purchasePriceInCents =
          payload.averageUnitPriceInCents! * payload.conversionRate;
      priceSource = '(库存均价)';
    } else if (payload.wholesalePriceInCents != null) {
      purchasePriceInCents = payload.wholesalePriceInCents;
      priceSource = '(批发价)';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('名称：${product.name}'),
        const SizedBox(height: 8),
        Text('条码：${payload.barcode}'),
        const SizedBox(height: 8),
        Text('单位：${payload.unitName}'),
        const SizedBox(height: 8),
        Text(
          '售价：${sellingPriceInCents != null ? '¥${(sellingPriceInCents / 100).toStringAsFixed(2)}' : '-'}',
        ),
        const SizedBox(height: 8),
        Text(
          '采购价：${purchasePriceInCents != null ? '¥${(purchasePriceInCents / 100).toStringAsFixed(2)}$priceSource' : '-'}',
        ),
        const SizedBox(height: 8),
        Text('库存：${stockQuantity != null ? '$stockQuantity' : '-'}'),
      ],
    );
  }
}
