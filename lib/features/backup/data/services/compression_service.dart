import 'dart:io';
import 'dart:developer' as developer;

import 'package:archive/archive.dart';

import '../../domain/models/performance_metrics.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/services/i_performance_service.dart';

/// 压缩服务实现
class CompressionService implements ICompressionService {
  static const String _gzipMagic = '\x1f\x8b';
  static const String _zipMagic = 'PK';

  @override
  Future<CompressionResult> compressData(
    List<int> data, {
    int level = 6,
  }) async {
    final startTime = DateTime.now();
    
    try {
      developer.log(
        'Starting data compression, size: ${data.length} bytes, level: $level',
        name: 'CompressionService',
      );

      // 使用GZip压缩（archive包不支持level参数，使用默认压缩）
      final compressedData = GZipEncoder().encode(data);
      
      final endTime = DateTime.now();
      final compressionTime = endTime.difference(startTime);
      
      final stats = CompressionStats(
        originalSize: data.length,
        compressedSize: compressedData?.length ?? 0,
        compressionRatio: compressedData != null && data.length > 0
            ? (data.length - compressedData.length) / data.length
            : 0.0,
        compressionTime: compressionTime,
        algorithm: 'gzip',
      );

      developer.log(
        'Data compression completed: ${data.length} -> ${compressedData?.length ?? 0} bytes '
        '(${(stats.compressionRatio * 100).toStringAsFixed(1)}% reduction) '
        'in ${compressionTime.inMilliseconds}ms',
        name: 'CompressionService',
      );

      return CompressionResult(
        compressedData: compressedData ?? [],
        stats: stats,
      );

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.compressionError,
        message: '数据压缩失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<int>> decompressData(List<int> compressedData) async {
    try {
      developer.log(
        'Starting data decompression, size: ${compressedData.length} bytes',
        name: 'CompressionService',
      );

      // 使用GZip解压
      final decompressedData = GZipDecoder().decodeBytes(compressedData);

      developer.log(
        'Data decompression completed: ${compressedData.length} -> ${decompressedData.length} bytes',
        name: 'CompressionService',
      );

      return decompressedData;

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.compressionError,
        message: '数据解压失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<CompressionStats> compressFile(
    String inputPath,
    String outputPath, {
    int level = 6,
  }) async {
    final startTime = DateTime.now();
    
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw BackupException(
          type: BackupErrorType.fileSystemError,
          message: '输入文件不存在: $inputPath',
        );
      }

      final originalSize = await inputFile.length();
      
      developer.log(
        'Starting file compression: $inputPath -> $outputPath, size: $originalSize bytes',
        name: 'CompressionService',
      );

      // 读取输入文件
      final inputData = await inputFile.readAsBytes();
      
      // 压缩数据（archive包不支持level参数，使用默认压缩）
      final compressedData = GZipEncoder().encode(inputData);
      
      if (compressedData == null) {
        throw BackupException(
          type: BackupErrorType.compressionError,
          message: '压缩数据失败',
        );
      }

      // 写入压缩文件
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedData);

      final endTime = DateTime.now();
      final compressionTime = endTime.difference(startTime);
      final compressedSize = compressedData.length;

      final stats = CompressionStats(
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: (originalSize - compressedSize) / originalSize,
        compressionTime: compressionTime,
        algorithm: 'gzip',
      );

      developer.log(
        'File compression completed: $originalSize -> $compressedSize bytes '
        '(${(stats.compressionRatio * 100).toStringAsFixed(1)}% reduction) '
        'in ${compressionTime.inMilliseconds}ms',
        name: 'CompressionService',
      );

      return stats;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        type: BackupErrorType.compressionError,
        message: '文件压缩失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> decompressFile(String inputPath, String outputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw BackupException(
          type: BackupErrorType.fileSystemError,
          message: '压缩文件不存在: $inputPath',
        );
      }

      final compressedSize = await inputFile.length();
      
      developer.log(
        'Starting file decompression: $inputPath -> $outputPath, size: $compressedSize bytes',
        name: 'CompressionService',
      );

      // 读取压缩文件
      final compressedData = await inputFile.readAsBytes();
      
      // 解压数据
      final decompressedData = GZipDecoder().decodeBytes(compressedData);
      
      // 写入解压文件
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(decompressedData);

      developer.log(
        'File decompression completed: $compressedSize -> ${decompressedData.length} bytes',
        name: 'CompressionService',
      );

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        type: BackupErrorType.compressionError,
        message: '文件解压失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isCompressed(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 读取文件头部字节来检测压缩格式
      final bytes = await file.openRead(0, 4).first;
      
      if (bytes.length >= 2) {
        // 检查GZip魔数
        final header = String.fromCharCodes(bytes.take(2));
        if (header == _gzipMagic) {
          return true;
        }
        
        // 检查ZIP魔数
        if (bytes.length >= 2) {
          final zipHeader = String.fromCharCodes(bytes.take(2));
          if (zipHeader == _zipMagic) {
            return true;
          }
        }
      }

      return false;

    } catch (e) {
      developer.log(
        'Error checking if file is compressed: $e',
        name: 'CompressionService',
      );
      return false;
    }
  }

  /// 压缩字符串数据
  Future<CompressionResult> compressString(
    String data, {
    int level = 6,
  }) async {
    final bytes = data.codeUnits;
    return await compressData(bytes, level: level);
  }

  /// 解压字符串数据
  Future<String> decompressString(List<int> compressedData) async {
    final decompressedBytes = await decompressData(compressedData);
    return String.fromCharCodes(decompressedBytes);
  }

  /// 获取最佳压缩级别建议
  /// 根据数据大小和性能要求返回建议的压缩级别
  int getRecommendedCompressionLevel({
    required int dataSize,
    required bool prioritizeSpeed,
  }) {
    // 小文件（< 1MB）：使用较高压缩级别
    if (dataSize < 1024 * 1024) {
      return prioritizeSpeed ? 3 : 6;
    }
    
    // 中等文件（1MB - 10MB）：平衡压缩率和速度
    if (dataSize < 10 * 1024 * 1024) {
      return prioritizeSpeed ? 2 : 4;
    }
    
    // 大文件（> 10MB）：优先考虑速度
    return prioritizeSpeed ? 1 : 3;
  }

  /// 估算压缩后的大小
  /// 基于数据类型和内容特征估算压缩效果
  int estimateCompressedSize(List<int> data) {
    // 简单的启发式估算
    // JSON文本通常可以压缩到原大小的30-50%
    // 这里使用保守估算40%
    return (data.length * 0.4).round();
  }

  /// 批量压缩多个文件到ZIP归档
  Future<CompressionStats> compressFilesToZip(
    List<String> inputPaths,
    String outputPath, {
    int level = 6,
  }) async {
    final startTime = DateTime.now();
    
    try {
      final archive = Archive();
      int totalOriginalSize = 0;

      developer.log(
        'Starting batch compression to ZIP: ${inputPaths.length} files -> $outputPath',
        name: 'CompressionService',
      );

      // 添加每个文件到归档
      for (final inputPath in inputPaths) {
        final file = File(inputPath);
        if (await file.exists()) {
          final fileData = await file.readAsBytes();
          final fileName = file.uri.pathSegments.last;
          
          final archiveFile = ArchiveFile(fileName, fileData.length, fileData);
          archive.addFile(archiveFile);
          
          totalOriginalSize += fileData.length;
        }
      }

      // 创建ZIP编码器并压缩
      final zipEncoder = ZipEncoder();
      final compressedData = zipEncoder.encode(archive);
      
      if (compressedData == null) {
        throw BackupException(
          type: BackupErrorType.compressionError,
          message: 'ZIP压缩失败',
        );
      }

      // 写入压缩文件
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedData);

      final endTime = DateTime.now();
      final compressionTime = endTime.difference(startTime);

      final stats = CompressionStats(
        originalSize: totalOriginalSize,
        compressedSize: compressedData.length,
        compressionRatio: (totalOriginalSize - compressedData.length) / totalOriginalSize,
        compressionTime: compressionTime,
        algorithm: 'zip',
      );

      developer.log(
        'Batch ZIP compression completed: $totalOriginalSize -> ${compressedData.length} bytes '
        '(${(stats.compressionRatio * 100).toStringAsFixed(1)}% reduction) '
        'in ${compressionTime.inMilliseconds}ms',
        name: 'CompressionService',
      );

      return stats;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        type: BackupErrorType.compressionError,
        message: '批量ZIP压缩失败: ${e.toString()}',
        originalError: e,
      );
    }
  }
}