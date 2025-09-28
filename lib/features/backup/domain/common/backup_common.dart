/// 取消令牌，用于取消长时间运行的操作
class CancelToken {
  bool _isCancelled = false;

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 取消操作
  void cancel() {
    _isCancelled = true;
  }

  /// 检查是否已取消，如果已取消则抛出异常
  void throwIfCancelled() {
    if (_isCancelled) {
      throw const BackupCancelledException();
    }
  }
}

/// 备份取消异常
class BackupCancelledException implements Exception {
  final String message;

  const BackupCancelledException([this.message = '备份操作已取消']);

  @override
  String toString() => 'BackupCancelledException: $message';
}

/// 恢复取消异常
class RestoreCancelledException implements Exception {
  final String message;

  const RestoreCancelledException([this.message = '恢复操作已取消']);

  @override
  String toString() => 'RestoreCancelledException: $message';
}



/// 数据冲突信息
class DataConflict {
  final String tableName;
  final String primaryKey;
  final dynamic primaryKeyValue;
  final Map<String, dynamic> existingRecord;
  final Map<String, dynamic> newRecord;
  final ConflictResolution resolution;

  const DataConflict({
    required this.tableName,
    required this.primaryKey,
    required this.primaryKeyValue,
    required this.existingRecord,
    required this.newRecord,
    required this.resolution,
  });
}

/// 数据冲突解决策略
enum ConflictResolution {
  /// 跳过新记录，保留现有记录
  skip,
  /// 用新记录覆盖现有记录
  overwrite,
  /// 合并记录（优先使用新记录的非空值）
  merge,
}

/// 批处理结果
class BatchResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final List<DataConflict> conflicts;

  const BatchResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.conflicts,
  });

  int get totalCount => successCount + failureCount;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;
}