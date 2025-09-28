import '../models/backup_metadata.dart';
import '../models/backup_options.dart';
import '../common/backup_common.dart';

/// 备份结果
class BackupResult {
  final bool success;
  final String? filePath;
  final BackupMetadata? metadata;
  final String? errorMessage;

  const BackupResult({
    required this.success,
    this.filePath,
    this.metadata,
    this.errorMessage,
  });

  factory BackupResult.success({
    required String filePath,
    required BackupMetadata metadata,
  }) =>
      BackupResult(
        success: true,
        filePath: filePath,
        metadata: metadata,
      );

  factory BackupResult.failure(String errorMessage) => BackupResult(
        success: false,
        errorMessage: errorMessage,
      );
}

/// 备份进度回调函数类型
typedef BackupProgressCallback = void Function(
  String currentStep,
  int currentProgress,
  int totalProgress,
);

/// 备份服务接口
abstract class IBackupService {
  /// 创建备份
  /// [options] 备份选项配置
  /// [onProgress] 进度回调函数
  /// [cancelToken] 取消令牌，用于取消备份操作
  Future<BackupResult> createBackup({
    BackupOptions? options,
    BackupProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// 获取本地备份文件列表
  Future<List<BackupMetadata>> getLocalBackups();

  /// 删除备份文件
  /// [backupId] 备份文件ID
  Future<bool> deleteBackup(String backupId);

  /// 获取备份文件信息
  /// [filePath] 备份文件路径
  Future<BackupMetadata?> getBackupInfo(String filePath);

  /// 验证备份文件
  /// [filePath] 备份文件路径
  Future<bool> validateBackupFile(String filePath);

  /// 估算备份文件大小
  Future<int> estimateBackupSize();
}

