import 'package:flutter/material.dart';
import '../product_image_picker.dart';
import '../inputs/app_text_field.dart';
import 'barcode_section.dart';

/// 商品组数据（用于下拉框）
class ProductGroupOption {
  final int? id;
  final String name;

  const ProductGroupOption({this.id, required this.name});
}

/// 基础信息区：图片、名称、条码
class BasicInfoSection extends StatefulWidget {
  final String? initialImagePath;
  final ValueChanged<String?> onImageChanged;

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final VoidCallback onNameSubmitted;

  final TextEditingController barcodeController;
  final VoidCallback onScan;

  // 商品组模式相关
  final bool isProductGroupEnabled;
  final int? selectedGroupId;
  final List<ProductGroupOption> productGroups;
  final ValueChanged<int?>? onGroupSelected;

  const BasicInfoSection({
    super.key,
    required this.initialImagePath,
    required this.onImageChanged,
    required this.nameController,
    required this.nameFocusNode,
    required this.onNameSubmitted,
    required this.barcodeController,
    required this.onScan,
    this.isProductGroupEnabled = false,
    this.selectedGroupId,
    this.productGroups = const [],
    this.onGroupSelected,
  });

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  @override
  void initState() {
    super.initState();
    // 如果有选中的商品组且商品组模式开启，同步名称到控制器
    if (widget.isProductGroupEnabled && widget.selectedGroupId != null) {
      final group = widget.productGroups
          .where((g) => g.id == widget.selectedGroupId)
          .firstOrNull;
      if (group != null && widget.nameController.text != group.name) {
        widget.nameController.text = group.name;
      }
    }
    // 监听焦点变化，当失去焦点时关闭下拉选项
    widget.nameFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!widget.nameFocusNode.hasFocus) {
      // 焦点失去时，下拉选项会自动关闭（RawAutocomplete 内部处理）
      // 这里可以添加额外的清理逻辑
    }
  }

  @override
  void didUpdateWidget(BasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的商品组变化时，且商品组模式开启时，同步名称
    if (widget.isProductGroupEnabled &&
        widget.selectedGroupId != oldWidget.selectedGroupId &&
        widget.selectedGroupId != null) {
      final group = widget.productGroups
          .where((g) => g.id == widget.selectedGroupId)
          .firstOrNull;
      if (group != null) {
        widget.nameController.text = group.name;
      }
    }
    // 如果焦点节点变化，更新监听
    if (widget.nameFocusNode != oldWidget.nameFocusNode) {
      oldWidget.nameFocusNode.removeListener(_onFocusChanged);
      widget.nameFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.nameFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

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
                    initialImagePath: widget.initialImagePath,
                    onImageChanged: widget.onImageChanged,
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
        // 根据商品组开关状态显示不同的名称输入组件
        if (widget.isProductGroupEnabled)
          _buildNameDropdown(context)
        else
          AppTextField(
            controller: widget.nameController,
            label: '名称',
            isRequired: true,
            focusNode: widget.nameFocusNode,
            onFieldSubmitted: (_) => widget.onNameSubmitted(),
          ),
        const SizedBox(height: 16),
        // 商品组模式下隐藏条码字段
        if (!widget.isProductGroupEnabled)
          BarcodeSection(
            controller: widget.barcodeController,
            onScan: widget.onScan,
          ),
      ],
    );
  }

  /// 构建商品名称输入框（商品组模式）- 合并下拉框与输入框
  Widget _buildNameDropdown(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<ProductGroupOption>(
          textEditingController: widget.nameController,
          focusNode: widget.nameFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.toLowerCase().trim();
            if (query.isEmpty) {
              return widget.productGroups;
            }
            return widget.productGroups.where((option) {
              return option.name.toLowerCase().contains(query);
            });
          },
          displayStringForOption: (option) => option.name,
          onSelected: (ProductGroupOption selection) {
            widget.nameController.text = selection.name;
            widget.onGroupSelected?.call(selection.id);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: '商品名称（商品组）*',
                hintText: '输入新名称或选择已有商品组',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          controller.clear();
                          widget.onGroupSelected?.call(null);
                        },
                      ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                helperText: _getHelperText(),
                helperStyle: TextStyle(
                  color: widget.selectedGroupId != null
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                ),
              ),
              onChanged: (value) {
                // 当用户输入时，检查是否匹配已有商品组
                final matchedGroup = widget.productGroups
                    .where((g) => g.name == value)
                    .firstOrNull;
                if (matchedGroup != null) {
                  widget.onGroupSelected?.call(matchedGroup.id);
                } else {
                  // 输入的是新名称，清除选中的商品组ID
                  widget.onGroupSelected?.call(null);
                }
              },
              onFieldSubmitted: (_) {
                onFieldSubmitted();
                widget.onNameSubmitted();
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入商品名称';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 250,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isSelected = widget.selectedGroupId == option.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: Icon(
                          Icons.folder_outlined,
                          size: 20,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text(
                          option.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: Theme.of(context).primaryColor, size: 20)
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 获取帮助文本
  String? _getHelperText() {
    final currentName = widget.nameController.text.trim();
    if (currentName.isEmpty) return null;
    
    if (widget.selectedGroupId != null) {
      return '✓ 已选择商品组';
    } else {
      return '将创建新商品组："$currentName"';
    }
  }
}
