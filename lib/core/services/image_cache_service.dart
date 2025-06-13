import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 图片缓存服务
/// 提供本地图片缓存、内存缓存和图片优化功能
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // 内存缓存
  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, Uint8List> _byteCache = {};

  // 缓存大小限制
  static const int maxMemoryCacheSize = 50; // 最大内存缓存图片数量
  static const int maxByteCacheSize = 20; // 最大字节缓存数量

  // 缩略图缓存目录
  String? _thumbnailCacheDir;

  /// 初始化缓存服务
  Future<void> initialize() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      _thumbnailCacheDir = path.join(appDir.path, 'image_cache', 'thumbnails');

      // 创建缓存目录
      final Directory cacheDir = Directory(_thumbnailCacheDir!);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      debugPrint('图片缓存服务初始化完成: $_thumbnailCacheDir');
    } catch (e) {
      debugPrint('图片缓存服务初始化失败: $e');
    }
  }

  /// 获取优化后的图片
  /// [imagePath] 原始图片路径
  /// [width] 目标宽度
  /// [height] 目标高度
  /// [quality] 压缩质量 (0-100)
  Future<Uint8List?> getOptimizedImage(
    String imagePath, {
    int? width,
    int? height,
    int quality = 85,
  }) async {
    try {
      // 生成缓存键
      final cacheKey = _generateCacheKey(imagePath, width, height, quality);

      // 检查字节缓存
      if (_byteCache.containsKey(cacheKey)) {
        debugPrint('从字节缓存加载图片: $cacheKey');
        return _byteCache[cacheKey];
      }

      // 检查磁盘缓存
      final cachedBytes = await _getCachedThumbnail(cacheKey);
      if (cachedBytes != null) {
        debugPrint('从磁盘缓存加载图片: $cacheKey');
        _addToByteCache(cacheKey, cachedBytes);
        return cachedBytes;
      }

      // 生成优化后的图片
      final optimizedBytes = await _generateOptimizedImage(
        imagePath,
        width: width,
        height: height,
        quality: quality,
      );

      if (optimizedBytes != null) {
        // 保存到缓存
        await _saveThumbnailCache(cacheKey, optimizedBytes);
        _addToByteCache(cacheKey, optimizedBytes);
        debugPrint('生成并缓存优化图片: $cacheKey');
      }

      return optimizedBytes;
    } catch (e) {
      debugPrint('获取优化图片失败: $e');
      return null;
    }
  }

  /// 获取内存中的UI图片对象
  Future<ui.Image?> getUIImage(String imagePath) async {
    try {
      // 检查内存缓存
      if (_memoryCache.containsKey(imagePath)) {
        debugPrint('从内存缓存加载UI图片: $imagePath');
        return _memoryCache[imagePath];
      }

      // 从文件加载
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 添加到内存缓存
      _addToMemoryCache(imagePath, image);
      debugPrint('加载并缓存UI图片: $imagePath');

      return image;
    } catch (e) {
      debugPrint('获取UI图片失败: $e');
      return null;
    }
  }

  /// 预加载图片到缓存
  Future<void> preloadImage(String imagePath) async {
    try {
      // 预加载常用尺寸的缩略图
      await Future.wait([
        getOptimizedImage(imagePath, width: 60, height: 60), // 列表缩略图
        getOptimizedImage(imagePath, width: 120, height: 120), // 对话框图片
        getOptimizedImage(imagePath, width: 200, height: 200), // 详情页图片
      ]);
      debugPrint('预加载图片完成: $imagePath');
    } catch (e) {
      debugPrint('预加载图片失败: $e');
    }
  }

  /// 清理单个图片的缓存
  Future<void> clearImageCache(String imagePath) async {
    try {
      // 从内存缓存移除
      _memoryCache.remove(imagePath);

      // 从字节缓存移除相关项
      final keysToRemove = _byteCache.keys
          .where((key) => key.contains(imagePath.hashCode.toString()))
          .toList();

      for (final key in keysToRemove) {
        _byteCache.remove(key);
      }

      // 从磁盘缓存移除相关文件
      if (_thumbnailCacheDir != null) {
        final cacheDir = Directory(_thumbnailCacheDir!);
        if (await cacheDir.exists()) {
          final files = await cacheDir.list().toList();
          for (final file in files) {
            if (file.path.contains(imagePath.hashCode.toString())) {
              await file.delete();
            }
          }
        }
      }

      debugPrint('清理图片缓存: $imagePath');
    } catch (e) {
      debugPrint('清理图片缓存失败: $e');
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      // 清理内存缓存
      _memoryCache.clear();
      _byteCache.clear();

      // 清理磁盘缓存
      if (_thumbnailCacheDir != null) {
        final cacheDir = Directory(_thumbnailCacheDir!);
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        }
      }

      debugPrint('清理所有图片缓存');
    } catch (e) {
      debugPrint('清理所有缓存失败: $e');
    }
  }

  /// 获取缓存状态信息
  Map<String, dynamic> getCacheStatus() {
    return {
      'memoryCount': _memoryCache.length,
      'byteCount': _byteCache.length,
      'maxMemorySize': maxMemoryCacheSize,
      'maxByteSize': maxByteCacheSize,
      'thumbnailCacheDir': _thumbnailCacheDir,
    };
  }

  // 私有方法

  /// 生成缓存键
  String _generateCacheKey(
    String imagePath,
    int? width,
    int? height,
    int quality,
  ) {
    return '${imagePath.hashCode}_${width ?? 'null'}_${height ?? 'null'}_$quality';
  }

  /// 生成优化后的图片
  Future<Uint8List?> _generateOptimizedImage(
    String imagePath, {
    int? width,
    int? height,
    int quality = 85,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final originalBytes = await file.readAsBytes();

      // 如果不需要调整大小，直接返回原始数据
      if (width == null && height == null) {
        return originalBytes;
      }

      // 解码图片
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 计算目标尺寸
      final targetWidth = width ?? originalImage.width;
      final targetHeight = height ?? originalImage.height;

      // 如果尺寸相同，返回原始数据
      if (targetWidth == originalImage.width &&
          targetHeight == originalImage.height) {
        return originalBytes;
      }

      // 创建画布并绘制缩放后的图片
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(
          0,
          0,
          originalImage.width.toDouble(),
          originalImage.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(targetWidth, targetHeight);

      // 转换为字节数据
      final byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      originalImage.dispose();
      resizedImage.dispose();
      picture.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('生成优化图片失败: $e');
      return null;
    }
  }

  /// 从磁盘缓存获取缩略图
  Future<Uint8List?> _getCachedThumbnail(String cacheKey) async {
    try {
      if (_thumbnailCacheDir == null) return null;

      final cacheFile = File(path.join(_thumbnailCacheDir!, '$cacheKey.png'));
      if (await cacheFile.exists()) {
        return await cacheFile.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('读取磁盘缓存失败: $e');
      return null;
    }
  }

  /// 保存缩略图到磁盘缓存
  Future<void> _saveThumbnailCache(String cacheKey, Uint8List bytes) async {
    try {
      if (_thumbnailCacheDir == null) return;

      final cacheFile = File(path.join(_thumbnailCacheDir!, '$cacheKey.png'));
      await cacheFile.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('保存磁盘缓存失败: $e');
    }
  }

  /// 添加到内存缓存
  void _addToMemoryCache(String key, ui.Image image) {
    // 如果缓存已满，移除最旧的项
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final firstKey = _memoryCache.keys.first;
      _memoryCache[firstKey]?.dispose();
      _memoryCache.remove(firstKey);
    }

    _memoryCache[key] = image;
  }

  /// 添加到字节缓存
  void _addToByteCache(String key, Uint8List bytes) {
    // 如果缓存已满，移除最旧的项
    if (_byteCache.length >= maxByteCacheSize) {
      final firstKey = _byteCache.keys.first;
      _byteCache.remove(firstKey);
    }

    _byteCache[key] = bytes;
  }

  /// 释放资源
  void dispose() {
    // 释放内存中的UI图片
    for (final image in _memoryCache.values) {
      image.dispose();
    }
    _memoryCache.clear();
    _byteCache.clear();
  }
}
