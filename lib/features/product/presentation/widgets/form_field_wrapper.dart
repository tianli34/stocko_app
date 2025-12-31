import 'package:flutter/material.dart';

/// 表单字段包装组件
/// 
/// 为表单字段提供统一的标签样式
class FormFieldWrapper extends StatelessWidget {
  /// 字段标签
  final String label;
  
  /// 子组件（表单字段）
  final Widget child;

  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
