/// 取消令牌，用于取消长时间运行的操作
class CancelToken {
  bool _isCancelled = false;

  /// 检查是否已被取消
  bool get isCancelled => _isCancelled;

  /// 取消操作
  void cancel() {
    _isCancelled = true;
  }

  /// 如果已取消则抛出异常
  void throwIfCancelled() {
    if (_isCancelled) {
      throw BackupCancelledException('操作已被取消');
    }
  }
}

/// 备份操作被取消异常
class BackupCancelledException implements Exception {
  final String message;
  
  const BackupCancelledException(this.message);
  
  @override
  String toString() => 'BackupCancelledException: $message';
}