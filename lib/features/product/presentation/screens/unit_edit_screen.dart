import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/barcode.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/unit_draft_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import 'unit_selection_screen.dart';

/// 单位编辑屏幕
/// 用于编辑产品的基本单位和辅单位配置
/// 基本单位从产品编辑页面传入，辅单位从数据库获取
class UnitEditScreen extends ConsumerStatefulWidget {
  final String? productId;
  final String? baseUnitId; // 基本单位ID（从产品编辑页传入）
  final String? baseUnitName; // 基本单位名称（从产品编辑页传入）

  const UnitEditScreen({
    super.key,
    this.productId,
    this.baseUnitId,
    this.baseUnitName,
  });

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
    print('🔧 UnitEditScreen: baseUnitId = ${widget.baseUnitId}');
    print('🔧 UnitEditScreen: baseUnitName = ${widget.baseUnitName}');

    // 1. 初始化基本单位（从产品编辑页传入）
    await _initializeBaseUnit();

    // 2. 初始化辅单位（从数据库获取）
    await _initializeAuxiliaryUnits();
  }

  /// 初始化基本单位（从产品编辑页传入的参数）
  Future<void> _initializeBaseUnit() async {
    if (widget.baseUnitId != null && widget.baseUnitName != null) {
      try {
        // 从传入的参数创建基本单位
        final baseUnit = Unit(
          id: widget.baseUnitId!,
          name: widget.baseUnitName!,
        );

        if (mounted) {
          setState(() {
            _baseUnit = baseUnit;
            _baseUnitController.text = baseUnit.name;
          });
        }
        print('🔧 UnitEditScreen: 基本单位初始化完成: ${baseUnit.name}');
      } catch (e) {
        print('🔧 UnitEditScreen: 基本单位初始化失败: $e');
      }
    } else {
      print('🔧 UnitEditScreen: 没有传入基本单位信息');
    }
  }

  /// 初始化辅单位（从数据库获取现有配置）
  Future<void> _initializeAuxiliaryUnits() async {
    if (widget.productId == null) {
      print('🔧 UnitEditScreen: 新产品，跳过辅单位初始化');
      return;
    }

    try {
      // 首先检查是否有草稿数据
      final draftData = ref
          .read(unitEditDraftProvider.notifier)
          .getDraft(widget.productId!);

      List<ProductUnit>? auxiliaryUnits;

      if (draftData != null && draftData.isNotEmpty) {
        print('🔧 UnitEditScreen: 发现草稿数据，使用草稿数据加载辅单位');
        // 过滤出辅单位（换算率不为1.0的单位）
        auxiliaryUnits = draftData
            .where((pu) => pu.conversionRate != 1.0)
            .toList();
      } else {
        print('🔧 UnitEditScreen: 从数据库获取辅单位配置');
        // 从数据库获取产品的所有单位配置
        final productUnitController = ref.read(
          productUnitControllerProvider.notifier,
        );
        final allProductUnits = await productUnitController
            .getProductUnitsByProductId(widget.productId!);
        // 过滤出辅单位（换算率不为1.0的单位）
        auxiliaryUnits = allProductUnits
            .where((pu) => pu.conversionRate != 1.0)
            .toList();
      }

      if (auxiliaryUnits.isNotEmpty) {
        print('🔧 UnitEditScreen: 发现 ${auxiliaryUnits.length} 个辅单位配置');
        await _loadAuxiliaryUnits(auxiliaryUnits);
      } else {
        print('🔧 UnitEditScreen: 没有辅单位配置');
      }
    } catch (e) {
      print('🔧 UnitEditScreen: 初始化辅单位失败: $e');
    }
  }

  /// 加载辅单位配置
  Future<void> _loadAuxiliaryUnits(List<ProductUnit> auxiliaryUnits) async {
    final List<_AuxiliaryUnit> tempAuxiliaryUnits = [];

    for (final productUnit in auxiliaryUnits) {
      print(
        '🔧 UnitEditScreen: 处理辅单位 ${productUnit.unitId}, 换算率: ${productUnit.conversionRate}',
      );

      try {
        // 获取单位信息
        final allUnits = await ref.read(allUnitsProvider.future);
        final unit = allUnits.firstWhere(
          (u) => u.id == productUnit.unitId,
          orElse: () =>
              throw Exception('Unit not found: ${productUnit.unitId}'),
        );

        // 创建辅单位对象
        final auxiliaryUnit = _AuxiliaryUnit(
          id: _auxiliaryCounter,
          unit: unit,
          conversionRate: productUnit.conversionRate,
          onDataChanged: _autoSaveDraft,
        );

        // 设置UI控制器的值
        auxiliaryUnit.unitController.text = unit.name;

        // 设置建议零售价
        if (productUnit.sellingPrice != null) {
          auxiliaryUnit.retailPriceController.text = productUnit.sellingPrice!
              .toString();
        }

        // 获取条码信息
        final barcodeController = ref.read(barcodeControllerProvider.notifier);
        final barcodes = await barcodeController.getBarcodesByProductUnitId(
          productUnit.productUnitId,
        );
        if (barcodes.isNotEmpty) {
          auxiliaryUnit.barcodeController.text = barcodes.first.barcode;
        }

        tempAuxiliaryUnits.add(auxiliaryUnit);
        _auxiliaryCounter++;
      } catch (e) {
        print('🔧 UnitEditScreen: 加载辅单位失败 ${productUnit.unitId}: $e');
      }
    }

    // 更新UI状态
    if (mounted && tempAuxiliaryUnits.isNotEmpty) {
      setState(() {
        _auxiliaryUnits.clear();
        _auxiliaryUnits.addAll(tempAuxiliaryUnits);
      });
      print('🔧 UnitEditScreen: 辅单位UI状态更新完成，共 ${tempAuxiliaryUnits.length} 个');
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
                  helperText: '可直接输入单位名称，如：个、箱、包、瓶等',
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
                ).primaryColor.withValues(alpha: 0.1),
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
                    ).primaryColor.withValues(alpha: 0.1),
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

  /// 保存辅单位条码
  /// 为所有有条码输入的辅单位创建或更新条码记录
  Future<void> _saveAuxiliaryUnitBarcodes(
    List<ProductUnit> productUnits,
  ) async {
    try {
      final barcodeController = ref.read(barcodeControllerProvider.notifier);
      int savedCount = 0;
      int skippedCount = 0;

      // 遍历所有辅单位，处理条码数据
      for (int i = 0; i < _auxiliaryUnits.length; i++) {
        final auxiliaryUnit = _auxiliaryUnits[i];
        final barcodeText = auxiliaryUnit.barcodeController.text.trim();

        // 找到对应的ProductUnit
        final productUnit = productUnits.firstWhere(
          (pu) => pu.unitId == auxiliaryUnit.unit?.id,
          orElse: () => ProductUnit(
            productUnitId: '',
            productId: '',
            unitId: '',
            conversionRate: 1.0,
            lastUpdated: DateTime.now(),
          ),
        );

        if (productUnit.productUnitId.isEmpty) {
          print(
            '🔧 UnitEditScreen: 未找到对应的ProductUnit，跳过处理单位: ${auxiliaryUnit.unit?.name}',
          );
          continue;
        }

        // 获取该产品单位现有的所有条码
        final existingBarcodes = await barcodeController
            .getBarcodesByProductUnitId(productUnit.productUnitId);

        // 如果没有输入新条码
        if (barcodeText.isEmpty) {
          // 删除该产品单位的所有现有条码
          if (existingBarcodes.isNotEmpty) {
            for (final barcode in existingBarcodes) {
              await barcodeController.deleteBarcode(barcode.id);
            }
            print('🔧 UnitEditScreen: 删除了 ${existingBarcodes.length} 个旧条码');
          }
          continue;
        }

        // 检查新条码是否与现有条码相同
        final sameBarcode = existingBarcodes.firstWhere(
          (barcode) => barcode.barcode == barcodeText,
          orElse: () => Barcode(id: '', productUnitId: '', barcode: ''),
        );

        if (sameBarcode.id.isNotEmpty) {
          // 条码没有变化，不需要更新
          print('🔧 UnitEditScreen: 辅单位条码没有变化，跳过保存: $barcodeText');
          skippedCount++;
          continue;
        }

        // 检查新条码是否在全局范围内已存在
        final globalExistingBarcode = await barcodeController.getBarcodeByValue(
          barcodeText,
        );
        if (globalExistingBarcode != null) {
          print('🔧 UnitEditScreen: 条码已被其他产品使用，跳过保存: $barcodeText');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('条码 $barcodeText 已被其他产品使用'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          skippedCount++;
          continue;
        }

        // 删除该产品单位的所有旧条码
        for (final barcode in existingBarcodes) {
          await barcodeController.deleteBarcode(barcode.id);
        }

        // 创建新的条码记录
        final newBarcode = Barcode(
          id: 'barcode_${DateTime.now().millisecondsSinceEpoch}_$i',
          productUnitId: productUnit.productUnitId,
          barcode: barcodeText,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 保存新条码
        await barcodeController.addBarcode(newBarcode);
        savedCount++;
        print('🔧 UnitEditScreen: 辅单位条码保存成功: $barcodeText');
      }

      // 显示保存结果
      if (mounted) {
        if (savedCount > 0) {
          final message = skippedCount > 0
              ? '保存了 $savedCount 个条码，跳过 $skippedCount 个'
              : '成功保存 $savedCount 个条码';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (skippedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所有条码都已是最新状态'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      print('🔧 UnitEditScreen: 条码处理完成 - 保存: $savedCount, 跳过: $skippedCount');
    } catch (e) {
      print('🔧 UnitEditScreen: 辅单位条码处理失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('条码处理失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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

    // 保存辅单位条码（如果有条码输入）
    await _saveAuxiliaryUnitBarcodes(productUnits);

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
