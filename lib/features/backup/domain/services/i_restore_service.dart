import '../models/backup_metadata.dart';
import '../models/restore_result.dart';
import '../models/restore_preview.dart';
import '../models/restore_mode.dart';
import '../common/backup_common.dart';

/// 恢复进度回调函数类型
/// [message] 当前操作描述
/// [current] 当前进度值
/// [total] 总进度值
typedef RestoreProgressCallback = void Function(String message, int current, int total);



/// 数据恢复服务接口
abstract class IRestoreService {
  /// 验证备份文件并获取元数据
  /// [filePath] 备份文件路径
  /// [password] 解密密码（如果备份文件已加密）
  /// 返回备份文件的元数据信息
  Future<BackupMetadata> validateBackupFile(
    String filePath, {
    String? password,
  });

  /// 预览恢复操作
  /// [filePath] 备份文件路径
  /// [password] 解密密码（如果备份文件已加密）
  /// 返回恢复预览信息，包含将要恢复的数据统计
  Future<RestorePreview> previewRestore(
    String filePath, {
    RestoreMode mode,
    String? password,
  });

  /// 从备份文件恢复数据
  /// [filePath] 备份文件路径
  /// [mode] 恢复模式（完全替换/合并数据）
  /// [password] 解密密码（如果备份文件已加密）
  /// [selectedTables] 选择要恢复的表（null表示恢复所有表）
  /// [onProgress] 进度回调函数
  /// [cancelToken] 取消令牌
  /// 返回恢复操作结果
  Future<RestoreResult> restoreFromBackup({
    required String filePath,
    required RestoreMode mode,
    String? password,
    List<String>? selectedTables,
    RestoreProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// 检查备份文件兼容性
  /// [filePath] 备份文件路径
  /// [password] 解密密码（如果备份文件已加密）
  /// 返回兼容性检查结果
  Future<bool> checkCompatibility(
    String filePath, {
    String? password,
  });

  /// 估算恢复时间
  /// [filePath] 备份文件路径
  /// [mode] 恢复模式
  /// [selectedTables] 选择要恢复的表
  /// 返回预计恢复时间（秒）
  Future<int> estimateRestoreTime(
    String filePath,
    RestoreMode mode, {
    List<String>? selectedTables,
  });
}