import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/sales_transaction_items_table.dart';

part 'sales_transaction_item_dao.g.dart';

@DriftAccessor(tables: [SalesTransactionItemsTable])
class SalesTransactionItemDao extends DatabaseAccessor<AppDatabase> with _$SalesTransactionItemDaoMixin {
  SalesTransactionItemDao(super.db);

  /// 插入一个销售交易项目
  Future<int> insertSalesTransactionItem(SalesTransactionItemsTableCompanion companion) {
    return into(db.salesTransactionItemsTable).insert(companion);
  }

  /// 批量插入销售交易项目
  Future<void> insertSalesTransactionItems(List<SalesTransactionItemsTableCompanion> companions) {
    return batch((batch) {
      batch.insertAll(db.salesTransactionItemsTable, companions);
    });
  }

  /// 根据交易ID查找销售项目
  Future<List<SalesTransactionItemsTableData>> findSalesTransactionItemsByTransactionId(String transactionId) {
    print('🔍 [DEBUG] DAO: findSalesTransactionItemsByTransactionId called with: $transactionId (type: ${transactionId.runtimeType})');
    print('🔍 [DEBUG] DAO: transactionId content: "$transactionId"');
    
    final parsedId = int.tryParse(transactionId);
    print('🔍 [DEBUG] DAO: Parsed ID: $parsedId, type: ${parsedId?.runtimeType}');
    print('🔍 [DEBUG] DAO: Parsed ID == null: ${parsedId == null}');
    
    if (parsedId == null) {
      print('🔍 [ERROR] DAO: Failed to parse transactionId: $transactionId');
      throw Exception('无法解析交易ID: $transactionId');
    }
    
    return (select(db.salesTransactionItemsTable)..where((tbl) => tbl.salesTransactionId.equals(parsedId))).get();
  }
}