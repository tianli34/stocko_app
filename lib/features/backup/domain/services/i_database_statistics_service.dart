/// 数据库统计服务接口
/// 提供当前数据库表的统计信息
abstract class IDatabaseStatisticsService {
  /// 获取所有表的记录数统计
  Future<Map<String, int>> getAllTableCounts();
  
  /// 获取指定表的记录数
  Future<int> getTableCount(String tableName);
  
  /// 获取数据库总记录数
  Future<int> getTotalRecordCount();
}