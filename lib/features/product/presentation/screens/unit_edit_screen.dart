import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../application/provider/unit_providers.dart';
import 'unit_selection_screen.dart';

/// 单位编辑屏幕
/// 用于编辑产品的基本单位和辅单位配置
class UnitEditScreen extends ConsumerStatefulWidget {
  final String? productId;
  final List<ProductUnit>? initialProductUnits;

  const UnitEditScreen({super.key, this.productId, this.initialProductUnits});

  @override
  ConsumerState<UnitEditScreen> createState() => _UnitEditScreenState();
}

class _UnitEditScreenState extends ConsumerState<UnitEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // 基本单位
  Unit? _baseUnit;
  late TextEditingController _baseUnitController;

  // 辅单位列表
  final List<_AuxiliaryUnit> _auxiliaryUnits = [];

  // 辅单位计数器
  int _auxiliaryCounter = 1;
  @override
  void initState() {
    super.initState();
    _baseUnitController = TextEditingController();
    // 使用 WidgetsBinding.instance.addPostFrameCallback 来确保在 build 完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUnits();
    });
  }

  @override
  void dispose() {
    _baseUnitController.dispose();
    for (final aux in _auxiliaryUnits) {
      aux.dispose();
    }
    super.dispose();
  }

  /// 初始化单位数据
  void _initializeUnits() async {
    print('🔧 UnitEditScreen: 开始初始化单位数据');
    print(
      '🔧 UnitEditScreen: initialProductUnits = ${widget.initialProductUnits}',
    );

    if (widget.initialProductUnits != null &&
        widget.initialProductUnits!.isNotEmpty) {
      print(
        '🔧 UnitEditScreen: 发现 ${widget.initialProductUnits!.length} 个初始单位',
      );

      // 临时存储要添加的辅单位
      final List<_AuxiliaryUnit> tempAuxiliaryUnits = [];
      Unit? tempBaseUnit;

      for (final productUnit in widget.initialProductUnits!) {
        print(
          '🔧 UnitEditScreen: 处理单位 ${productUnit.unitId}, 换算率: ${productUnit.conversionRate}',
        );

        try {
          // 使用 ref.read 获取 Unit 对象
          final allUnits = await ref.read(allUnitsProvider.future);
          print('🔧 UnitEditScreen: 获取到 ${allUnits.length} 个可用单位');

          final unit = allUnits.firstWhere(
            (u) => u.id == productUnit.unitId,
            orElse: () =>
                throw Exception('Unit not found: ${productUnit.unitId}'),
          );

          if (productUnit.conversionRate == 1.0) {
            // 基本单位
            print('🔧 UnitEditScreen: 设置基本单位: ${unit.name}');
            tempBaseUnit = unit;
          } else {
            // 辅单位
            print(
              '🔧 UnitEditScreen: 添加辅单位: ${unit.name}, 换算率: ${productUnit.conversionRate}',
            );
            tempAuxiliaryUnits.add(
              _AuxiliaryUnit(
                id: _auxiliaryCounter,
                unit: unit,
                conversionRate: productUnit.conversionRate,
              ),
            );
            // 设置controller的text
            tempAuxiliaryUnits.last.unitController.text = unit.name;
            _auxiliaryCounter++;
          }
        } catch (e) {
          print('🔧 UnitEditScreen: 加载单位失败 ${productUnit.unitId}: $e');
        }
      }

      // 更新状态
      if (mounted) {
        print(
          '🔧 UnitEditScreen: 更新UI状态 - 基本单位: ${tempBaseUnit?.name}, 辅单位数: ${tempAuxiliaryUnits.length}',
        );
        setState(() {
          _baseUnit = tempBaseUnit;
          _baseUnitController.text = tempBaseUnit?.name ?? '';
          _auxiliaryUnits.clear();
          _auxiliaryUnits.addAll(tempAuxiliaryUnits);
        });
        print('🔧 UnitEditScreen: UI状态更新完成');
      }
    } else {
      print('🔧 UnitEditScreen: 没有初始单位数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单位编辑'),
        actions: [
          // 提交按钮
          IconButton(
            onPressed: _canSubmit() ? _submitForm : null,
            icon: const Icon(Icons.check),
            tooltip: '保存',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本单位部分
              _buildBaseUnitSection(),

              const SizedBox(height: 24),

              // 辅单位部分
              _buildAuxiliaryUnitsSection(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建基本单位部分
  Widget _buildBaseUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本单位',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: '请选择基本单位',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                controller: _baseUnitController,
                validator: (value) {
                  if (_baseUnit == null) {
                    return '请选择基本单位';
                  }
                  return null;
                },
                onTap: _selectBaseUnit,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _selectBaseUnit,
              icon: const Icon(Icons.search),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建辅单位部分
  Widget _buildAuxiliaryUnitsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 如果没有辅单位，显示添加按钮和提示文本在顶部
          if (_auxiliaryUnits.isEmpty) ...[
            Row(
              children: [
                FloatingActionButton.small(
                  onPressed: _addAuxiliaryUnit,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
                const Text(
                  '添加辅单位',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],

          // 辅单位列表
          Expanded(
            child: ListView.builder(
              itemCount: _auxiliaryUnits.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    _buildAuxiliaryUnitItem(index),
                    // 如果是最后一项，显示添加按钮
                    if (index == _auxiliaryUnits.length - 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          FloatingActionButton.small(
                            onPressed: _addAuxiliaryUnit,
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '添加辅单位',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建辅单位项
  Widget _buildAuxiliaryUnitItem(int index) {
    final auxiliaryUnit = _auxiliaryUnits[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 辅单位标题和删除按钮
            Row(
              children: [
                Text(
                  '辅单位${auxiliaryUnit.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeAuxiliaryUnit(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 单位选择
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: '请选择单位',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    controller: auxiliaryUnit.unitController,
                    validator: (value) {
                      if (auxiliaryUnit.unit == null) {
                        return '请选择单位';
                      }
                      return null;
                    },
                    onTap: () => _selectAuxiliaryUnit(index),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _selectAuxiliaryUnit(index),
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 换算率输入
            TextFormField(
              decoration: const InputDecoration(
                labelText: '换算率',
                hintText: '请输入换算率',
                border: OutlineInputBorder(),
                suffixText: '(相对于基本单位)',
              ),
              keyboardType: TextInputType.number,
              initialValue: auxiliaryUnit.conversionRate > 0
                  ? auxiliaryUnit.conversionRate.toString()
                  : '',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入换算率';
                }
                final rate = double.tryParse(value.trim());
                if (rate == null || rate <= 0) {
                  return '请输入有效的换算率';
                }
                if (rate == 1.0) {
                  return '辅单位换算率不能为1';
                }
                return null;
              },
              onChanged: (value) {
                final rate = double.tryParse(value.trim());
                if (rate != null) {
                  auxiliaryUnit.conversionRate = rate;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 选择基本单位
  void _selectBaseUnit() async {
    final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => const UnitSelectionScreen(isSelectionMode: true),
      ),
    );
    if (selectedUnit != null) {
      setState(() {
        _baseUnit = selectedUnit;
        _baseUnitController.text = selectedUnit.name;
      });
    }
  }

  /// 选择辅单位
  void _selectAuxiliaryUnit(int index) async {
    final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => const UnitSelectionScreen(isSelectionMode: true),
      ),
    );

    if (selectedUnit != null) {
      // 检查是否与基本单位重复
      if (_baseUnit != null && selectedUnit.id == _baseUnit!.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('辅单位不能与基本单位相同'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 检查是否与其他辅单位重复
      final existingIndex = _auxiliaryUnits.indexWhere(
        (aux) => aux.unit?.id == selectedUnit.id,
      );
      if (existingIndex != -1 && existingIndex != index) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('该单位已被其他辅单位使用'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      setState(() {
        _auxiliaryUnits[index].unit = selectedUnit;
        _auxiliaryUnits[index].unitController.text = selectedUnit.name;
      });
    }
  }

  /// 添加辅单位
  void _addAuxiliaryUnit() {
    setState(() {
      _auxiliaryUnits.add(
        _AuxiliaryUnit(id: _auxiliaryCounter, unit: null, conversionRate: 0),
      );
      _auxiliaryCounter++;
    });
  }

  /// 删除辅单位
  void _removeAuxiliaryUnit(int index) {
    setState(() {
      _auxiliaryUnits[index].dispose();
      _auxiliaryUnits.removeAt(index);
    });
  }

  /// 检查是否可以提交
  bool _canSubmit() {
    return _baseUnit != null;
  }

  /// 提交表单
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 构建ProductUnit列表
    final List<ProductUnit> productUnits = [];

    // 添加基本单位
    if (_baseUnit != null) {
      productUnits.add(
        ProductUnit(
          productUnitId: '${widget.productId ?? 'new'}_${_baseUnit!.id}',
          productId: widget.productId ?? 'new',
          unitId: _baseUnit!.id,
          conversionRate: 1.0,
        ),
      );
    }

    // 添加辅单位
    for (final aux in _auxiliaryUnits) {
      if (aux.unit != null && aux.conversionRate > 0) {
        productUnits.add(
          ProductUnit(
            productUnitId: '${widget.productId ?? 'new'}_${aux.unit!.id}',
            productId: widget.productId ?? 'new',
            unitId: aux.unit!.id,
            conversionRate: aux.conversionRate,
          ),
        );
      }
    }

    // 显示配置完成提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单位配置完成'), backgroundColor: Colors.green),
      );
    }

    // 返回配置结果，由调用方决定何时保存
    Navigator.of(context).pop(productUnits);
  }
}

/// 辅单位数据类
class _AuxiliaryUnit {
  final int id;
  Unit? unit;
  double conversionRate;
  late TextEditingController unitController;

  _AuxiliaryUnit({required this.id, this.unit, required this.conversionRate}) {
    unitController = TextEditingController(text: unit?.name ?? '');
  }

  void dispose() {
    unitController.dispose();
  }
}
