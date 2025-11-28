import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../sale/domain/model/sale_cart_item.dart';
import '../../../../core/database/database.dart';

/// 出库类型枚举
enum OutboundType {
  /// 销售出库（结账）
  sale,
  /// 赊账出库
  credit,
  /// 非售出库（报损、调拨、赠送等）
  nonSale,
}

/// 统一出库服务
/// 
/// 处理所有类型的出库操作，包括：
/// - 销售出库（结账）
/// - 赊账出库
/// - 非售出库（报损、调拨、赠送等）
class OutboundService {
  OutboundService({
    required this.ref,
    required this.inventoryService,
  });

  final Ref ref;
  final InventoryService inventoryService;

  /// 执行非售出库操作
  ///
  /// [shopId] - 店铺ID
  /// [items] - 出库货品列表
  /// [reason] - 出库原因
  Future<String> processNonSaleOutbound({
    required int shopId,
    required List<SaleCartItem> items,
    required String reason,
  }) async {
    final now = DateTime.now();
    final db = ref.read(appDatabaseProvider);

    return await db.transaction<String>(() async {
      // 1. 创建出库单
      final receiptId = await db.outboundReceiptDao.insertOutboundReceipt(
        OutboundReceiptCompanion(
          shopId: drift.Value(shopId),
          reason: drift.Value(reason),
        ),
      );

      // 2. 合并明细（将数量换算为基本单位）
      final Map<(int, int, int?), int> merged = {};
      for (final item in items) {
        final unitProduct = await db.productUnitDao.getUnitProductByProductAndUnit(
          item.productId,
          item.unitId,
        );
        if (unitProduct == null) {
          throw Exception('未找到产品${item.productName}的单位配置');
        }
        
        final key = (
          unitProduct.id,
          item.productId,
          item.batchId != null ? int.tryParse(item.batchId!) : null,
        );
        final baseUnitQuantity = (item.quantity * item.conversionRate).toInt();
        merged.update(key, (q) => q + baseUnitQuantity, ifAbsent: () => baseUnitQuantity);
      }

      // 3. 批量写入出库明细
      if (merged.isNotEmpty) {
        final companions = merged.entries.map((e) {
          final upid = e.key.$1;
          final bid = e.key.$3;
          final qty = e.value;
          return OutboundItemCompanion(
            receiptId: drift.Value(receiptId),
            unitProductId: drift.Value(upid),
            quantity: drift.Value(qty),
            batchId: bid != null ? drift.Value(bid) : const drift.Value.absent(),
          );
        }).toList(growable: false);
        await db.batch((batch) {
          batch.insertAll(db.outboundItem, companions);
        });
      }

      // 4. 扣减库存
      for (final item in items) {
        final baseUnitQuantity = (item.quantity * item.conversionRate).toInt();
        
        final ok = await inventoryService.outbound(
          productId: item.productId,
          shopId: shopId,
          quantity: baseUnitQuantity,
          batchId: item.batchId != null ? int.tryParse(item.batchId!) : null,
          time: now,
        );
        
        if (!ok) {
          final batchInfo = item.batchId != null ? ', batch ${item.batchId}' : '';
          throw StateError(
            'Inventory operation failed for product ${item.productId} in shop $shopId$batchInfo. No inventory record found.',
          );
        }
      }

      final receiptNumber = 'OUT-${now.millisecondsSinceEpoch}';
      print('Non-sale outbound successful. Receipt number: $receiptNumber, reason: $reason');
      return receiptNumber;
    });
  }
}

final outboundServiceProvider = Provider<OutboundService>((ref) {
  final inventoryService = ref.watch(inventoryServiceProvider);
  return OutboundService(
    ref: ref,
    inventoryService: inventoryService,
  );
});
