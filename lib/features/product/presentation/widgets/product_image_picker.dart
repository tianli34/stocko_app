import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// 产品图片选择器组件
class ProductImagePicker extends StatefulWidget {
  final String? initialImagePath;
  final ValueChanged<String?> onImageChanged;
  final double size;
  final bool enabled;

  const ProductImagePicker({
    super.key,
    this.initialImagePath,
    required this.onImageChanged,
    this.size = 120,
    this.enabled = true,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  String? _currentImagePath;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  @override
  void didUpdateWidget(ProductImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath) {
      setState(() {
        _currentImagePath = widget.initialImagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 图片显示区域
        GestureDetector(
          onTap: widget.enabled ? _showImagePickerOptions : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _buildImageContent(),
          ),
        ),
        const SizedBox(height: 8),
        // 操作按钮
        // if (widget.enabled) _buildActionButtons(),
      ],
    );
  }

  Widget _buildImageContent() {
    if (_currentImagePath != null && _currentImagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_currentImagePath!),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: widget.size * 0.3,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 4),
        Text(
          '添加图片',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('选择图片', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.camera_alt,
                      label: '拍照',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImageFromCamera();
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.photo_library,
                      label: '相册',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImageFromGallery();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final String? imagePath = await _imageService.pickImageFromCamera();
      if (imagePath != null) {
        _updateImage(imagePath);
      }
    } catch (e) {
      showAppSnackBar(context, message: '拍照失败: $e', isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final String? imagePath = await _imageService.pickImageFromGallery();
      if (imagePath != null) {
        _updateImage(imagePath);
      }
    } catch (e) {
      showAppSnackBar(context, message: '选择图片失败: $e', isError: true);
    }
  }

  void _updateImage(String imagePath) {
    setState(() {
      _currentImagePath = imagePath;
    });
    widget.onImageChanged(imagePath);
  }
  // void _removeImage() {
  //   setState(() {
  //     _currentImagePath = null;
  //   });
  //   widget.onImageChanged(null);
  // }

}
