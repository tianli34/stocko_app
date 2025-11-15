import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 文件访问辅助工具类
class FileAccessHelper {
  /// 检查文件是否可访问
  static Future<bool> isFileAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists() && await file.length() > 0;
    } catch (e) {
      return false;
    }
  }

  /// 将文件数据保存到临时文件
  static Future<String> saveToTempFile(Uint8List bytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = Directory(path.join(tempDir.path, 'backup_temp'));
      
      // 确保目录存在
      if (!await backupTempDir.exists()) {
        await backupTempDir.create(recursive: true);
      }
      
      final tempFile = File(path.join(backupTempDir.path, fileName));
      
      // 写入文件数据
      await tempFile.writeAsBytes(bytes);
      
      return tempFile.path;
    } catch (e) {
      throw Exception('保存临时文件失败: ${e.toString()}');
    }
  }

  /// 清理临时文件
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = Directory(path.join(tempDir.path, 'backup_temp'));
      
      if (await backupTempDir.exists()) {
        await backupTempDir.delete(recursive: true);
      }
    } catch (e) {
      // 忽略清理错误
    }
  }

  /// 获取文件的可读路径（用于显示）
  static String getDisplayPath(String filePath) {
    try {
      // 如果是临时文件，只显示文件名
      if (filePath.contains('backup_temp')) {
        return path.basename(filePath);
      }
      
      // 如果路径太长，截断显示
      if (filePath.length > 50) {
        final fileName = path.basename(filePath);
        final dirName = path.basename(path.dirname(filePath));
        return '.../$dirName/$fileName';
      }
      
      return filePath;
    } catch (e) {
      return path.basename(filePath);
    }
  }

  /// 检查文件扩展名是否支持
  static bool isSupportedFileExtension(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return ['.json', '.backup'].contains(extension);
  }

  /// 获取建议的备份文件位置
  static Future<List<String>> getSuggestedBackupLocations() async {
    final suggestions = <String>[];
    
    try {
      // 下载文件夹
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        suggestions.add(downloadsDir.path);
      }
    } catch (e) {
      // 忽略错误
    }
    
    try {
      // 文档文件夹
      final documentsDir = await getApplicationDocumentsDirectory();
      suggestions.add(documentsDir.path);
    } catch (e) {
      // 忽略错误
    }
    
    try {
      // 外部存储
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        suggestions.add(externalDir.path);
      }
    } catch (e) {
      // 忽略错误
    }
    
    return suggestions;
  }

  /// 复制文件到可访问位置
  static Future<String> copyToAccessibleLocation(String sourcePath, String fileName) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('源文件不存在');
      }

      // 尝试复制到下载文件夹
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (e) {
        // 如果获取下载文件夹失败，使用文档文件夹
        targetDir = await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final targetFile = File(path.join(targetDir.path, fileName));
      await sourceFile.copy(targetFile.path);
      
      return targetFile.path;
    } catch (e) {
      throw Exception('复制文件失败: ${e.toString()}');
    }
  }

  /// 获取用户友好的访问指南
  static String getAccessGuide() {
    return '''
如果无法访问备份文件，请按以下步骤操作：

1. 将备份文件复制到以下任一位置：
   • 下载文件夹 (Downloads)
   • 文档文件夹 (Documents)
   • SD卡根目录

2. 或者使用文件管理器：
   • 找到备份文件位置
   • 长按文件选择"复制"
   • 导航到下载或文档文件夹
   • 粘贴文件

3. 然后重新在应用中选择文件
''';
  }
}