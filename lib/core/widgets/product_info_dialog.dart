import 'package:flutter/material.dart';
import 'package:stocko_app/core/models/scanned_product_payload.dart';

enum ProductInfoAction { sale, purchase, cancel }

Future<ProductInfoAction?> showProductInfoDialog(
  BuildContext context, {
  required ScannedProductPayload payload,
}) async {
  final product = payload.product;
  final price = product.effectivePrice; // 可能为 null

  return showDialog<ProductInfoAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('货品信息'),
        content: Column(
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
              '售价：${price != null ? '¥${(price.cents / 100).toStringAsFixed(2)}' : '-'}',
            ),
            const SizedBox(height: 8),
            Text(
              '采购价：${payload.averageUnitPriceInCents != null ? '¥${(payload.averageUnitPriceInCents! / 100).toStringAsFixed(2)}' : '-'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(ProductInfoAction.cancel),
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
    },
  );
}
