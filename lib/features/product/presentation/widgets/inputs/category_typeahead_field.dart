import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../domain/model/category.dart';

/// 类别选择 TypeAhead 输入组件
class CategoryTypeAheadField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final void Function(CategoryModel) onSelected;
  final VoidCallback onTapChooseCategory;
  final String hintText;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const CategoryTypeAheadField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.onTapChooseCategory,
    this.hintText = '类别',
    this.onClear,
    this.onSubmitted,
  });

  @override
  State<CategoryTypeAheadField> createState() => _CategoryTypeAheadFieldState();
}

class _CategoryTypeAheadFieldState extends State<CategoryTypeAheadField> {
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
          child: TypeAheadField<CategoryModel>(
            controller: widget.controller,
            suggestionsCallback: (pattern) {
              if (pattern.isEmpty) {
                return Future.value([
                  const CategoryModel(name: '未分类'),
                  ...widget.categories,
                ]);
              }
              final filtered = widget.categories
                  .where(
                    (c) => c.name
                        .replaceAll(' ', '')
                        .toLowerCase()
                        .contains(pattern.toLowerCase()),
                  )
                  .toList();
              if (filtered.isEmpty || pattern == '未分类') {
                filtered.insert(0, const CategoryModel(name: '未分类'));
              }
              return Future.value(filtered);
            },
            itemBuilder: (context, CategoryModel suggestion) => ListTile(
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
                focusNode: widget.focusNode, // 使用外部传入的 focusNode
                onSubmitted: (_) => widget.onSubmitted?.call(),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  hintText: _isFocused ? '' : widget.hintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                ),
              );
            },
            emptyBuilder: (context) => const Padding(
              padding: EdgeInsets.all(0.0),
              child: Text('未找到匹配的类别'),
            ),
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          onPressed: widget.onTapChooseCategory,
          icon: const Icon(Icons.arrow_forward_ios),
          tooltip: '选择类别',
        ),
      ],
    );
  }
}
