import '../models/backup_metadata.dart';
import '../models/validation_result.dart';
import '../models/integrity_check_result.dart';
import '../models/compatibility_check_result.dart';

/// 数据验证服务接口
/// 负责备份文件的格式验证、完整性检查和兼容性验证
abstract class IValidationService {
  /// 验证备份文件格式
  /// [filePath] 备份文件路径
  /// [password] 解密密码（如果文件已加密）
  /// 返回格式验证结果
  Future<ValidationResult> validateBackupFormat(
    String filePath, {
    String? password,
  });

  /// 检查版本兼容性
  /// [metadata] 备份文件元数据
  /// 返回兼容性检查结果
  Future<CompatibilityCheckResult> checkVersionCompatibility(
    BackupMetadata metadata,
  );

  /// 验证数据关系完整性
  /// [tablesData] 表数据
  /// [metadata] 备份元数据
  /// 返回完整性检查结果
  Future<IntegrityCheckResult> validateDataIntegrity(
    Map<String, List<Map<String, dynamic>>> tablesData,
    BackupMetadata metadata,
  );

  /// 检测备份文件损坏
  /// [filePath] 备份文件路径
  /// [password] 解密密码（如果文件已加密）
  /// 返回损坏检测结果和修复建议
  Future<ValidationResult> detectFileCorruption(
    String filePath, {
    String? password,
  });

  /// 恢复前数据预检查
  /// [filePath] 备份文件路径
  /// [selectedTables] 选择要恢复的表
  /// [password] 解密密码（如果文件已加密）
  /// 返回预检查结果
  Future<ValidationResult> preRestoreValidation(
    String filePath, {
    List<String>? selectedTables,
    String? password,
  });

  /// 验证表结构兼容性
  /// [tableName] 表名
  /// [backupTableData] 备份中的表数据样本
  /// 返回表结构兼容性结果
  Future<ValidationResult> validateTableStructure(
    String tableName,
    Map<String, dynamic> backupTableData,
  );

  /// 验证数据类型兼容性
  /// [tableName] 表名
  /// [records] 记录列表
  /// 返回数据类型验证结果
  Future<ValidationResult> validateDataTypes(
    String tableName,
    List<Map<String, dynamic>> records,
  );

  /// 验证外键关系
  /// [tablesData] 所有表数据
  /// 返回外键关系验证结果
  Future<ValidationResult> validateForeignKeyRelationships(
    Map<String, List<Map<String, dynamic>>> tablesData,
  );

  /// 验证数据约束
  /// [tableName] 表名
  /// [records] 记录列表
  /// 返回约束验证结果
  Future<ValidationResult> validateDataConstraints(
    String tableName,
    List<Map<String, dynamic>> records,
  );

  /// 生成修复建议
  /// [validationResults] 验证结果列表
  /// 返回修复建议列表
  List<String> generateRepairSuggestions(
    List<ValidationResult> validationResults,
  );
}