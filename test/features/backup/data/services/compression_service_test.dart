import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/services/compression_service.dart';

void main() {
  group('CompressionService', () {
    late CompressionService compressionService;
    late Directory tempDir;

    setUp(() async {
      compressionService = CompressionService();
      tempDir = await Directory.systemTemp.createTemp('compression_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should compress and decompress data correctly', () async {
      final originalData = 'Hello, World! This is a test string for compression.'.codeUnits;
      
      // 压缩数据
      final compressionResult = await compressionService.compressData(originalData);
      
      expect(compressionResult.compressedData, isNotEmpty);
      expect(compressionResult.stats.originalSize, equals(originalData.length));
      expect(compressionResult.stats.compressedSize, equals(compressionResult.compressedData.length));
      expect(compressionResult.stats.compressionRatio, isA<double>());
      expect(compressionResult.stats.algorithm, equals('gzip'));
      
      // 解压数据
      final decompressedData = await compressionService.decompressData(compressionResult.compressedData);
      
      expect(decompressedData, equals(originalData));
    });

    test('should compress and decompress files correctly', () async {
      final inputFile = File('${tempDir.path}/input.txt');
      final outputFile = File('${tempDir.path}/output.gz');
      final decompressedFile = File('${tempDir.path}/decompressed.txt');
      
      final testContent = 'This is a test file content for compression testing. ' * 100;
      await inputFile.writeAsString(testContent);
      
      // 压缩文件
      final stats = await compressionService.compressFile(
        inputFile.path,
        outputFile.path,
        level: 6,
      );
      
      expect(await outputFile.exists(), isTrue);
      expect(stats.originalSize, equals(testContent.length));
      expect(stats.compressedSize, lessThan(stats.originalSize));
      expect(stats.compressionRatio, isA<double>());
      
      // 解压文件
      await compressionService.decompressFile(outputFile.path, decompressedFile.path);
      
      expect(await decompressedFile.exists(), isTrue);
      final decompressedContent = await decompressedFile.readAsString();
      expect(decompressedContent, equals(testContent));
    });

    test('should detect compressed files correctly', () async {
      final normalFile = File('${tempDir.path}/normal.txt');
      final compressedFile = File('${tempDir.path}/compressed.gz');
      
      await normalFile.writeAsString('Normal file content');
      
      // 创建压缩文件
      final stats = await compressionService.compressFile(
        normalFile.path,
        compressedFile.path,
      );
      
      expect(await compressionService.isCompressed(normalFile.path), isFalse);
      expect(await compressionService.isCompressed(compressedFile.path), isTrue);
    });

    test('should compress and decompress strings correctly', () async {
      final originalString = 'This is a test string for compression. ' * 50;
      
      // 压缩字符串
      final compressionResult = await compressionService.compressString(originalString);
      
      expect(compressionResult.compressedData, isNotEmpty);
      expect(compressionResult.stats.compressionRatio, isA<double>());
      
      // 解压字符串
      final decompressedString = await compressionService.decompressString(
        compressionResult.compressedData,
      );
      
      expect(decompressedString, equals(originalString));
    });

    test('should recommend appropriate compression levels', () {
      // 小文件
      final smallFileLevel = compressionService.getRecommendedCompressionLevel(
        dataSize: 500 * 1024, // 500KB
        prioritizeSpeed: false,
      );
      expect(smallFileLevel, equals(6));
      
      final smallFileSpeedLevel = compressionService.getRecommendedCompressionLevel(
        dataSize: 500 * 1024,
        prioritizeSpeed: true,
      );
      expect(smallFileSpeedLevel, equals(3));
      
      // 大文件
      final largeFileLevel = compressionService.getRecommendedCompressionLevel(
        dataSize: 50 * 1024 * 1024, // 50MB
        prioritizeSpeed: false,
      );
      expect(largeFileLevel, equals(3));
      
      final largeFileSpeedLevel = compressionService.getRecommendedCompressionLevel(
        dataSize: 50 * 1024 * 1024,
        prioritizeSpeed: true,
      );
      expect(largeFileSpeedLevel, equals(1));
    });

    test('should estimate compressed size', () {
      final testData = 'Test data for size estimation. ' * 100;
      final dataBytes = testData.codeUnits;
      
      final estimatedSize = compressionService.estimateCompressedSize(dataBytes);
      
      expect(estimatedSize, lessThan(dataBytes.length));
      expect(estimatedSize, greaterThan(0));
      // 估算应该大约是原大小的40%
      expect(estimatedSize, closeTo(dataBytes.length * 0.4, dataBytes.length * 0.1));
    });

    test('should handle compression errors gracefully', () async {
      // 测试压缩不存在的文件
      expect(
        () => compressionService.compressFile('/nonexistent/file.txt', '/tmp/output.gz'),
        throwsA(isA<Exception>()),
      );
      
      // 测试解压无效数据
      expect(
        () => compressionService.decompressData([1, 2, 3, 4, 5]),
        throwsA(isA<Exception>()),
      );
    });

    test('should create ZIP archives with multiple files', () async {
      final file1 = File('${tempDir.path}/file1.txt');
      final file2 = File('${tempDir.path}/file2.txt');
      final zipFile = File('${tempDir.path}/archive.zip');
      
      await file1.writeAsString('Content of file 1. ' * 50);
      await file2.writeAsString('Content of file 2. ' * 30);
      
      final stats = await compressionService.compressFilesToZip(
        [file1.path, file2.path],
        zipFile.path,
      );
      
      expect(await zipFile.exists(), isTrue);
      expect(stats.originalSize, greaterThan(0));
      expect(stats.compressedSize, lessThan(stats.originalSize));
      expect(stats.algorithm, equals('zip'));
    });
  });
}