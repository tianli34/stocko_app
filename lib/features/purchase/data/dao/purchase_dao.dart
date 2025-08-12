import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/purchase_orders_table.dart';
import '../../../../core/database/purchase_order_items_table.dart';
import '../../../../core/database/products_table.dart';
import 'package:rxdart/rxdart.dart';

part 'purchase_dao.g.dart';

/// 采购订单及其所有明细的数据类
class PurchaseOrderWithItems {
  final PurchaseOrdersTableData order;
  final List<PurchaseOrderItemWithDetails> items;

  PurchaseOrderWithItems({required this.order, required this.items});
}

/// 采购订单明细及其关联产品信息的数据类
class PurchaseOrderItemWithDetails {
  final PurchaseOrderItemsTableData item;
  final ProductData product;

  PurchaseOrderItemWithDetails({required this.item, required this.product});
}

/// 采购订单数据访问对象 (DAO)
@DriftAccessor(
  tables: [PurchaseOrdersTable, PurchaseOrderItemsTable, Product],
)
class PurchaseDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(super.db);

  // ===========================================================================
  // 采购订单 (Purchase Order) 操作
  // ===========================================================================

  /// 创建一个新的采购订单，并返回其自增ID
  Future<int> createPurchaseOrder(PurchaseOrdersTableCompanion companion) {
    return into(db.purchaseOrdersTable).insert(companion);
  }

  /// 根据ID获取单个采购订单
  Future<PurchaseOrdersTableData?> getPurchaseOrderById(int orderId) {
    return (select(
      db.purchaseOrdersTable,
    )..where((tbl) => tbl.id.equals(orderId))).getSingleOrNull();
  }

  /// 监听所有采购订单的变化
  Stream<List<PurchaseOrdersTableData>> watchAllPurchaseOrders() {
    return select(db.purchaseOrdersTable).watch();
  }

  /// 删除一个采购订单（需要先删除其所有明细）
  Future<int> deletePurchaseOrder(int orderId) async {
    return transaction(() async {
      // 1. 删除所有关联的明细
      await (delete(
        db.purchaseOrderItemsTable,
      )..where((tbl) => tbl.purchaseOrderId.equals(orderId))).go();
      // 2. 删除订单本身
      return (delete(
        db.purchaseOrdersTable,
      )..where((tbl) => tbl.id.equals(orderId))).go();
    });
  }

  // ===========================================================================
  // 采购订单明细 (Purchase Order Item) 操作
  // ===========================================================================

  /// 为指定的采购订单批量添加明细
  Future<void> addPurchaseOrderItems(
    List<PurchaseOrderItemsTableCompanion> companions,
  ) {
    return batch((batch) {
      batch.insertAll(db.purchaseOrderItemsTable, companions);
    });
  }

  /// 获取指定采购订单的所有明细
  Future<List<PurchaseOrderItemsTableData>> getPurchaseOrderItems(int orderId) {
    return (select(
      db.purchaseOrderItemsTable,
    )..where((tbl) => tbl.purchaseOrderId.equals(orderId))).get();
  }

  // ===========================================================================
  // 组合查询和事务性操作
  // ===========================================================================

  /// 监听一个完整的采购订单（包含其所有明细及产品信息）
  Stream<PurchaseOrderWithItems> watchPurchaseOrderWithItems(int orderId) {
    final orderStream = (select(
      db.purchaseOrdersTable,
    )..where((tbl) => tbl.id.equals(orderId))).watchSingle();

    final itemsStream =
        (select(
          db.purchaseOrderItemsTable,
        )..where((tbl) => tbl.purchaseOrderId.equals(orderId))).join([
          innerJoin(
            db.product,
            db.product.id.equalsExp(db.purchaseOrderItemsTable.productId),
          ),
        ]).watch();

    return orderStream.switchMap((order) {
      return itemsStream.map((rows) {
        final detailedItems = rows.map((row) {
          return PurchaseOrderItemWithDetails(
            item: row.readTable(db.purchaseOrderItemsTable),
            product: row.readTable(db.product),
          );
        }).toList();
        return PurchaseOrderWithItems(order: order, items: detailedItems);
      });
    });
  }

  /// 创建一个完整的采购订单（包括订单头和多个明细项）
  /// 这是一个事务性操作，确保数据一致性
  Future<int> createFullPurchaseOrder({
    required PurchaseOrdersTableCompanion order,
    required List<PurchaseOrderItemsTableCompanion> items,
  }) {
    return transaction(() async {
      // 1. 插入订单头，获取新订单的ID
      final orderId = await into(db.purchaseOrdersTable).insert(order);

      // 2. 为每个明细项设置外键 (purchaseOrderId)
      final itemsWithOrderId = items.map((item) {
        return item.copyWith(purchaseOrderId: Value(orderId));
      }).toList();

      // 3. 批量插入所有明细项
      await batch((batch) {
        batch.insertAll(db.purchaseOrderItemsTable, itemsWithOrderId);
      });

      return orderId;
    });
  }

  // ===========================================================================
  // 工具方法
  // ===========================================================================

  /// 生成新的采购单号
  /// 格式：PUR + YYYYMMDD + 4位序号
  Future<String> generatePurchaseNumber(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10).replaceAll('-', '');
    final prefix = 'PUR$dateStr';

    // 获取当天已有的采购单数量
    final query = selectOnly(db.purchaseOrdersTable)
      ..where(db.purchaseOrdersTable.purchaseOrderNumber.like('$prefix%'))
      ..addColumns([db.purchaseOrdersTable.id.count()]);

    final result = await query.getSingle();
    final count = result.read(db.purchaseOrdersTable.id.count());

    final sequenceNumber = (count ?? 0) + 1;
    return '$prefix${sequenceNumber.toString().padLeft(4, '0')}';
  }
}
