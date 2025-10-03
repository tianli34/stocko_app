import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database.dart';
import 'backup_diagnostic_service.dart';
import 'backup_logger.dart';

/// 备份修复结果
class BackupRepairResult {
  final bool success;
  final List<String> fixedIssues;
  final List<String> remainingIssues;
  final String message;

  const BackupRepairResult({
    required this.success,
    required this.fixedIssues,
    required this.remainingIssues,
    required this.message,
  });
}

/// 备份修复服务
class BackupRepairService {
  final AppDatabase _database;
  final BackupLogger _logger = BackupLogger.instance;
  late final BackupDiagnosticService _diagnosticService;

  BackupRepairService(this._database) {
    _diagnosticService = BackupDiagnosticService(_database);
  }

  /// 自动修复备份系统问题
  Future<BackupRepairResult> autoRepair() async {
    final fixedIssues = <String>[];
    final remainingIssues = <String>[];
    
    try {
      await _logger.info('BackupRepair', '开始自动修复备份系统');
      
      // 1. 运行诊断
      final diagnostic = await _diagnosticService.runFullDiagnostic();
      
      if (diagnostic.isHealthy) {
        return BackupRepairResult(
          success: true,
          fixedIssues: [],
          remainingIssues: [],
          message: '备份系统状态正常，无需修复',
        );
      }
      
      // 2. 修复备份目录问题
      await _fixBackupDirectory(fixedIssues, remainingIssues);
      
      // 3. 修复权限问题
      await _fixPermissions(fixedIssues, remainingIssues);
      
      // 4. 清理损坏的备份文件
      await _cleanupCorruptedBackups(fixedIssues, remainingIssues);
      
      // 5. 修复数据库连接问题
      await _fixDatabaseIssues(fixedIssues, remainingIssues);
      
      // 6. 清理临时文件
      await _cleanupTemporaryFiles(fixedIssues, remainingIssues);
      
      final success = remainingIssues.isEmpty;
      final message = success 
          ? '修复完成，共解决 ${fixedIssues.length} 个问题'
          : '部分修复完成，还有 ${remainingIssues.length} 个问题需要手动处理';
      
      await _logger.info('BackupRepair', '自动修复完成', details: {
        'success': success,
        'fixedCount': fixedIssues.length,
        'remainingCount': remainingIssues.length,
      });
      
      return BackupRepairResult(
        success: success,
        fixedIssues: fixedIssues,
        remainingIssues: remainingIssues,
        message: message,
      );
      
    } catch (e) {
      await _logger.error('BackupRepair', '自动修复过程中发生错误', error: e);
      
      return BackupRepairResult(
        success: false,
        fixedIssues: fixedIssues,
        remainingIssues: ['修复过程中发生错误: ${e.toString()}'],
        message: '修复失败，请联系技术支持',
      );
    }
  }

  /// 修复备份目录问题
  Future<void> _fixBackupDirectory(
    List<String> fixedIssues,
    List<String> remainingIssues,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        fixedIssues.add('创建了缺失的备份目录');
      }
      
      // 检查目录权限
      try {
        final testFile = File(path.join(backupDir.path, 'test_permission.tmp'));
        await testFile.writeAsString('test');
        await testFile.delete();
        fixedIssues.add('验证了备份目录的读写权限');
      } catch (e) {
        remainingIssues.add('备份目录权限问题: ${e.toString()}');
      }
      
    } catch (e) {
      remainingIssues.add('无法修复备份目录: ${e.toString()}');
    }
  }

  /// 修复权限问题
  Future<void> _fixPermissions(
    List<String> fixedIssues,
    List<String> remainingIssues,
  ) async {
    try {
      // 测试基本文件操作权限
      final tempDir = Directory.systemTemp;
      final testFile = File(path.join(tempDir.path, 'backup_repair_test.tmp'));
      
      await testFile.writeAsString('permission repair test');
      final content = await testFile.readAsString();
      
      if (content == 'permission repair test') {
        await testFile.delete();
        fixedIssues.add('验证了基本文件操作权限');
      } else {
        remainingIssues.add('文件读写权限异常');
      }
      
    } catch (e) {
      remainingIssues.add('权限修复失败: ${e.toString()}');
    }
  }

  /// 清理损坏的备份文件
  Future<void> _cleanupCorruptedBackups(
    List<String> fixedIssues,
    List<String> remainingIssues,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));
      
      if (!await backupDir.exists()) {
        return;
      }
      
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      int corruptedCount = 0;
      
      for (final file in files) {
        try {
          // 尝试读取和解析文件
          final content = await file.readAsString();
          if (content.trim().isEmpty) {
            await file.delete();
            corruptedCount++;
            continue;
          }
          
          // 尝试解析JSON
          final jsonData = json.decode(content);
          if (jsonData is! Map<String, dynamic> ||
              !jsonData.containsKey('metadata') ||
              !jsonData.containsKey('tables')) {
            await file.delete();
            corruptedCount++;
          }
          
        } catch (e) {
          // 文件损坏，删除它
          try {
            await file.delete();
            corruptedCount++;
          } catch (deleteError) {
            remainingIssues.add('无法删除损坏的备份文件: ${file.path}');
          }
        }
      }
      
      if (corruptedCount > 0) {
        fixedIssues.add('清理了 $corruptedCount 个损坏的备份文件');
      }
      
    } catch (e) {
      remainingIssues.add('清理损坏备份文件失败: ${e.toString()}');
    }
  }

  /// 修复数据库连接问题
  Future<void> _fixDatabaseIssues(
    List<String> fixedIssues,
    List<String> remainingIssues,
  ) async {
    try {
      // 尝试执行简单的数据库查询
      final result = await _database.customSelect('SELECT 1 as test').get();
      
      if (result.isNotEmpty && result.first.data['test'] == 1) {
        fixedIssues.add('验证了数据库连接正常');
      } else {
        remainingIssues.add('数据库查询返回异常结果');
      }
      
    } catch (e) {
      remainingIssues.add('数据库连接问题: ${e.toString()}');
    }
  }

  /// 清理临时文件
  Future<void> _cleanupTemporaryFiles(
    List<String> fixedIssues,
    List<String> remainingIssues,
  ) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFiles = await tempDir
          .list()
          .where((entity) => 
              entity is File && 
              (entity.path.contains('backup_temp') || 
               entity.path.contains('backup_repair_test') ||
               entity.path.contains('test_write_permission')))
          .cast<File>()
          .toList();
      
      int cleanedCount = 0;
      
      for (final file in tempFiles) {
        try {
          await file.delete();
          cleanedCount++;
        } catch (e) {
          // 忽略无法删除的临时文件
        }
      }
      
      if (cleanedCount > 0) {
        fixedIssues.add('清理了 $cleanedCount 个临时文件');
      }
      
    } catch (e) {
      // 临时文件清理失败不是严重问题
      await _logger.warning('BackupRepair', '清理临时文件时发生警告', 
          details: {'error': e.toString()});
    }
  }

  /// 重置备份系统
  Future<BackupRepairResult> resetBackupSystem() async {
    final fixedIssues = <String>[];
    final remainingIssues = <String>[];
    
    try {
      await _logger.info('BackupRepair', '开始重置备份系统');
      
      // 1. 清理所有备份文件
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final backupDir = Directory(path.join(appDir.path, 'backups'));
        
        if (await backupDir.exists()) {
          await backupDir.delete(recursive: true);
          fixedIssues.add('删除了旧的备份目录');
        }
        
        // 重新创建备份目录
        await backupDir.create(recursive: true);
        fixedIssues.add('重新创建了备份目录');
        
      } catch (e) {
        remainingIssues.add('重置备份目录失败: ${e.toString()}');
      }
      
      // 2. 清理所有临时文件
      await _cleanupTemporaryFiles(fixedIssues, remainingIssues);
      
      // 3. 验证数据库连接
      await _fixDatabaseIssues(fixedIssues, remainingIssues);
      
      final success = remainingIssues.isEmpty;
      final message = success 
          ? '备份系统重置完成'
          : '备份系统重置部分完成，还有问题需要处理';
      
      await _logger.info('BackupRepair', '备份系统重置完成', details: {
        'success': success,
        'fixedCount': fixedIssues.length,
        'remainingCount': remainingIssues.length,
      });
      
      return BackupRepairResult(
        success: success,
        fixedIssues: fixedIssues,
        remainingIssues: remainingIssues,
        message: message,
      );
      
    } catch (e) {
      await _logger.error('BackupRepair', '重置备份系统失败', error: e);
      
      return BackupRepairResult(
        success: false,
        fixedIssues: fixedIssues,
        remainingIssues: ['重置过程中发生错误: ${e.toString()}'],
        message: '重置失败，请联系技术支持',
      );
    }
  }

  /// 验证修复结果
  Future<bool> verifyRepair() async {
    try {
      final diagnostic = await _diagnosticService.runQuickDiagnostic();
      return diagnostic.isHealthy;
    } catch (e) {
      await _logger.error('BackupRepair', '验证修复结果失败', error: e);
      return false;
    }
  }
}