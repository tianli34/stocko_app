import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/sales_return_items_table.dart';

part 'sales_return_item_dao.g.dart';

@DriftAccessor(tables: [SalesReturnItem])
class SalesReturnItemDao extends DatabaseAccessor<AppDatabase> with _$SalesReturnItemDaoMixin {
  SalesReturnItemDao(super.db);

  /// 插入退货明细
  Future<int> insertSalesReturnItem(SalesReturnItemCompanion companion) {
    return into(db.salesReturnItem).insert(companion);
  }

  /// 根据退货单ID查找明细
  Future<List<SalesReturnItemData>> findItemsBySalesReturnId(int salesReturnId) {
    return (select(db.salesReturnItem)..where((tbl) => tbl.salesReturnId.equals(salesReturnId))).get();
  }

  /// 根据原销售明细ID查找已退货数量
  Future<int> getReturnedQuantityByTransactionItemId(int transactionItemId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(quantity), 0) as total FROM sales_return_item WHERE sales_transaction_item_id = ?',
      variables: [Variable.withInt(transactionItemId)],
    ).getSingle();
    return result.read<int>('total');
  }

  /// 根据原销售单ID获取所有已退货商品的数量映射
  Future<Map<int, int>> getReturnedQuantitiesByTransactionId(int transactionId) async {
    final result = await customSelect(
      '''
      SELECT sri.sales_transaction_item_id, SUM(sri.quantity) as total_returned
      FROM sales_return_item sri
      INNER JOIN sales_return sr ON sri.sales_return_id = sr.id
      WHERE sr.sales_transaction_id = ? AND sr.status != 'cancelled'
      GROUP BY sri.sales_transaction_item_id
      ''',
      variables: [Variable.withInt(transactionId)],
    ).get();
    
    final map = <int, int>{};
    for (final row in result) {
      final itemId = row.read<int?>('sales_transaction_item_id');
      if (itemId != null) {
        map[itemId] = row.read<int>('total_returned');
      }
    }
    return map;
  }
}
