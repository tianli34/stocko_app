import 'package:flutter/material.dart';

/// 通用表单文本输入框
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int maxLines;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.icon,
    this.keyboardType,
    this.prefixText,
    this.maxLines = 1,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // 使用传入的 focusNode 或创建一个新的
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    // 如果我们创建了新的 FocusNode，则需要释放它
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 标签显示在左边
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                widget.isRequired ? '${widget.label} *' : widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 输入框
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                onFieldSubmitted: widget.onFieldSubmitted,
                decoration: InputDecoration(
                  prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
                  prefixText: widget.prefixText,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: widget.isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '${widget.label}不能为空';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ),
        ],
    );
  }
}
