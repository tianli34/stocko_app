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
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // 使用传入的 focusNode 或创建一个新的
    _focusNode = widget.focusNode ?? FocusNode();
    // 添加监听器
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // 如果我们创建了新的 FocusNode，则需要释放它
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: _isFocused ? '' : (widget.isRequired ? '${widget.label} *' : widget.label),
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        prefixText: widget.prefixText,
      ),
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '${widget.label}不能为空';
              }
              return null;
            }
          : null,
    );
  }
}
