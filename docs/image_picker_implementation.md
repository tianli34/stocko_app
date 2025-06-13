# 产品图片选择器功能实现指南

## 概述

本文档描述了为产品管理系统实现的图片选择器功能。该功能允许用户为产品添加图片，支持从相册选择或使用相机拍照。

## 已实现的功能

### 1. 核心服务

#### ImageService (图片服务)
位置：`lib/core/services/image_service.dart`

**主要功能：**
- 从相机拍照选择图片
- 从相册选择图片  
- 自动压缩图片（最大尺寸 1024x1024，质量85%）
- 保存图片到应用本地目录
- 删除本地图片文件
- 检查图片文件是否存在

**使用示例：**
```dart
final ImageService imageService = ImageService();

// 从相机拍照
String? imagePath = await imageService.pickImageFromCamera();

// 从相册选择
String? imagePath = await imageService.pickImageFromGallery();

// 删除图片
bool success = await imageService.deleteImage(imagePath);
```

### 2. UI组件

#### ProductImagePicker (产品图片选择器)
位置：`lib/features/product/presentation/widgets/product_image_picker.dart`

**特性：**
- 可点击的图片显示区域
- 支持初始图片路径
- 弹出底部选择菜单（拍照/相册）
- 图片占位符显示
- 操作按钮（更换/删除）
- 错误处理和用户反馈

**使用示例：**
```dart
ProductImagePicker(
  initialImagePath: product.image,
  onImageChanged: (imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
    });
  },
  size: 120,
  enabled: true,
)
```

### 3. 集成实现

#### 产品添加/编辑页面
- 在产品名称下方添加了图片选择器
- 包含使用提示信息
- 图片路径保存到产品模型的 `image` 字段

#### 产品列表显示
- 在产品列表项中显示60x60的缩略图
- 支持图片加载错误处理
- 无图片时显示占位符图标

#### 产品详情页面  
- 显示200x200的大图
- 支持图片加载错误处理
- 居中显示带阴影效果

### 4. 权限配置

#### Android权限
位置：`android/app/src/main/AndroidManifest.xml`

```xml
<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />
<!-- 存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<!-- 相机特性 -->
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

## 技术实现细节

### 1. 依赖包
- `image_picker: ^1.1.2` - 图片选择核心功能
- `path_provider: ^2.1.5` - 获取应用目录路径

### 2. 图片存储
- 图片保存在应用文档目录的 `product_images` 子文件夹
- 文件名格式：`product_[时间戳].[扩展名]`
- 自动创建目录结构

### 3. 图片处理
- 最大尺寸限制：1024x1024像素
- 压缩质量：85%
- 保持原始宽高比

### 4. 错误处理
- 图片选择失败时显示错误提示
- 图片加载失败时显示占位符
- 权限被拒绝时的友好提示

## 使用流程

### 新增产品时添加图片
1. 打开产品添加页面
2. 点击图片选择区域
3. 选择"拍照"或"相册"
4. 确认选择的图片
5. 保存产品（图片路径会保存到数据库）

### 编辑产品时更换图片
1. 打开产品编辑页面
2. 当前图片会自动显示
3. 点击"更换"按钮选择新图片
4. 或点击"删除"按钮移除图片
5. 保存更改

### 查看产品图片
- **列表页面**：显示小缩略图
- **详情页面**：显示大图
- **图片缺失**：显示占位符图标

## 演示页面

创建了演示页面用于测试图片选择功能：
位置：`lib/features/product/presentation/widgets/image_picker_demo.dart`

该页面展示了：
- 图片选择器的完整功能
- 选择状态显示
- 使用说明和提示

## 注意事项

1. **权限处理**：首次使用需要用户授权相机和存储权限
2. **图片大小**：自动压缩处理，无需担心大文件问题
3. **存储位置**：图片存储在应用私有目录，卸载应用时会被清除
4. **错误处理**：所有可能的错误情况都有相应的用户提示
5. **性能考虑**：图片加载使用异步处理，不会阻塞UI

## 后续改进建议

1. **云存储**：考虑将图片上传到云存储服务
2. **图片编辑**：添加裁剪、旋转等编辑功能
3. **多图片**：支持每个产品添加多张图片
4. **图片同步**：在多设备间同步图片数据
5. **缓存优化**：添加图片缓存机制提升性能

## 总结

图片选择器功能已完全集成到产品管理系统中，提供了完整的图片管理能力。用户可以轻松为产品添加图片，系统会自动处理图片的压缩、存储和显示。所有UI组件都经过精心设计，提供了良好的用户体验。
