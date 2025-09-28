/// 备份和恢复操作中可能出现的错误类型
enum BackupErrorType {
  /// 文件系统相关错误（读写权限、磁盘空间等）
  fileSystemError,
  
  /// 数据库操作错误
  databaseError,
  
  /// 数据序列化/反序列化错误
  serializationError,
  
  /// 数据加密/解密错误
  encryptionError,
  
  /// 数据验证错误（格式、完整性等）
  validationError,
  
  /// 磁盘空间不足
  insufficientSpace,
  
  /// 权限被拒绝
  permissionDenied,
  
  /// 文件不存在或无法访问
  fileNotFound,
  
  /// 备份文件格式不支持
  unsupportedFormat,
  
  /// 密码错误
  incorrectPassword,
  
  /// 操作被用户取消
  operationCancelled,
  
  /// 网络相关错误
  networkError,
  
  /// 压缩/解压错误
  compressionError,
  
  /// 未知错误
  unknown,
}