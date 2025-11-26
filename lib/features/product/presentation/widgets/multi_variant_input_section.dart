import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool get isEmpty => variantName.trim().isEmpty && barcode.trim().isEmpty;
}

/// 多变体录入区域组件（开关模式）
/// 
/// 新方案：
/// - 商品组开关：开启后显示变体列表
/// - 商品名称字段在开关开启时由外部切换为下拉框
class MultiVariantInputSection extends ConsumerStatefulWidget {
  final bool isProductGroupEnabled;
  final List<VariantInputData> variants;
  final ValueChanged<bool> onProductGroupEnabledChanged;
  final ValueChanged<List<VariantInputData>> onVariantsChanged;
  final bool enabled;
  final Future<String?> Function()? onScanBarcode;

  const MultiVariantInputSection({
    super.key,
    required this.isProductGroupEnabled,
    required this.variants,
    required this.onProductGroupEnabledChanged,
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
    for (final variant in widget.variants) {
      _ensureControllers(variant);
    }
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

  /// 处理开关切换
  Future<void> _handleSwitchChanged(bool value) async {
    if (!value && widget.variants.isNotEmpty) {
      // 关闭开关时，如果有变体数据，提示用户
      final hasData = widget.variants.any(
          (v) => v.variantName.trim().isNotEmpty || v.barcode.trim().isNotEmpty);
      if (hasData) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认关闭'),
            content: const Text('关闭商品组将清除已录入的变体数据，是否继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确认'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
      // 清除变体数据
      widget.onVariantsChanged([]);
    } else if (value && widget.variants.isEmpty) {
      // 开启开关时，自动添加一个空变体
      _addVariant();
    }
    widget.onProductGroupEnabledChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 商品组开关
        _buildGroupSwitch(context),

        // 商品组开启时：显示变体列表
        if (widget.isProductGroupEnabled) ...[
          const SizedBox(height: 16),
          _buildVariantList(context, theme),
        ],
      ],
    );
  }

  /// 构建商品组开关
  Widget _buildGroupSwitch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            color: widget.isProductGroupEnabled
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启用商品组',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '开启后可批量录入同组变体商品',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.isProductGroupEnabled,
            onChanged: widget.enabled ? _handleSwitchChanged : null,
          ),
        ],
      ),
    );
  }

  /// 构建变体列表
  Widget _buildVariantList(BuildContext context, ThemeData theme) {
    return Container(
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
              Icon(Icons.list_alt, size: 20, color: theme.primaryColor),
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
            '商品名称将作为商品组名称，每个变体将创建独立商品',
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
    );
  }

  Widget _buildVariantItem(
      BuildContext context, int index, VariantInputData variant) {
    final isFirst = index == 0;

    return Dismissible(
      key: Key(variant.id),
      direction: widget.variants.length > 1
          ? DismissDirection.endToStart
          : DismissDirection.none,
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
                  hintText: '如：黄瓜味',
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
}
