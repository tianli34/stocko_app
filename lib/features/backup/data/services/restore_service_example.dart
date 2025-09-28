import '../../../../core/database/database.dart';
import '../../domain/models/restore_mode.dart';
import '../../domain/services/i_restore_service.dart';
import '../../domain/common/backup_common.dart';
import 'restore_service.dart';
import 'encryption_service.dart';
import 'validation_service.dart';

/// RestoreService使用示例
/// 
/// 这个文件展示了如何使用RestoreService进行数据恢复操作
class RestoreServiceExample {
  late final IRestoreService _restoreService;

  RestoreServiceExample(AppDatabase database) {
    final encryptionService = EncryptionService();
    final validationService = ValidationService(database, encryptionService);
    _restoreService = RestoreService(database, encryptionService, validationService);
  }

  /// 示例1: 验证备份文件
  Future<void> validateBackupExample(String filePath) async {
    try {
      print('正在验证备份文件: $filePath');
      
      final metadata = await _restoreService.validateBackupFile(filePath);
      
      print('备份文件验证成功!');
      print('备份ID: ${metadata.id}');
      print('创建时间: ${metadata.createdAt}');
      print('文件大小: ${metadata.fileSize} 字节');
      print('表数量统计: ${metadata.tableCounts}');
      print('是否加密: ${metadata.isEncrypted}');
      
    } catch (e) {
      print('备份文件验证失败: $e');
    }
  }

  /// 示例2: 预览恢复操作
  Future<void> previewRestoreExample(String filePath) async {
    try {
      print('正在生成恢复预览: $filePath');
      
      final preview = await _restoreService.previewRestore(filePath);
      
      print('恢复预览生成成功!');
      print('备份文件兼容性: ${preview.isCompatible ? "兼容" : "不兼容"}');
      print('预计恢复记录数: ${preview.recordCounts}');
      print('预计冲突数量: ${preview.estimatedConflicts}');
      print('预计恢复时间: ${preview.estimatedDurationSeconds} 秒');
      
      if (preview.compatibilityWarnings.isNotEmpty) {
        print('兼容性警告:');
        for (final warning in preview.compatibilityWarnings) {
          print('  - $warning');
        }
      }
      
    } catch (e) {
      print('生成恢复预览失败: $e');
    }
  }

  /// 示例3: 执行完全替换恢复
  Future<void> performReplaceRestoreExample(String filePath) async {
    try {
      print('开始执行完全替换恢复: $filePath');
      
      final result = await _restoreService.restoreFromBackup(
        filePath: filePath,
        mode: RestoreMode.replace,
        onProgress: (step, current, total) {
          final percentage = (current / total * 100).toStringAsFixed(1);
          print('[$percentage%] $step');
        },
      );
      
      if (result.success) {
        print('恢复操作成功完成!');
        print('总恢复记录数: ${result.totalRecordsRestored}');
        print('各表恢复统计: ${result.tableRecordCounts}');
        print('耗时: ${result.endTime.difference(result.startTime).inSeconds} 秒');
        
        if (result.warnings.isNotEmpty) {
          print('警告信息:');
          for (final warning in result.warnings) {
            print('  - $warning');
          }
        }
      } else {
        print('恢复操作失败: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('执行恢复操作时发生错误: $e');
    }
  }

  /// 示例4: 执行合并恢复（保留现有数据）
  Future<void> performMergeRestoreExample(String filePath) async {
    try {
      print('开始执行合并恢复: $filePath');
      
      final result = await _restoreService.restoreFromBackup(
        filePath: filePath,
        mode: RestoreMode.merge,
        selectedTables: ['category', 'unit', 'product'], // 只恢复指定表
        onProgress: (step, current, total) {
          print('进度: $current/$total - $step');
        },
      );
      
      if (result.success) {
        print('合并恢复成功!');
        print('新增/更新记录数: ${result.totalRecordsRestored}');
        print('跳过记录数: ${result.skippedRecords}');
      } else {
        print('合并恢复失败: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('执行合并恢复时发生错误: $e');
    }
  }

  /// 示例5: 恢复加密备份文件
  Future<void> restoreEncryptedBackupExample(
    String filePath,
    String password,
  ) async {
    try {
      print('开始恢复加密备份文件: $filePath');
      
      // 首先验证密码是否正确
      final metadata = await _restoreService.validateBackupFile(
        filePath,
        password: password,
      );
      
      print('密码验证成功，备份文件: ${metadata.fileName}');
      
      // 执行恢复
      final result = await _restoreService.restoreFromBackup(
        filePath: filePath,
        mode: RestoreMode.merge,
        password: password,
        onProgress: (step, current, total) {
          print('[$current/$total] $step');
        },
      );
      
      if (result.success) {
        print('加密备份恢复成功!');
      } else {
        print('加密备份恢复失败: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('恢复加密备份时发生错误: $e');
    }
  }

  /// 示例6: 检查备份文件兼容性
  Future<void> checkCompatibilityExample(String filePath) async {
    try {
      print('检查备份文件兼容性: $filePath');
      
      final isCompatible = await _restoreService.checkCompatibility(filePath);
      
      if (isCompatible) {
        print('✓ 备份文件与当前应用版本兼容');
        
        // 估算恢复时间
        final estimatedTime = await _restoreService.estimateRestoreTime(
          filePath,
          RestoreMode.merge,
        );
        
        print('预计恢复时间: $estimatedTime 秒');
      } else {
        print('✗ 备份文件与当前应用版本不兼容');
        print('建议升级应用或使用兼容的备份文件');
      }
      
    } catch (e) {
      print('检查兼容性时发生错误: $e');
    }
  }

  /// 示例7: 带取消功能的恢复操作
  Future<void> restoreWithCancellationExample(String filePath) async {
    try {
      print('开始可取消的恢复操作: $filePath');
      
      final cancelToken = CancelToken();
      
      // 模拟在5秒后取消操作
      Future.delayed(const Duration(seconds: 5), () {
        print('用户请求取消操作...');
        cancelToken.cancel();
      });
      
      final result = await _restoreService.restoreFromBackup(
        filePath: filePath,
        mode: RestoreMode.merge,
        cancelToken: cancelToken,
        onProgress: (step, current, total) {
          print('进度: $current/$total - $step');
        },
      );
      
      if (result.success) {
        print('恢复操作成功完成!');
      } else {
        print('恢复操作失败或被取消: ${result.errorMessage}');
      }
      
    } catch (e) {
      print('执行可取消恢复时发生错误: $e');
    }
  }

  /// 完整的恢复流程示例
  Future<void> completeRestoreWorkflowExample(String filePath) async {
    print('=== 完整的数据恢复流程示例 ===');
    
    // 步骤1: 验证备份文件
    print('\n1. 验证备份文件...');
    await validateBackupExample(filePath);
    
    // 步骤2: 检查兼容性
    print('\n2. 检查兼容性...');
    await checkCompatibilityExample(filePath);
    
    // 步骤3: 预览恢复操作
    print('\n3. 预览恢复操作...');
    await previewRestoreExample(filePath);
    
    // 步骤4: 执行恢复（这里选择合并模式）
    print('\n4. 执行恢复操作...');
    await performMergeRestoreExample(filePath);
    
    print('\n=== 恢复流程完成 ===');
  }
}

