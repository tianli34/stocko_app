import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/sales_returns_table.dart';

part 'sales_return_dao.g.dart';

@DriftAccessor(tables: [SalesReturn])
class SalesReturnDao extends DatabaseAccessor<AppDatabase> with _$SalesReturnDaoMixin {
  SalesReturnDao(super.db);

  /// 插入退货单
  Future<int> insertSalesReturn(SalesReturnCompanion companion) {
    return into(db.salesReturn).insert(companion);
  }

  /// 根据ID查找退货单
  Future<SalesReturnData?> findSalesReturnById(int id) {
    return (select(db.salesReturn)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据原销售单ID查找退货单
  Future<List<SalesReturnData>> findSalesReturnsByTransactionId(int transactionId) {
    return (select(db.salesReturn)..where((tbl) => tbl.salesTransactionId.equals(transactionId))).get();
  }

  /// 根据店铺ID查找退货单
  Future<List<SalesReturnData>> findSalesReturnsByShopId(int shopId) {
    return (select(db.salesReturn)..where((tbl) => tbl.shopId.equals(shopId))).get();
  }

  /// 监听所有退货单
  Stream<List<SalesReturnData>> watchAllSalesReturns() {
    return (select(db.salesReturn)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// 更新退货单状态
  Future<bool> updateSalesReturnStatus(int id, String status) {
    return (update(db.salesReturn)..where((tbl) => tbl.id.equals(id)))
        .write(SalesReturnCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ))
        .then((value) => value > 0);
  }
}
