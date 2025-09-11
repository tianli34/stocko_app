import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/services/image_cache_service.dart';

// Helper to create a tiny 1x1 PNG in memory
Future<Uint8List> _create1x1Png() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(1, 1);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  img.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File imageFile;
  late ImageCacheService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('image_cache_service_test_');
    // Mock path_provider to point to tempDir
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    channel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  setUp(() async {
    service = ImageCacheService();
    await service.initialize();

    final bytes = await _create1x1Png();
    imageFile = File('${tempDir.path}/seed.png');
    await imageFile.writeAsBytes(bytes);
  });

  tearDown(() async {
    await service.clearAllCache();
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageCacheService', () {
    test('getOptimizedImage caches bytes in memory and disk', () async {
      final stat = await imageFile.stat();
      final bytes1 = await service.getOptimizedImage(
        imageFile.path,
        width: 10,
        height: 10,
        quality: 90,
        fileModifiedTime: stat.modified,
      );
      expect(bytes1, isNotNull);

      // Second call should hit byte cache or disk cache and return identical content
      final bytes2 = await service.getOptimizedImage(
        imageFile.path,
        width: 10,
        height: 10,
        quality: 90,
        fileModifiedTime: stat.modified,
      );
      expect(bytes2, isNotNull);
      expect(bytes2, bytes1);
    });

    test('getUIImage loads and caches ui.Image in memory', () async {
      final ui1 = await service.getUIImage(imageFile.path);
      expect(ui1, isNotNull);
      // Call again should hit memory cache
      final ui2 = await service.getUIImage(imageFile.path);
      expect(ui2, isNotNull);
    });

    test('clearImageCache removes specific caches', () async {
      await service.getUIImage(imageFile.path);
      final stat = await imageFile.stat();
      await service.getOptimizedImage(imageFile.path,
          width: 5, height: 5, fileModifiedTime: stat.modified);

      await service.clearImageCache(imageFile.path);

      // After clearing, getting optimized image should regenerate
      final bytes = await service.getOptimizedImage(imageFile.path,
          width: 5, height: 5, fileModifiedTime: stat.modified);
      expect(bytes, isNotNull);
    });

    test('clearAllCache clears caches and recreates directory', () async {
      final stat = await imageFile.stat();
      await service.getOptimizedImage(imageFile.path,
          width: 8, height: 8, fileModifiedTime: stat.modified);
      await service.clearAllCache();

      // Reinitialize effect: subsequent call works and recreates cache dir
      final bytes = await service.getOptimizedImage(imageFile.path,
          width: 8, height: 8, fileModifiedTime: stat.modified);
      expect(bytes, isNotNull);
    });
  });
}
