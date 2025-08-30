import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'image_cache_service.dart';

/// 图片服务
/// 提供图片选择、保存和管理功能
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;

  ImagePicker _picker;
  ImageCacheService _cacheService;

  ImageService._internal({ImagePicker? picker, ImageCacheService? cacheService})
      : _picker = picker ?? ImagePicker(),
        _cacheService = cacheService ?? ImageCacheService();

  @visibleForTesting
  factory ImageService.forTest({
    required ImagePicker picker,
    required ImageCacheService cacheService,
  }) {
    return ImageService._internal(picker: picker, cacheService: cacheService);
  }

  /// 从相机拍照
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToLocal(image);
      }
      return null;
    } catch (e) {
      debugPrint('从相机选择图片失败: $e');
      rethrow;
    }
  }

  /// 从相册选择图片
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 100,
      );

      if (image != null) {
        return await _saveImageToLocal(image);
      }
      return null;
    } catch (e) {
      debugPrint('从相册选择图片失败: $e');
      rethrow;
    }
  }

  /// 显示图片选择底部对话框
  Future<String?> showImagePickerBottomSheet() async {
    // 这个方法需要在调用者中实现UI逻辑
    // 返回选择的图片路径
    return null;
  }

  /// 保存图片到本地应用目录
  Future<String> _saveImageToLocal(XFile image) async {
    try {
      // 获取应用文档目录
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'product_images');

      // 创建图片目录
      final Directory imageDirectory = Directory(imagesDir);
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }

      // 生成唯一的文件名
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path);
      final String fileName = 'product_$timestamp$extension';
      final String localPath = path.join(imagesDir, fileName); // 复制文件到本地目录
      await File(image.path).copy(localPath);
      debugPrint('图片保存成功: $localPath');

      // 异步预加载到缓存
      _preloadImageToCache(localPath);

      return localPath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      rethrow;
    }
  }

  /// 删除本地图片文件
  Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('图片删除成功: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除图片失败: $e');
      return false;
    }
  }

  /// 检查图片文件是否存在
  Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// 获取图片文件大小（字节）
  Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// 清理所有产品图片（慎用）
  Future<void> clearAllProductImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'product_images');
      final Directory imageDirectory = Directory(imagesDir);

      if (await imageDirectory.exists()) {
        await imageDirectory.delete(recursive: true);
        debugPrint('所有产品图片已清理');
      }
    } catch (e) {
      debugPrint('清理图片失败: $e');
    }
  }

  /// 预加载图片到缓存
  Future<void> _preloadImageToCache(String imagePath) async {
    try {
      // 在后台异步预加载常用尺寸的图片
      unawaited(_cacheService.preloadImage(imagePath));
    } catch (e) {
      debugPrint('预加载图片到缓存失败: $e');
    }
  }

  /// 清理图片缓存
  Future<void> clearImageCache(String imagePath) async {
    try {
      await _cacheService.clearImageCache(imagePath);
    } catch (e) {
      debugPrint('清理图片缓存失败: $e');
    }
  }
}
