import 'package:flutter/material.dart';
import '../inputs/shelf_life_unit_dropdown.dart';

/// 保质期表单区块
/// - 左侧：保质期数值输入
/// - 右侧：保质期单位下拉
class ShelfLifeSection extends StatefulWidget {
  final TextEditingController shelfLifeController;
  final FocusNode? shelfLifeFocusNode;
  final String shelfLifeUnit;
  final List<String> shelfLifeUnitOptions;
  final ValueChanged<String> onShelfLifeUnitChanged;
  final VoidCallback? onSubmitted;

  const ShelfLifeSection({
    super.key,
    required this.shelfLifeController,
    this.shelfLifeFocusNode,
    required this.shelfLifeUnit,
    required this.shelfLifeUnitOptions,
    required this.onShelfLifeUnitChanged,
    this.onSubmitted,
  });

  @override
  State<ShelfLifeSection> createState() => _ShelfLifeSectionState();
}

class _ShelfLifeSectionState extends State<ShelfLifeSection> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  final String _hintText = '保质期';

  @override
  void initState() {
    super.initState();
    // 使用传入的 focusNode 或创建一个新的
    _focusNode = widget.shelfLifeFocusNode ?? FocusNode();
    // 添加监听器
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // 如果我们创建了新的 FocusNode，则需要释放它
    if (widget.shelfLifeFocusNode == null) {
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: widget.shelfLifeController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              hintText: _isFocused ? '' : _hintText,
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: ShelfLifeUnitDropdown(
            value: widget.shelfLifeUnit,
            options: widget.shelfLifeUnitOptions,
            onChanged: widget.onShelfLifeUnitChanged,
          ),
        ),
      ],
    );
  }
}
