import 'package:flutter/material.dart';

/// 表单底部操作栏（提交按钮）
class ProductFormActionBar extends StatelessWidget {
  final bool isLoading;
  final bool isEdit;
  final VoidCallback onSubmit;

  const ProductFormActionBar({
    super.key,
    required this.isLoading,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEdit ? '更新货品' : '添加货品',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
