import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/purchases_table.dart';

part 'purchase_dao.g.dart';

/// 采购记录包含货品名称的数据类
class PurchaseWithProductName {
  final PurchasesTableData purchase;
  final String productName;

  PurchaseWithProductName({
    required this.purchase,
    required this.productName,
  });
}

/// 采购数据访问对象 (DAO)
/// 专门负责采购表相关的数据库操作
@DriftAccessor(tables: [PurchasesTable])
class PurchaseDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(super.db);

  /// 添加采购记录
  Future<int> insertPurchase(PurchasesTableCompanion companion) async {
    return await into(db.purchasesTable).insert(companion);
  }

  /// 批量添加采购记录
  Future<void> insertMultiplePurchases(
    List<PurchasesTableCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(db.purchasesTable, companions);
    });
  }

  /// 根据采购单号获取采购记录
  Future<PurchasesTableData?> getPurchaseByNumber(String purchaseNumber) async {
    return await (select(db.purchasesTable)
          ..where((tbl) => tbl.purchaseNumber.equals(purchaseNumber)))
        .getSingleOrNull();
  }

  /// 获取所有采购记录
  Future<List<PurchasesTableData>> getAllPurchases() async {
    return await select(db.purchasesTable).get();
  }

  /// 根据店铺ID获取采购记录
  Future<List<PurchasesTableData>> getPurchasesByShop(String shopId) async {
    return await (select(
      db.purchasesTable,
    )..where((tbl) => tbl.shopId.equals(shopId))).get();
  }

  /// 根据供应商ID获取采购记录
  Future<List<PurchasesTableData>> getPurchasesBySupplier(
    String supplierId,
  ) async {
    return await (select(
      db.purchasesTable,
    )..where((tbl) => tbl.supplierId.equals(supplierId))).get();
  }

  /// 根据产品ID获取采购记录
  Future<List<PurchasesTableData>> getPurchasesByProduct(
    String productId,
  ) async {
    return await (select(
      db.purchasesTable,
    )..where((tbl) => tbl.productId.equals(productId))).get();
  }

  /// 监听所有采购记录变化
  Stream<List<PurchasesTableData>> watchAllPurchases() {
    return select(db.purchasesTable).watch();
  }

  /// 监听所有采购记录变化（包含货品名称）
  Stream<List<PurchaseWithProductName>> watchAllPurchasesWithProductName() {
    final query = select(db.purchasesTable).join([
      leftOuterJoin(db.productsTable, db.productsTable.id.equalsExp(db.purchasesTable.productId)),
    ]);
    
    return query.watch().map((rows) {
      return rows.map((row) {
        final purchase = row.readTable(db.purchasesTable);
        final product = row.readTableOrNull(db.productsTable);
        return PurchaseWithProductName(
          purchase: purchase,
          productName: product?.name ?? '未知货品',
        );
      }).toList();
    });
  }

  /// 更新采购记录
  Future<bool> updatePurchase(PurchasesTableCompanion companion) async {
    final rowsAffected =
        await (update(db.purchasesTable)..where(
              (tbl) =>
                  tbl.purchaseNumber.equals(companion.purchaseNumber.value),
            ))
            .write(companion);
    return rowsAffected > 0;
  }

  /// 删除采购记录
  Future<int> deletePurchase(String purchaseNumber) async {
    print('💾 数据库层：删除采购记录，单号: $purchaseNumber');
    final result = await (delete(
      db.purchasesTable,
    )..where((tbl) => tbl.purchaseNumber.equals(purchaseNumber))).go();
    print('💾 数据库层：删除完成，影响行数: $result');
    return result;
  }

  /// 生成新的采购单号
  /// 格式：PUR + YYYYMMDD + 4位序号
  Future<String> generatePurchaseNumber(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10).replaceAll('-', '');
    final prefix = 'PUR$dateStr';

    // 获取当天已有的采购单数量
    final count =
        await (selectOnly(db.purchasesTable)
              ..where(db.purchasesTable.purchaseNumber.like('$prefix%'))
              ..addColumns([db.purchasesTable.purchaseNumber.count()]))
            .getSingle();

    final sequenceNumber =
        (count.read(db.purchasesTable.purchaseNumber.count()) ?? 0) + 1;
    return '$prefix${sequenceNumber.toString().padLeft(4, '0')}';
  }
}
