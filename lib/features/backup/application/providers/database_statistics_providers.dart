import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/database/database.dart';
import '../../domain/services/i_database_statistics_service.dart';
import '../../data/services/database_statistics_service.dart';

/// 数据库统计服务提供者
final databaseStatisticsServiceProvider = Provider<IDatabaseStatisticsService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DatabaseStatisticsService(database);
});

/// 所有表统计数据提供者
final allTableCountsProvider = FutureProvider<Map<String, int>>((ref) {
  final service = ref.watch(databaseStatisticsServiceProvider);
  return service.getAllTableCounts();
});

/// 数据库总记录数提供者
final totalRecordCountProvider = FutureProvider<int>((ref) {
  final service = ref.watch(databaseStatisticsServiceProvider);
  return service.getTotalRecordCount();
});