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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 标签显示在左边
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '条码',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: _isFocused ? '' : '建议优先扫码',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
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
        ],
    );
  }
}
