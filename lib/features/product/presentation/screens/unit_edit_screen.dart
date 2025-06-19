import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/unit_draft_providers.dart';
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
    _baseUnitController = TextEditingController(text: '个'); // 默认单位为"个"
    // 设置默认基本单位
    _setDefaultBaseUnit();
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

  /// 设置默认基本单位为"个"
  void _setDefaultBaseUnit() async {
    try {
      final allUnits = await ref.read(allUnitsProvider.future);
      final defaultUnit = allUnits.firstWhere(
        (unit) => unit.name == '个',
        orElse: () => Unit(id: 'default_unit_ge', name: '个'),
      );

      if (mounted) {
        setState(() {
          _baseUnit = defaultUnit;
        });
      }
    } catch (e) {
      // 如果无法获取单位数据，创建一个默认的"个"单位
      final defaultUnit = Unit(id: 'default_unit_ge', name: '个');

      if (mounted) {
        setState(() {
          _baseUnit = defaultUnit;
        });
      }
    }
  }

  /// 初始化单位数据
  void _initializeUnits() async {
    print('🔧 UnitEditScreen: 开始初始化单位数据');
    print(
      '🔧 UnitEditScreen: initialProductUnits = ${widget.initialProductUnits}',
    );

    // 首先检查是否有草稿数据
    List<ProductUnit>? dataToLoad = widget.initialProductUnits;

    if (widget.productId != null) {
      final draftData = ref
          .read(unitEditDraftProvider.notifier)
          .getDraft(widget.productId!);
      if (draftData != null && draftData.isNotEmpty) {
        print('🔧 UnitEditScreen: 发现草稿数据，使用草稿数据加载');
        dataToLoad = draftData;
      }
    }

    if (dataToLoad != null && dataToLoad.isNotEmpty) {
      print('🔧 UnitEditScreen: 发现 ${dataToLoad.length} 个单位数据');

      // 临时存储要添加的辅单位
      final List<_AuxiliaryUnit> tempAuxiliaryUnits = [];
      Unit? tempBaseUnit;

      for (final productUnit in dataToLoad) {
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
            final auxiliaryUnit = _AuxiliaryUnit(
              id: _auxiliaryCounter,
              unit: unit,
              conversionRate: productUnit.conversionRate,
              onDataChanged: _autoSaveDraft, // 传递自动保存回调
            );

            // 设置controller的text
            auxiliaryUnit.unitController.text = unit.name;

            // 设置条码和建议零售价
            if (productUnit.barcode != null &&
                productUnit.barcode!.isNotEmpty) {
              auxiliaryUnit.barcodeController.text = productUnit.barcode!;
            }
            if (productUnit.sellingPrice != null) {
              auxiliaryUnit.retailPriceController.text = productUnit
                  .sellingPrice!
                  .toString();
            }

            tempAuxiliaryUnits.add(auxiliaryUnit);
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
                decoration: const InputDecoration(
                  hintText: '请输入基本单位名称',
                  border: OutlineInputBorder(),
                  helperText: '默认为"个"，可直接输入其他单位名称',
                ),
                controller: _baseUnitController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入基本单位名称';
                  }
                  return null;
                },
                onChanged: (value) {
                  _onBaseUnitNameChanged(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _selectBaseUnit(),
              icon: const Icon(Icons.list),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                foregroundColor: Theme.of(context).primaryColor,
              ),
              tooltip: '选择单位',
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
              padding: const EdgeInsets.only(bottom: 80), // 添加底部边距避免遮挡
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
                  '辅单位${index + 1}',
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
            const SizedBox(height: 12), // 单位选择
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: '请输入单位名称',
                      border: OutlineInputBorder(),
                      helperText: '可直接输入单位名称，如：箱、包、瓶等',
                    ),
                    controller: auxiliaryUnit.unitController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入单位名称';
                      }
                      return null;
                    },
                    onChanged: (value) =>
                        _onAuxiliaryUnitNameChanged(index, value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _selectAuxiliaryUnit(index),
                  icon: const Icon(Icons.list),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  tooltip: '选择单位',
                ),
              ],
            ),
            const SizedBox(height: 12), // 换算率输入
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
                  _autoSaveDraft(); // 自动保存草稿
                }
              },
            ),

            const SizedBox(height: 12), // 条码输入
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: auxiliaryUnit.barcodeController,
                    decoration: const InputDecoration(
                      labelText: '条码',
                      hintText: '请输入或扫描条码',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _scanBarcode(index),
                  icon: const Icon(Icons.qr_code_scanner),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  tooltip: '扫描条码',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 建议零售价输入
            TextFormField(
              controller: auxiliaryUnit.retailPriceController,
              decoration: const InputDecoration(
                labelText: '建议零售价',
                hintText: '请输入建议零售价',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final price = double.tryParse(value.trim());
                  if (price == null || price < 0) {
                    return '请输入有效的价格';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 处理基本单位名称变化
  void _onBaseUnitNameChanged(String unitName) async {
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _baseUnit = null;
      });
      return;
    }

    try {
      // 首先查找现有单位
      final allUnits = await ref.read(allUnitsProvider.future);
      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit(id: '', name: ''), // 临时占位符
      );

      // 如果找不到现有单位，创建新单位
      if (existingUnit.id.isEmpty) {
        existingUnit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmedName,
        );
      }

      setState(() {
        _baseUnit = existingUnit;
      });
      _autoSaveDraft(); // 自动保存草稿
    } catch (e) {
      print('处理基本单位名称变化失败: $e');
    }
  }

  /// 处理辅单位名称变化
  void _onAuxiliaryUnitNameChanged(int index, String unitName) async {
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _auxiliaryUnits[index].unit = null;
      });
      return;
    }

    try {
      // 首先查找现有单位
      final allUnits = await ref.read(allUnitsProvider.future);
      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit(id: '', name: ''), // 临时占位符
      );

      // 如果找不到现有单位，创建新单位
      if (existingUnit.id.isEmpty) {
        existingUnit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmedName,
        );
      }

      // 检查是否与基本单位重复
      if (_baseUnit != null && existingUnit.name == _baseUnit!.name) {
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
        (aux) => aux.unit?.name == existingUnit!.name,
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
        _auxiliaryUnits[index].unit = existingUnit;
      });
      _autoSaveDraft(); // 自动保存草稿
    } catch (e) {
      print('处理辅单位名称变化失败: $e');
    }
  }

  /// 添加辅单位
  void _addAuxiliaryUnit() {
    setState(() {
      _auxiliaryUnits.add(
        _AuxiliaryUnit(
          id: _auxiliaryCounter,
          unit: null,
          conversionRate: 0,
          onDataChanged: _autoSaveDraft, // 传递自动保存回调
        ),
      );
      _auxiliaryCounter++;
    });
    _autoSaveDraft(); // 自动保存草稿
  }

  /// 删除辅单位
  void _removeAuxiliaryUnit(int index) {
    setState(() {
      _auxiliaryUnits[index].dispose();
      _auxiliaryUnits.removeAt(index);
    });
    _autoSaveDraft(); // 自动保存草稿
  }

  /// 选择基本单位
  void _selectBaseUnit() async {
    try {
      final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
        MaterialPageRoute(
          builder: (context) => UnitSelectionScreen(
            selectedUnitId: _baseUnit?.id,
            isSelectionMode: true,
          ),
        ),
      );

      if (selectedUnit != null) {
        setState(() {
          _baseUnit = selectedUnit;
          _baseUnitController.text = selectedUnit.name;
        });
        _autoSaveDraft(); // 自动保存草稿
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择单位失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 选择辅单位
  void _selectAuxiliaryUnit(int index) async {
    try {
      final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
        MaterialPageRoute(
          builder: (context) => UnitSelectionScreen(
            selectedUnitId: _auxiliaryUnits[index].unit?.id,
            isSelectionMode: true,
          ),
        ),
      );

      if (selectedUnit != null) {
        // 检查是否与基本单位重复
        if (_baseUnit != null && selectedUnit.name == _baseUnit!.name) {
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
          (aux) => aux.unit?.name == selectedUnit.name,
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
        _autoSaveDraft(); // 自动保存草稿
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择单位失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 扫描条码
  void _scanBarcode(int index) async {
    try {
      final String? barcode = await BarcodeScannerService.scanForProduct(
        context,
      );

      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _auxiliaryUnits[index].barcodeController.text = barcode;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('扫描成功: $barcode'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 检查是否可以提交
  bool _canSubmit() {
    return _baseUnit != null && _baseUnitController.text.trim().isNotEmpty;
  }

  /// 构建ProductUnit列表的通用方法
  List<ProductUnit> _buildProductUnits() {
    final List<ProductUnit> productUnits = [];

    // 添加基本单位
    if (_baseUnit != null) {
      productUnits.add(
        ProductUnit(
          productUnitId: '${widget.productId ?? 'new'}_${_baseUnit!.id}',
          productId: widget.productId ?? 'new',
          unitId: _baseUnit!.id,
          conversionRate: 1.0,
          // 基本单位暂不设置条码和售价，这些信息在产品主表中管理
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
            barcode: aux.barcodeController.text.trim().isNotEmpty
                ? aux.barcodeController.text.trim()
                : null,
            sellingPrice: aux.retailPriceController.text.trim().isNotEmpty
                ? double.tryParse(aux.retailPriceController.text.trim())
                : null,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }

    return productUnits;
  }

  /// 自动保存草稿（每次数据变更时调用）
  void _autoSaveDraft() {
    if (widget.productId != null && _baseUnit != null) {
      final productUnits = _buildProductUnits();
      if (productUnits.isNotEmpty) {
        ref
            .read(unitEditDraftProvider.notifier)
            .saveDraft(widget.productId!, productUnits);
      }
    }
  }

  /// 提交表单
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 构建ProductUnit列表
    final List<ProductUnit> productUnits = _buildProductUnits();

    // 自动保存草稿（每次提交时都保存当前状态，下次进入还能看到）
    if (widget.productId != null && productUnits.isNotEmpty) {
      ref
          .read(unitEditDraftProvider.notifier)
          .saveDraft(widget.productId!, productUnits);
    }

    // 显示配置完成提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单位配置已保存'), backgroundColor: Colors.green),
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
  late TextEditingController barcodeController;
  late TextEditingController retailPriceController;
  VoidCallback? onDataChanged; // 添加数据变更回调

  _AuxiliaryUnit({
    required this.id,
    this.unit,
    required this.conversionRate,
    this.onDataChanged,
  }) {
    unitController = TextEditingController(text: unit?.name ?? '');
    barcodeController = TextEditingController();
    retailPriceController = TextEditingController();

    // 添加监听器，当条码或零售价变化时触发回调
    barcodeController.addListener(() {
      onDataChanged?.call();
    });
    retailPriceController.addListener(() {
      onDataChanged?.call();
    });
  }
  void dispose() {
    unitController.dispose();
    barcodeController.dispose();
    retailPriceController.dispose();
  }
}
