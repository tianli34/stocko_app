import 'package:flutter/material.dart';

/// 条码输入 + 扫码按钮
class BarcodeSection extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onScan;

  const BarcodeSection({
    super.key,
    required this.controller,
    required this.onScan,
  });

  @override
  State<BarcodeSection> createState() => _BarcodeSectionState();
}

class _BarcodeSectionState extends State<BarcodeSection> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  final String _hintText = '建议最先扫码';

  @override
  void initState() {
    super.initState();
    // 创建一个新的 FocusNode
    _focusNode = FocusNode();
    // 添加监听器
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // 释放 FocusNode
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // 只给条码输入框添加上边距
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: _isFocused ? '' : _hintText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Padding(
          padding: const EdgeInsets.only(right: 12.0), // 给扫码按钮添加右边距
          child: SizedBox(
            height: 33,
            child: ElevatedButton.icon(
              onPressed: widget.onScan,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('扫码'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
