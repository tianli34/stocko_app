import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/product_group_providers.dart';
import '../../domain/model/product_group.dart';

/// 单个变体数据模型
class VariantInputData {
  final String id; // 临时ID，用于列表管理
  String variantName;
  String barcode;

  VariantInputData({
    String? id,
    this.variantName = '',
    this.barcode = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  VariantInputData copyWith({
    String? variantName,
    String? barcode,
  }) {
    return VariantInputData(
      id: id,
      variantName: variantName ?? this.variantName,
      barcode: barcode ?? this.barcode,
    );
  }

  bool get isValid => variantName.trim().isNotEmpty;
  bool get isEmpty =>
      variantName.trim().isEmpty && barcode.trim().isEmpty;
}

/// 多变体录入区域组件
class MultiVariantInputSection extends ConsumerStatefulWidget {
  final int? selectedGroupId;
  final List<VariantInputData> variants;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<List<VariantInputData>> onVariantsChanged;
  final bool enabled;
  final Future<String?> Function()? onScanBarcode;

  const MultiVariantInputSection({
    super.key,
    this.selectedGroupId,
    required this.variants,
    required this.onGroupChanged,
    required this.onVariantsChanged,
    this.enabled = true,
    this.onScanBarcode,
  });

  @override
  ConsumerState<MultiVariantInputSection> createState() =>
      _MultiVariantInputSectionState();
}

class _MultiVariantInputSectionState
    extends ConsumerState<MultiVariantInputSection> {
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _barcodeControllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final variant in widget.variants) {
      _ensureControllers(variant);
    }
  }

  void _ensureControllers(VariantInputData variant) {
    if (!_nameControllers.containsKey(variant.id)) {
      _nameControllers[variant.id] =
          TextEditingController(text: variant.variantName);
    }
    if (!_barcodeControllers.containsKey(variant.id)) {
      _barcodeControllers[variant.id] =
          TextEditingController(text: variant.barcode);
    }
  }

  void _disposeControllers(String id) {
    _nameControllers[id]?.dispose();
    _nameControllers.remove(id);
    _barcodeControllers[id]?.dispose();
    _barcodeControllers.remove(id);
  }

  @override
  void didUpdateWidget(MultiVariantInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步控制器
    for (final variant in widget.variants) {
      _ensureControllers(variant);
    }
    // 清理不再需要的控制器
    final currentIds = widget.variants.map((v) => v.id).toSet();
    final toRemove =
        _nameControllers.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in toRemove) {
      _disposeControllers(id);
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _barcodeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    final newVariant = VariantInputData();
    _ensureControllers(newVariant);
    widget.onVariantsChanged([...widget.variants, newVariant]);
  }

  void _removeVariant(int index) {
    if (widget.variants.length <= 1) return;
    final variant = widget.variants[index];
    _disposeControllers(variant.id);
    final newList = List<VariantInputData>.from(widget.variants)
      ..removeAt(index);
    widget.onVariantsChanged(newList);
  }

  void _updateVariant(int index, VariantInputData updated) {
    final newList = List<VariantInputData>.from(widget.variants);
    newList[index] = updated;
    widget.onVariantsChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(allProductGroupsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 商品组选择
        groupsAsync.when(
          data: (groups) => _buildGroupSelector(context, groups),
          loading: () => const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('加载商品组失败: $e'),
        ),

        // 多变体录入区域（仅当选择了商品组时显示）
        if (widget.selectedGroupId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, size: 20, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '变体列表',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.enabled ? _addVariant : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加变体'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '录入同一商品组下的多个变体，如不同口味、规格等',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // 变体列表
                ...widget.variants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final variant = entry.value;
                  return _buildVariantItem(context, index, variant);
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupSelector(
      BuildContext context, List<ProductGroupData> groups) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: widget.selectedGroupId,
            decoration: InputDecoration(
              labelText: '商品组（批量录入变体）',
              hintText: '选择商品组以批量录入变体',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('无（普通商品）'),
              ),
              ...groups.map((g) => DropdownMenuItem<int?>(
                    value: g.id,
                    child: Text(g.name),
                  )),
            ],
            onChanged: widget.enabled
                ? (value) {
                    widget.onGroupChanged(value);
                    // 选择商品组后，如果变体列表为空，自动添加一个
                    if (value != null && widget.variants.isEmpty) {
                      _addVariant();
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: '新建商品组',
          onPressed: widget.enabled
              ? () => _showCreateGroupDialog(context)
              : null,
        ),
      ],
    );
  }

  Widget _buildVariantItem(
      BuildContext context, int index, VariantInputData variant) {
    final theme = Theme.of(context);
    final isFirst = index == 0;

    return Dismissible(
      key: Key(variant.id),
      direction: widget.variants.length > 1 ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        margin: EdgeInsets.only(top: isFirst ? 0 : 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _removeVariant(index),
      child: Container(
        margin: EdgeInsets.only(top: isFirst ? 0 : 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _barcodeControllers[variant.id],
                enabled: widget.enabled,
                decoration: InputDecoration(
                  labelText: '条码',
                  hintText: '可选',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: widget.onScanBarcode != null
                      ? IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          onPressed: widget.enabled
                              ? () => _scanBarcodeForVariant(index, variant)
                              : null,
                          tooltip: '扫码',
                        )
                      : null,
                ),
                onChanged: (value) {
                  _updateVariant(index, variant.copyWith(barcode: value));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _nameControllers[variant.id],
                enabled: widget.enabled,
                decoration: InputDecoration(
                  labelText: '变体名称 *',
                  hintText: '如：黄瓜味、大包装',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                onChanged: (value) {
                  _updateVariant(index, variant.copyWith(variantName: value));
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入变体名称';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcodeForVariant(
      int index, VariantInputData variant) async {
    if (widget.onScanBarcode == null) return;
    final barcode = await widget.onScanBarcode!();
    if (barcode != null && barcode.isNotEmpty) {
      _barcodeControllers[variant.id]?.text = barcode;
      _updateVariant(index, variant.copyWith(barcode: barcode));
    }
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建商品组'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '商品组名称',
            hintText: '如：乐事薯片',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final model = ProductGroupModel(name: result.trim());
      final id = await ref
          .read(productGroupOperationsProvider.notifier)
          .createProductGroup(model);
      if (id != null) {
        widget.onGroupChanged(id);
        // 自动添加第一个变体
        if (widget.variants.isEmpty) {
          _addVariant();
        }
      }
    }
  }
}
