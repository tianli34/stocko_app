import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../repository/data_export_repository.dart';

/// 数据导出仓储 Provider
/// 提供 DataExportRepository 的实例
final dataExportRepositoryProvider = Provider<DataExportRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DataExportRepository(database);
});

/// 获取表记录数量统计的 Provider
final tableCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(dataExportRepositoryProvider);
  return repository.getTableCounts();
});

/// 估算导出数据大小的 Provider
final estimatedExportSizeProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(dataExportRepositoryProvider);
  return repository.estimateExportSize();
});

/// 获取数据库架构版本的 Provider
final databaseSchemaVersionProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(dataExportRepositoryProvider);
  return repository.getDatabaseSchemaVersion();
});

/// 获取所有表名的 Provider
final allTableNamesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(dataExportRepositoryProvider);
  return repository.getAllTableNames();
});