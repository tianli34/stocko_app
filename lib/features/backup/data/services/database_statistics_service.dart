import '../../../../core/database/database.dart';
import '../../domain/services/i_database_statistics_service.dart';

/// 数据库统计服务实现
class DatabaseStatisticsService implements IDatabaseStatisticsService {
  final AppDatabase _database;

  DatabaseStatisticsService(this._database);

  @override
  Future<Map<String, int>> getAllTableCounts() async {
    final Map<String, int> counts = {};
    
    // 定义所有需要统计的表
    final tables = [
      'product',
      'category', 
      'unit',
      'unit_product',
      'shop',
      'supplier',
      'customers',
      'product_batch',
      'stock',
      'inventory_transaction',
      'locations',
      'inbound_receipt',
      'inbound_item',
      'outbound_receipt',
      'outbound_item',
      'purchase_order',
      'purchase_order_item',
      'sales_transaction',
      'sales_transaction_item',
      'barcode',
    ];

    for (final tableName in tables) {
      counts[tableName] = await getTableCount(tableName);
    }

    return counts;
  }

  @override
  Future<int> getTableCount(String tableName) async {
    try {
      final query = 'SELECT COUNT(*) as count FROM $tableName';
      final result = await _database.customSelect(query).getSingle();
      return result.data['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getTotalRecordCount() async {
    final counts = await getAllTableCounts();
    return counts.values.fold<int>(0, (sum, count) => sum + count);
  }
}