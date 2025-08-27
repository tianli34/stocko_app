import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../domain/model/unit.dart';

/// 单位选择 TypeAhead 输入组件
class UnitTypeAheadField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<Unit> units;
  final int? selectedUnitId;
  final void Function(Unit unit) onSelected;
  final VoidCallback onTapAddAuxiliary;
  final VoidCallback onTapChooseUnit;
  final String hintText;
  final String? Function()? errorTextBuilder;
  final String? helperText;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const UnitTypeAheadField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.units,
    required this.selectedUnitId,
    required this.onSelected,
    required this.onTapAddAuxiliary,
    required this.onTapChooseUnit,
    this.hintText = '基本单位 *',
    this.errorTextBuilder,
    this.helperText,
    this.onClear,
    this.onSubmitted,
  });

  @override
  State<UnitTypeAheadField> createState() => _UnitTypeAheadFieldState();
}

class _UnitTypeAheadFieldState extends State<UnitTypeAheadField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // 添加监听器
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // 移除监听器
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TypeAheadField<Unit>(
            controller: widget.controller,
            suggestionsCallback: (pattern) {
              if (pattern.isEmpty) return Future.value(widget.units);
              final filtered = widget.units
                  .where((u) => u.name
                      .replaceAll(' ', '')
                      .toLowerCase()
                      .contains(pattern.toLowerCase()))
                  .toList();
              return Future.value(filtered);
            },
            itemBuilder: (context, Unit suggestion) => ListTile(
              title: Text(
                suggestion.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dense: true,
            ),
            onSelected: widget.onSelected,
            builder: (context, c, fNode) {
              return TextField(
                controller: c,
                focusNode: widget.focusNode, // 使用外部传入的 focusNode 以便页面控制焦点
                onSubmitted: (_) => widget.onSubmitted?.call(),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  hintText: _isFocused ? '' : widget.hintText,
                  errorText: widget.errorTextBuilder?.call(),
                  helperText: widget.helperText,
                  helperStyle: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: widget.onClear ?? widget.controller.clear,
                        )
                      : null,
                ),
              );
            },
            emptyBuilder: (context) => const Padding(
              padding: EdgeInsets.all(0.0),
              child: Text('未找到匹配的单位'),
            ),
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          onPressed: widget.onTapAddAuxiliary,
          icon: const Icon(Icons.add),
          tooltip: '添加辅单位',
        ),
        IconButton(
          onPressed: widget.onTapChooseUnit,
          icon: const Icon(Icons.arrow_forward_ios),
          tooltip: '选择单位',
        ),
      ],
    );
  }
}
