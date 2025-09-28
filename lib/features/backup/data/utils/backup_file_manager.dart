import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_metadata.dart';

/// 备份文件管理器
/// 处理备份文件的本地存储、分享和管理操作
class BackupFileManager {
  /// 获取备份目录
  static Future<Directory> getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// 获取备份文件路径
  static Future<String> getBackupFilePath(String backupId) async {
    final backupDir = await getBackupDirectory();
    return path.join(backupDir.path, '$backupId.json');
  }

  /// 检查备份文件是否存在
  static Future<bool> backupFileExists(String backupId) async {
    final filePath = await getBackupFilePath(backupId);
    return File(filePath).exists();
  }

  /// 重命名备份文件
  static Future<bool> renameBackupFile(String oldBackupId, String newBackupId) async {
    try {
      final oldFilePath = await getBackupFilePath(oldBackupId);
      final newFilePath = await getBackupFilePath(newBackupId);
      
      final oldFile = File(oldFilePath);
      if (!await oldFile.exists()) {
        return false;
      }
      
      // 检查新文件名是否已存在
      if (await File(newFilePath).exists()) {
        throw BackupException.fileSystem('备份文件名已存在: $newBackupId');
      }
      
      await oldFile.rename(newFilePath);
      return true;
    } catch (e) {
      throw BackupException.fileSystem('重命名备份文件失败: ${e.toString()}');
    }
  }

  /// 复制备份文件到指定路径
  static Future<void> copyBackupFile(String backupId, String destinationPath) async {
    try {
      final sourceFilePath = await getBackupFilePath(backupId);
      final sourceFile = File(sourceFilePath);
      
      if (!await sourceFile.exists()) {
        throw BackupException.fileSystem('备份文件不存在: $backupId');
      }
      
      await sourceFile.copy(destinationPath);
    } catch (e) {
      throw BackupException.fileSystem('复制备份文件失败: ${e.toString()}');
    }
  }

  /// 分享备份文件
  /// 返回备份文件路径，由调用者处理分享逻辑
  static Future<String> getBackupFileForSharing(BackupMetadata metadata) async {
    try {
      final filePath = await getBackupFilePath(metadata.id);
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw BackupException.fileSystem('备份文件不存在: ${metadata.id}');
      }
      
      return filePath;
    } catch (e) {
      throw BackupException.fileSystem('获取备份文件失败: ${e.toString()}');
    }
  }

  /// 删除备份文件
  static Future<bool> deleteBackupFile(String backupId) async {
    try {
      final filePath = await getBackupFilePath(backupId);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw BackupException.fileSystem('删除备份文件失败: ${e.toString()}');
    }
  }

  /// 获取备份文件大小
  static Future<int> getBackupFileSize(String backupId) async {
    try {
      final filePath = await getBackupFilePath(backupId);
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.length();
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// 清理所有备份文件（慎用）
  static Future<void> clearAllBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw BackupException.fileSystem('清理备份文件失败: ${e.toString()}');
    }
  }

  /// 获取备份目录总大小
  static Future<int> getBackupDirectorySize() async {
    try {
      final backupDir = await getBackupDirectory();
      int totalSize = 0;
      
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// 验证备份文件名
  static bool isValidBackupFileName(String fileName) {
    // 检查文件名是否包含非法字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return false;
    }
    
    // 检查文件名长度
    if (fileName.isEmpty || fileName.length > 255) {
      return false;
    }
    
    return true;
  }

  /// 格式化文件大小显示
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 生成安全的文件名
  static String generateSafeFileName(String originalName) {
    // 移除或替换非法字符
    String safeName = originalName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    // 限制长度
    if (safeName.length > 200) {
      safeName = safeName.substring(0, 200);
    }
    
    // 确保不为空
    if (safeName.isEmpty) {
      safeName = 'backup';
    }
    
    return safeName;
  }

  /// 检查可用存储空间
  /// 返回可用空间大小（字节）
  static Future<int> getAvailableStorageSpace() async {
    try {
      final backupDir = await getBackupDirectory();
      final stat = await backupDir.stat();
      
      // 在不同平台上获取可用空间的方法可能不同
      // 这里提供一个基本实现，实际应用中可能需要使用平台特定的API
      
      // 对于Android/iOS，可以使用disk_space插件
      // 这里先返回一个估算值
      return 1024 * 1024 * 1024; // 1GB 作为默认值
    } catch (e) {
      // 如果无法获取存储空间信息，返回0
      return 0;
    }
  }

  /// 检查是否有足够的存储空间
  /// [requiredSize] 需要的空间大小（字节）
  /// [reserveSpace] 预留空间大小（字节），默认100MB
  static Future<bool> hasEnoughStorageSpace(
    int requiredSize, {
    int reserveSpace = 100 * 1024 * 1024, // 100MB
  }) async {
    try {
      final availableSpace = await getAvailableStorageSpace();
      return availableSpace >= (requiredSize + reserveSpace);
    } catch (e) {
      // 如果无法检查存储空间，假设有足够空间
      return true;
    }
  }

  /// 验证备份文件完整性
  /// 检查文件是否存在且可读
  static Future<bool> validateBackupFileIntegrity(String backupId) async {
    try {
      final filePath = await getBackupFilePath(backupId);
      final file = File(filePath);
      
      if (!await file.exists()) {
        return false;
      }
      
      // 尝试读取文件的前几个字节来验证文件是否损坏
      final bytes = await file.openRead(0, 100).toList();
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 分享备份文件
  /// 使用系统分享功能分享备份文件
  static Future<void> shareBackupFile(BackupMetadata metadata) async {
    try {
      final filePath = await getBackupFileForSharing(metadata);
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw BackupException.fileSystem('备份文件不存在: ${metadata.id}');
      }
      
      // 使用share_plus插件分享文件
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '备份文件: ${metadata.fileName}\n'
              '创建时间: ${metadata.createdAt.toLocal()}\n'
              '文件大小: ${formatFileSize(metadata.fileSize)}',
        subject: '库存数据备份 - ${metadata.fileName}',
      );
    } catch (e) {
      throw BackupException.fileSystem('分享备份文件失败: ${e.toString()}');
    }
  }

  /// 导出备份文件到指定目录
  /// [backupId] 备份文件ID
  /// [destinationDir] 目标目录路径
  /// [newFileName] 新文件名（可选）
  static Future<String> exportBackupFile(
    String backupId,
    String destinationDir, {
    String? newFileName,
  }) async {
    try {
      final sourceFilePath = await getBackupFilePath(backupId);
      final sourceFile = File(sourceFilePath);
      
      if (!await sourceFile.exists()) {
        throw BackupException.fileSystem('备份文件不存在: $backupId');
      }
      
      // 确保目标目录存在
      final destDir = Directory(destinationDir);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      
      // 生成目标文件路径
      final fileName = newFileName ?? '$backupId.json';
      final destinationPath = path.join(destinationDir, fileName);
      
      // 检查目标文件是否已存在
      final destFile = File(destinationPath);
      if (await destFile.exists()) {
        throw BackupException.fileSystem('目标文件已存在: $fileName');
      }
      
      // 复制文件
      await sourceFile.copy(destinationPath);
      
      return destinationPath;
    } catch (e) {
      throw BackupException.fileSystem('导出备份文件失败: ${e.toString()}');
    }
  }

  /// 获取备份文件列表（按修改时间排序）
  static Future<List<FileSystemEntity>> getBackupFilesList({
    bool sortByModifiedTime = true,
  }) async {
    try {
      final backupDir = await getBackupDirectory();
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .toList();
      
      if (sortByModifiedTime) {
        // 按修改时间排序（最新的在前）
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        });
      }
      
      return files;
    } catch (e) {
      return [];
    }
  }

  /// 清理过期的备份文件
  /// [maxAge] 最大保留天数
  /// [maxCount] 最大保留文件数量
  static Future<int> cleanupOldBackups({
    int? maxAge,
    int? maxCount,
  }) async {
    try {
      final files = await getBackupFilesList(sortByModifiedTime: true);
      int deletedCount = 0;
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i] as File;
        bool shouldDelete = false;
        
        // 检查文件年龄
        if (maxAge != null) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified).inDays;
          if (age > maxAge) {
            shouldDelete = true;
          }
        }
        
        // 检查文件数量限制
        if (maxCount != null && i >= maxCount) {
          shouldDelete = true;
        }
        
        if (shouldDelete) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            // 忽略删除失败的文件，继续处理其他文件
            continue;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw BackupException.fileSystem('清理过期备份失败: ${e.toString()}');
    }
  }

  /// 获取备份目录信息
  static Future<Map<String, dynamic>> getBackupDirectoryInfo() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = await getBackupFilesList();
      final totalSize = await getBackupDirectorySize();
      final availableSpace = await getAvailableStorageSpace();
      
      return {
        'path': backupDir.path,
        'fileCount': files.length,
        'totalSize': totalSize,
        'totalSizeFormatted': formatFileSize(totalSize),
        'availableSpace': availableSpace,
        'availableSpaceFormatted': formatFileSize(availableSpace),
        'lastModified': files.isNotEmpty 
            ? (files.first as File).statSync().modified
            : null,
      };
    } catch (e) {
      throw BackupException.fileSystem('获取备份目录信息失败: ${e.toString()}');
    }
  }

  /// 创建备份文件的临时副本
  /// 用于在操作过程中保护原始文件
  static Future<String> createTemporaryBackup(String backupId) async {
    try {
      final sourceFilePath = await getBackupFilePath(backupId);
      final sourceFile = File(sourceFilePath);
      
      if (!await sourceFile.exists()) {
        throw BackupException.fileSystem('备份文件不存在: $backupId');
      }
      
      // 创建临时文件路径
      final backupDir = await getBackupDirectory();
      final tempFilePath = path.join(backupDir.path, '${backupId}_temp.json');
      
      // 复制文件
      await sourceFile.copy(tempFilePath);
      
      return tempFilePath;
    } catch (e) {
      throw BackupException.fileSystem('创建临时备份失败: ${e.toString()}');
    }
  }

  /// 删除临时文件
  static Future<void> cleanupTemporaryFiles() async {
    try {
      final backupDir = await getBackupDirectory();
      
      if (!await backupDir.exists()) {
        return;
      }
      
      await for (final entity in backupDir.list()) {
        if (entity is File && entity.path.contains('_temp.json')) {
          try {
            await entity.delete();
          } catch (e) {
            // 忽略删除失败的临时文件
            continue;
          }
        }
      }
    } catch (e) {
      // 忽略清理临时文件的错误
    }
  }
}