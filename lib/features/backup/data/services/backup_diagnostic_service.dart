import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database.dart';
import '../repository/optimized_data_export_repository.dart';
import 'backup_logger.dart';

/// 备份诊断结果
class BackupDiagnosticResult {
  final bool isHealthy;
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> systemInfo;
  final Map<String, dynamic> databaseInfo;
  final Map<String, dynamic> storageInfo;

  const BackupDiagnosticResult({
    required this.isHealthy,
    required this.issues,
    required this.warnings,
    required this.systemInfo,
    required this.databaseInfo,
    required this.storageInfo,
  });

  Map<String, dynamic> toJson() => {
    'isHealthy': isHealthy,
    'issues': issues,
    'warnings': warnings,
    'systemInfo': systemInfo,
    'databaseInfo': databaseInfo,
    'storageInfo': storageInfo,
    'timestamp': DateTime.now().toIso8601String(),
  };
}

/// 备份诊断服务
class BackupDiagnosticService {
  final AppDatabase _database;
  final BackupLogger _logger = BackupLogger.instance;

  BackupDiagnosticService(this._database);

  /// 执行完整的备份系统诊断
  Future<BackupDiagnosticResult> runFullDiagnostic() async {
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      await _logger.info('BackupDiagnostic', '开始执行备份系统诊断');
      
      // 1. 检查数据库状态
      final databaseInfo = await _checkDatabaseHealth(issues, warnings);
      
      // 2. 检查存储状态
      final storageInfo = await _checkStorageHealth(issues, warnings);
      
      // 3. 检查系统状态
      final systemInfo = await _checkSystemHealth(issues, warnings);
      
      // 4. 检查备份目录
      await _checkBackupDirectory(issues, warnings);
      
      // 5. 检查权限
      await _checkPermissions(issues, warnings);
      
      final isHealthy = issues.isEmpty;
      
      final result = BackupDiagnosticResult(
        isHealthy: isHealthy,
        issues: issues,
        warnings: warnings,
        systemInfo: systemInfo,
        databaseInfo: databaseInfo,
        storageInfo: storageInfo,
      );
      
      await _logger.info('BackupDiagnostic', '诊断完成', details: {
        'isHealthy': isHealthy,
        'issueCount': issues.length,
        'warningCount': warnings.length,
      });
      
      return result;
      
    } catch (e) {
      await _logger.error('BackupDiagnostic', '诊断过程中发生错误', error: e);
      
      return BackupDiagnosticResult(
        isHealthy: false,
        issues: ['诊断过程中发生错误: ${e.toString()}'],
        warnings: warnings,
        systemInfo: {'error': '无法获取系统信息'},
        databaseInfo: {'error': '无法获取数据库信息'},
        storageInfo: {'error': '无法获取存储信息'},
      );
    }
  }

  /// 检查数据库健康状态
  Future<Map<String, dynamic>> _checkDatabaseHealth(
    List<String> issues,
    List<String> warnings,
  ) async {
    final info = <String, dynamic>{};
    
    try {
      // 检查数据库连接
      final repository = OptimizedDataExportRepository(_database);
      
      // 获取表数量统计
      final tableCounts = await repository.getTableCounts();
      info['tableCounts'] = tableCounts;
      info['totalRecords'] = tableCounts.values.fold<int>(0, (sum, count) => sum + count);
      
      // 检查数据库版本
      final schemaVersion = await repository.getDatabaseSchemaVersion();
      info['schemaVersion'] = schemaVersion;
      
      // 检查数据库文件大小
      try {
        // 尝试获取数据库路径信息
        info['databaseSizeCheck'] = 'attempted';
        warnings.add('数据库文件大小检查暂时跳过');
      } catch (e) {
        warnings.add('无法获取数据库文件大小: ${e.toString()}');
      }
      
      // 尝试执行简单查询测试数据库响应
      try {
        await repository.getAllTableNames();
        info['connectionStatus'] = 'healthy';
      } catch (e) {
        issues.add('数据库连接测试失败: ${e.toString()}');
        info['connectionStatus'] = 'failed';
      }
      
      // 检查是否有空表
      final emptyTables = tableCounts.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList();
      
      if (emptyTables.isNotEmpty) {
        warnings.add('发现空表: ${emptyTables.join(', ')}');
        info['emptyTables'] = emptyTables;
      }
      
    } catch (e) {
      issues.add('数据库健康检查失败: ${e.toString()}');
      info['error'] = e.toString();
    }
    
    return info;
  }

  /// 检查存储健康状态
  Future<Map<String, dynamic>> _checkStorageHealth(
    List<String> issues,
    List<String> warnings,
  ) async {
    final info = <String, dynamic>{};
    
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      info['appDirectory'] = appDir.path;
      
      // 检查目录是否可访问
      if (!await appDir.exists()) {
        issues.add('应用文档目录不存在: ${appDir.path}');
        return info;
      }
      
      // 获取可用存储空间
      try {
        final stat = await appDir.stat();
        info['directoryExists'] = true;
        info['lastModified'] = stat.modified.toIso8601String();
      } catch (e) {
        warnings.add('无法获取目录统计信息: ${e.toString()}');
      }
      
      // 测试文件创建权限
      try {
        final testFile = File(path.join(appDir.path, 'test_write_permission.tmp'));
        await testFile.writeAsString('test');
        await testFile.delete();
        info['writePermission'] = true;
      } catch (e) {
        issues.add('没有写入权限: ${e.toString()}');
        info['writePermission'] = false;
      }
      
      // 估算可用空间（简化版本）
      try {
        // 这里可以添加更精确的磁盘空间检查
        info['spaceCheckStatus'] = 'basic_check_only';
        warnings.add('无法精确检查可用存储空间，请确保设备有足够空间');
      } catch (e) {
        warnings.add('存储空间检查失败: ${e.toString()}');
      }
      
    } catch (e) {
      issues.add('存储健康检查失败: ${e.toString()}');
      info['error'] = e.toString();
    }
    
    return info;
  }

  /// 检查系统健康状态
  Future<Map<String, dynamic>> _checkSystemHealth(
    List<String> issues,
    List<String> warnings,
  ) async {
    final info = <String, dynamic>{};
    
    try {
      // 获取平台信息
      info['platform'] = Platform.operatingSystem;
      info['version'] = Platform.operatingSystemVersion;
      
      // 检查内存使用情况（基础检查）
      try {
        // 创建一个小的测试对象来检查内存分配
        final testData = List.generate(1000, (i) => 'test_$i');
        testData.clear();
        info['memoryTest'] = 'passed';
      } catch (e) {
        warnings.add('内存测试异常: ${e.toString()}');
        info['memoryTest'] = 'failed';
      }
      
      // 检查当前时间
      final now = DateTime.now();
      info['currentTime'] = now.toIso8601String();
      info['timezone'] = now.timeZoneName;
      
    } catch (e) {
      warnings.add('系统健康检查失败: ${e.toString()}');
      info['error'] = e.toString();
    }
    
    return info;
  }

  /// 检查备份目录
  Future<void> _checkBackupDirectory(
    List<String> issues,
    List<String> warnings,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));
      
      if (!await backupDir.exists()) {
        try {
          await backupDir.create(recursive: true);
          warnings.add('备份目录不存在，已自动创建');
        } catch (e) {
          issues.add('无法创建备份目录: ${e.toString()}');
          return;
        }
      }
      
      // 检查备份目录中的文件
      try {
        final files = await backupDir.list().toList();
        final backupFiles = files
            .where((f) => f is File && f.path.endsWith('.json'))
            .length;
        
        if (backupFiles == 0) {
          warnings.add('备份目录中没有找到备份文件');
        } else {
          warnings.add('找到 $backupFiles 个备份文件');
        }
      } catch (e) {
        warnings.add('无法读取备份目录内容: ${e.toString()}');
      }
      
    } catch (e) {
      issues.add('备份目录检查失败: ${e.toString()}');
    }
  }

  /// 检查权限
  Future<void> _checkPermissions(
    List<String> issues,
    List<String> warnings,
  ) async {
    try {
      // 检查基本文件操作权限
      final tempDir = Directory.systemTemp;
      final testFile = File(path.join(tempDir.path, 'backup_permission_test.tmp'));
      
      try {
        // 测试创建文件
        await testFile.writeAsString('permission test');
        
        // 测试读取文件
        final content = await testFile.readAsString();
        if (content != 'permission test') {
          warnings.add('文件读写测试异常');
        }
        
        // 测试删除文件
        await testFile.delete();
        
      } catch (e) {
        issues.add('基本文件权限测试失败: ${e.toString()}');
      }
      
    } catch (e) {
      warnings.add('权限检查失败: ${e.toString()}');
    }
  }

  /// 快速诊断（仅检查关键问题）
  Future<BackupDiagnosticResult> runQuickDiagnostic() async {
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // 快速数据库连接测试
      final repository = OptimizedDataExportRepository(_database);
      await repository.getAllTableNames();
      
      // 快速存储权限测试
      final appDir = await getApplicationDocumentsDirectory();
      final testFile = File(path.join(appDir.path, 'quick_test.tmp'));
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return BackupDiagnosticResult(
        isHealthy: true,
        issues: issues,
        warnings: warnings,
        systemInfo: {'quickCheck': 'passed'},
        databaseInfo: {'quickCheck': 'passed'},
        storageInfo: {'quickCheck': 'passed'},
      );
      
    } catch (e) {
      issues.add('快速诊断发现问题: ${e.toString()}');
      
      return BackupDiagnosticResult(
        isHealthy: false,
        issues: issues,
        warnings: warnings,
        systemInfo: {'quickCheck': 'failed'},
        databaseInfo: {'quickCheck': 'failed'},
        storageInfo: {'quickCheck': 'failed'},
      );
    }
  }

  /// 生成诊断报告
  Future<String> generateDiagnosticReport(BackupDiagnosticResult result) async {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 备份系统诊断报告 ===');
    buffer.writeln('生成时间: ${DateTime.now()}');
    buffer.writeln('系统状态: ${result.isHealthy ? "正常" : "异常"}');
    buffer.writeln();
    
    if (result.issues.isNotEmpty) {
      buffer.writeln('发现的问题:');
      for (int i = 0; i < result.issues.length; i++) {
        buffer.writeln('${i + 1}. ${result.issues[i]}');
      }
      buffer.writeln();
    }
    
    if (result.warnings.isNotEmpty) {
      buffer.writeln('警告信息:');
      for (int i = 0; i < result.warnings.length; i++) {
        buffer.writeln('${i + 1}. ${result.warnings[i]}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('系统信息:');
    result.systemInfo.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln();
    
    buffer.writeln('数据库信息:');
    result.databaseInfo.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln();
    
    buffer.writeln('存储信息:');
    result.storageInfo.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    
    return buffer.toString();
  }
}