import 'package:flutter/material.dart';
import '../product_image_picker.dart';
import '../inputs/app_text_field.dart';
import 'barcode_section.dart';

/// 基础信息区：图片、名称、条码
class BasicInfoSection extends StatelessWidget {
  final String? initialImagePath;
  final ValueChanged<String?> onImageChanged;

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final VoidCallback onNameSubmitted;

  final TextEditingController barcodeController;
  final VoidCallback onScan;

  const BasicInfoSection({
    super.key,
    required this.initialImagePath,
    required this.onImageChanged,
    required this.nameController,
    required this.nameFocusNode,
    required this.onNameSubmitted,
    required this.barcodeController,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ProductImagePicker(
                    initialImagePath: initialImagePath,
                    onImageChanged: onImageChanged,
                    size: 120,
                    enabled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: nameController,
          label: '名称',
          isRequired: true,
          focusNode: nameFocusNode,
          onFieldSubmitted: (_) => onNameSubmitted(),
        ),
        const SizedBox(height: 16),
        BarcodeSection(
          controller: barcodeController,
          onScan: onScan,
        ),
      ],
    );
  }
}
