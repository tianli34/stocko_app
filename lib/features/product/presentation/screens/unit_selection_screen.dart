import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/provider/unit_providers.dart';
import '../../domain/model/unit.dart';
import '../../../../core/shared_widgets/loading_widget.dart';
import '../../../../core/shared_widgets/error_widget.dart';
import '../widgets/unit_list_tile.dart';

/// 单位选择屏幕
/// 支持选择单位、新增单位及删除单位操作
class UnitSelectionScreen extends ConsumerStatefulWidget {
  final String? selectedUnitId;
  final bool isSelectionMode;

  const UnitSelectionScreen({
    super.key,
    this.selectedUnitId,
    this.isSelectionMode = true,
  });

  @override
  ConsumerState<UnitSelectionScreen> createState() =>
      _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends ConsumerState<UnitSelectionScreen> {
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.selectedUnitId;
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsyncValue = ref.watch(allUnitsProvider);
    final controllerState = ref.watch(unitControllerProvider);

    // 监听操作结果
    ref.listen<UnitControllerState>(unitControllerProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功'), backgroundColor: Colors.green),
        );
      } else if (next.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? '操作失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? '选择单位' : '单位管理'),
        actions: [
          IconButton(
            onPressed: () => _showAddUnitDialog(context),
            icon: const Icon(Icons.add),
            tooltip: '新增单位',
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作状态指示器
          if (controllerState.isLoading) const LinearProgressIndicator(),

          // 单位列表
          Expanded(
            child: unitsAsyncValue.when(
              data: (units) => _buildUnitList(context, units),
              loading: () => const LoadingWidget(message: '加载单位列表中...'),
              error: (error, stackTrace) => CustomErrorWidget(
                message: '加载单位列表失败',
                onRetry: () => ref.invalidate(allUnitsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单位列表
  Widget _buildUnitList(BuildContext context, List<Unit> units) {
    if (units.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无单位', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              '点击右上角的 + 号添加新单位',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUnitsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          return _buildUnitTile(context, unit);
        },
      ),
    );
  }

  /// 构建单位列表项
  Widget _buildUnitTile(BuildContext context, Unit unit) {
    final isSelected = _selectedUnitId == unit.id;

    if (widget.isSelectionMode) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: ListTile(
          title: Text(
            unit.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedUnitId = unit.id;
            });
            // 直接确认选择并返回
            _confirmSelection();
          },
        ),
      );
    } else {
      return UnitListTile(
        unit: unit,
        isSelected: isSelected,
        onEdit: () => _showEditUnitDialog(context, unit),
        onDelete: () => _showDeleteUnitDialog(context, unit),
        showActions: true,
      );
    }
  }

  /// 显示新增单位对话框
  void _showAddUnitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增单位'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '单位名称',
              hintText: '请输入单位名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入单位名称';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final unitName = nameController.text.trim();

                // 检查单位名称是否已存在
                final controller = ref.read(unitControllerProvider.notifier);
                final exists = await controller.isUnitNameExists(unitName);

                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('单位名称已存在'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final unit = Unit(
                  id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
                  name: unitName,
                );

                await controller.addUnit(unit);

                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑单位对话框
  void _showEditUnitDialog(BuildContext context, Unit unit) {
    final nameController = TextEditingController(text: unit.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑单位'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '单位名称',
              hintText: '请输入单位名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入单位名称';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final unitName = nameController.text.trim();

                // 检查单位名称是否已存在（排除当前单位）
                final controller = ref.read(unitControllerProvider.notifier);
                final exists = await controller.isUnitNameExists(
                  unitName,
                  unit.id,
                );

                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('单位名称已存在'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final updatedUnit = unit.copyWith(name: unitName);
                await controller.updateUnit(updatedUnit);

                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除单位确认对话框
  void _showDeleteUnitDialog(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除单位 "${unit.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final controller = ref.read(unitControllerProvider.notifier);
              await controller.deleteUnit(unit.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 确认选择单位
  void _confirmSelection() {
    if (_selectedUnitId != null) {
      final units = ref.read(allUnitsProvider).value ?? [];
      final selectedUnit = units.firstWhere(
        (unit) => unit.id == _selectedUnitId,
        orElse: () => throw Exception('选中的单位不存在'),
      );

      Navigator.of(context).pop(selectedUnit);
    }
  }
}
