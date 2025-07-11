import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/auxiliary_unit_data.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import 'unit_selection_screen.dart';

class UnitEditScreen extends ConsumerStatefulWidget {
  final String? productId;
  final String? baseUnitId;
  final String? baseUnitName;

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

  final List<_AuxiliaryUnit> _auxiliaryUnits = [];

  int _auxiliaryCounter = 1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUnits();
    });
  }

  @override
  void dispose() {
    for (final aux in _auxiliaryUnits) {
      aux.dispose();
    }
    super.dispose();
  }

  void _initializeUnits() async {
    print('🔍 _initializeUnits: productId=${widget.productId}');
    // 如果是编辑模式（有productId），优先从数据库加载现有数据
    if (widget.productId != null) {
      print('🔍 编辑模式，调用_initializeAuxiliaryUnits');
      await _initializeAuxiliaryUnits();
      return;
    }

    // 如果是新增模式，检查是否有持久化数据
    final formState = ref.read(unitEditFormProvider);
    final hasPersistedData = formState.auxiliaryUnits.isNotEmpty;
    print('🔍 新增模式，hasPersistedData=$hasPersistedData');

    if (hasPersistedData) {
      print('🔍 加载持久化数据');
      _loadFromFormProvider();
      return;
    }

    print('🔍 无持久化数据，调用_initializeAuxiliaryUnits');
    await _initializeAuxiliaryUnits();
  }

  Future<void> _initializeAuxiliaryUnits() async {
    print('🔍 _initializeAuxiliaryUnits 开始');
    try {
      final formState = ref.read(unitEditFormProvider);
      print(
        '🔍 formState.auxiliaryUnits.length=${formState.auxiliaryUnits.length}',
      );
      if (formState.auxiliaryUnits.isNotEmpty) {
        print('🔍 从表单数据加载');
        await _loadAuxiliaryUnitsFromFormData(formState.auxiliaryUnits);
        _auxiliaryCounter = formState.auxiliaryCounter;
        return;
      }
      if (widget.productId != null) {
        print('🔍 从数据库加载辅单位');
        final productUnitController = ref.read(
          productUnitControllerProvider.notifier,
        );
        final allProductUnits = await productUnitController
            .getProductUnitsByProductId(widget.productId!);
        final auxiliaryUnits = allProductUnits
            .where((pu) => pu.conversionRate != 1.0)
            .toList();

        if (auxiliaryUnits.isNotEmpty) {
          await _loadAuxiliaryUnits(auxiliaryUnits);
        } else {
          _addAuxiliaryUnit();
        }
      } else {
        _addAuxiliaryUnit();
      }
    } catch (e, s) {
      debugPrint('Error initializing auxiliary units: $e\n$s');
    }
  }

  Future<void> _loadAuxiliaryUnits(List<ProductUnit> auxiliaryUnits) async {
    final List<_AuxiliaryUnit> tempAuxiliaryUnits = [];

    for (final productUnit in auxiliaryUnits) {
      try {
        final allUnits = await ref.read(allUnitsProvider.future);
        final unit = allUnits.firstWhere(
          (u) => u.id == productUnit.unitId,
          orElse: () =>
              throw Exception('Unit not found: ${productUnit.unitId}'),
        );
        print('🔍 ProductUnit售价: ${productUnit.sellingPrice}');
        final auxiliaryUnit = _AuxiliaryUnit(
          id: _auxiliaryCounter,
          unit: unit,
          conversionRate: productUnit.conversionRate,
          initialSellingPrice: productUnit.sellingPrice,
        );
        print('🔍 控制器初始化后售价: ${auxiliaryUnit.retailPriceController.text}');

        auxiliaryUnit.unitController.text = unit.name;

        final barcodeController = ref.read(barcodeControllerProvider.notifier);
        final barcodes = await barcodeController.getBarcodesByProductUnitId(
          productUnit.productUnitId,
        );
        if (barcodes.isNotEmpty) {
          auxiliaryUnit.barcodeController.text = barcodes.first.barcode;
        }

        tempAuxiliaryUnits.add(auxiliaryUnit);
        _auxiliaryCounter++;
      } catch (e) {}
    }

    if (mounted && tempAuxiliaryUnits.isNotEmpty) {
      setState(() {
        _auxiliaryUnits.clear();
        _auxiliaryUnits.addAll(tempAuxiliaryUnits);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleReturn();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('添加辅单位'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleReturn,
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.baseUnitName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            '基本单位: ${widget.baseUnitName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildAuxiliaryUnitsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuxiliaryUnitsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _auxiliaryUnits.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    _buildAuxiliaryUnitItem(index),
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

  Widget _buildAuxiliaryUnitItem(int index) {
    final auxiliaryUnit = _auxiliaryUnits[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 78, 4, 138),
                  ),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '辅单位名称',
                      border: OutlineInputBorder(),
                    ),
                    controller: auxiliaryUnit.unitController,
                    focusNode: auxiliaryUnit.unitFocusNode,
                    onFieldSubmitted: (_) =>
                        auxiliaryUnit.conversionRateFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入单位名称';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _onAuxiliaryUnitNameChanged(index, value);
                    },
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
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: '换算率',
                border: const OutlineInputBorder(),
                suffixText: '(相对于${widget.baseUnitName ?? '基本单位'})',
              ),
              keyboardType: TextInputType.number,
              focusNode: auxiliaryUnit.conversionRateFocusNode,
              onFieldSubmitted: (_) =>
                  auxiliaryUnit.retailPriceFocusNode.requestFocus(),
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
                  ref
                      .read(unitEditFormProvider.notifier)
                      .updateAuxiliaryUnitConversionRate(
                        auxiliaryUnit.id,
                        rate,
                      );
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: auxiliaryUnit.barcodeController,
                    decoration: const InputDecoration(
                      labelText: '条码',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      ref
                          .read(unitEditFormProvider.notifier)
                          .updateAuxiliaryUnitBarcode(auxiliaryUnit.id, value);
                    },
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
            TextFormField(
              controller: auxiliaryUnit.retailPriceController,
              focusNode: auxiliaryUnit.retailPriceFocusNode,
              decoration: const InputDecoration(
                labelText: '建议零售价',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final price = double.tryParse(value.trim());
                  if (price == null || price < 0) {
                    return '请输入有效的价格';
                  }
                }
                return null;
              },
              onChanged: (value) {
                ref
                    .read(unitEditFormProvider.notifier)
                    .updateAuxiliaryUnitRetailPrice(auxiliaryUnit.id, value);
              },
              onFieldSubmitted: (_) => _handleReturn(),
            ),
          ],
        ),
      ),
    );
  }

  void _onAuxiliaryUnitNameChanged(int index, String unitName) async {
    print('🔍 辅单位名称变更 - 索引: $index, 输入: "$unitName"');
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty) {
      print('🔍 单位名称为空，清除单位');
      setState(() {
        _auxiliaryUnits[index].unit = null;
      });
      ref
          .read(unitEditFormProvider.notifier)
          .updateAuxiliaryUnitName(_auxiliaryUnits[index].id, '');
      return;
    }

    try {
      print('🔍 查找现有单位: "$trimmedName"');
      final allUnits = await ref.read(allUnitsProvider.future);
      print('🔍 数据库中共有 ${allUnits.length} 个单位');

      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit(id: '', name: ''),
      );

      if (existingUnit.id.isEmpty) {
        print('🔍 单位不存在，创建新单位对象: "$trimmedName"');
        existingUnit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmedName,
        );
        print('🔍 新单位对象已创建: ID=${existingUnit.id}, 名称="${existingUnit.name}"');
      } else {
        print('🔍 找到现有单位: ID=${existingUnit.id}, 名称="${existingUnit.name}"');
      }

      if (widget.baseUnitName != null &&
          existingUnit.name == widget.baseUnitName!) {
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
      print('🔍 设置辅单位 $index 的单位为: ${existingUnit.name}');
      setState(() {
        _auxiliaryUnits[index].unit = existingUnit;
      });

      print(
        '🔍 更新表单状态: 辅单位ID=${_auxiliaryUnits[index].id}, 单位ID=${existingUnit.id}',
      );
      ref
          .read(unitEditFormProvider.notifier)
          .updateAuxiliaryUnitName(
            _auxiliaryUnits[index].id,
            trimmedName,
            unitId: existingUnit.id,
          );
      print('✅ 辅单位名称变更完成');
    } catch (e) {
      print('❌ 辅单位名称变更异常: $e');
    }
  }

  void _addAuxiliaryUnit() {
    setState(() {
      _auxiliaryUnits.add(
        _AuxiliaryUnit(id: _auxiliaryCounter, unit: null, conversionRate: 0),
      );
      _auxiliaryCounter++;
    });

    ref.read(unitEditFormProvider.notifier).addAuxiliaryUnit();
  }

  void _removeAuxiliaryUnit(int index) {
    final auxiliaryUnitId = _auxiliaryUnits[index].id;

    setState(() {
      _auxiliaryUnits[index].dispose();
      _auxiliaryUnits.removeAt(index);
    });

    ref
        .read(unitEditFormProvider.notifier)
        .removeAuxiliaryUnit(auxiliaryUnitId);
  }

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
        if (widget.baseUnitName != null &&
            selectedUnit.name == widget.baseUnitName!) {
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

        ref
            .read(unitEditFormProvider.notifier)
            .updateAuxiliaryUnitName(
              _auxiliaryUnits[index].id,
              selectedUnit.name,
              unitId: selectedUnit.id,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择单位失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scanBarcode(int index) async {
    try {
      final String? barcode = await BarcodeScannerService.scanForProduct(
        context,
      );
      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _auxiliaryUnits[index].barcodeController.text = barcode;
        });

        ref
            .read(unitEditFormProvider.notifier)
            .updateAuxiliaryUnitBarcode(_auxiliaryUnits[index].id, barcode);

        // 扫码成功后转移焦点到辅单位名称输入框
        _auxiliaryUnits[index].unitFocusNode.requestFocus();

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

  List<ProductUnit> _buildProductUnits() {
    print('🔍 [DEBUG] ==================== 开始构建产品单位 ====================');
    print('🔍 [DEBUG] 产品ID: ${widget.productId}');
    print('🔍 [DEBUG] 基本单位ID: ${widget.baseUnitId}');
    print('🔍 [DEBUG] 基本单位名称: ${widget.baseUnitName}');
    print('🔍 [DEBUG] 辅单位数量: ${_auxiliaryUnits.length}');

    final List<ProductUnit> productUnits = [];

    // 添加基本单位
    if (widget.baseUnitId != null) {
      final baseUnit = ProductUnit(
        productUnitId: '${widget.productId ?? 'new'}_${widget.baseUnitId!}',
        productId: widget.productId ?? 'new',
        unitId: widget.baseUnitId!,
        conversionRate: 1.0,
      );
      productUnits.add(baseUnit);
      print('🔍 [DEBUG] ✅ 添加基本单位: ${baseUnit.productUnitId}');
    } else {
      print('🔍 [DEBUG] ❌ 警告: 基本单位ID为null');
    }

    // 处理辅单位
    for (int i = 0; i < _auxiliaryUnits.length; i++) {
      final aux = _auxiliaryUnits[i];
      print('🔍 [DEBUG] --- 处理辅单位 ${i + 1} ---');
      print('🔍 [DEBUG]   单位对象: ${aux.unit}');
      print('🔍 [DEBUG]   单位ID: ${aux.unit?.id}');
      print('🔍 [DEBUG]   单位名称: "${aux.unit?.name}"');
      print('🔍 [DEBUG]   换算率: ${aux.conversionRate}');
      print('🔍 [DEBUG]   输入框文本: "${aux.unitController.text}"');
      print('🔍 [DEBUG]   条码: "${aux.barcodeController.text}"');
      print('🔍 [DEBUG]   零售价: "${aux.retailPriceController.text}"');

      if (aux.unit != null && aux.conversionRate > 0) {
        print('=== 构建辅单位ProductUnit ===');
        print(
          'retailPriceController.text: "${aux.retailPriceController.text}"',
        );
        final sellingPrice = aux.retailPriceController.text.trim().isNotEmpty
            ? double.tryParse(aux.retailPriceController.text.trim())
            : null;
        print('解析后的sellingPrice: $sellingPrice');
        print('========================');

        final auxUnit = ProductUnit(
          productUnitId: '${widget.productId ?? 'new'}_${aux.unit!.id}',
          productId: widget.productId ?? 'new',
          unitId: aux.unit!.id,
          conversionRate: aux.conversionRate,
          sellingPrice: sellingPrice,
          lastUpdated: DateTime.now(),
        );
        productUnits.add(auxUnit);
        print('🔍 [DEBUG]   ✅ 添加辅单位: ${auxUnit.productUnitId}');
      } else {
        print('🔍 [DEBUG]   ❌ 跳过无效辅单位:');
        if (aux.unit == null) {
          print('🔍 [DEBUG]     - 单位对象为null');
        }
        if (aux.conversionRate <= 0) {
          print('🔍 [DEBUG]     - 换算率无效: ${aux.conversionRate}');
        }
      }
    }

    print('🔍 [DEBUG] ==================== 构建结果 ====================');
    print('🔍 [DEBUG] 总计产品单位数量: ${productUnits.length}');
    for (int i = 0; i < productUnits.length; i++) {
      final pu = productUnits[i];
      print(
        '🔍 [DEBUG] 产品单位 ${i + 1}: ${pu.productUnitId} (换算率: ${pu.conversionRate})',
      );
    }
    print('🔍 [DEBUG] ==================== 构建完成 ====================');

    return productUnits;
  }

  /// 构建辅单位条码数据
  List<Map<String, String>> _buildAuxiliaryUnitBarcodes() {
    final List<Map<String, String>> barcodes = [];

    for (final aux in _auxiliaryUnits) {
      if (aux.unit != null && aux.barcodeController.text.trim().isNotEmpty) {
        barcodes.add({
          'productUnitId': '${widget.productId ?? 'new'}_${aux.unit!.id}',
          'barcode': aux.barcodeController.text.trim(),
        });
      }
    }

    return barcodes;
  }

  void _handleReturn() {
    print('🔍 处理返回，开始构建数据...');
    final productUnits = _buildProductUnits();
    final auxiliaryBarcodes = _buildAuxiliaryUnitBarcodes();

    if (productUnits.isNotEmpty && widget.baseUnitId != null) {
      print('🔍 数据有效，返回产品单位数据');
      ref.read(unitEditFormProvider.notifier).resetUnitEditForm();

      // 返回包含产品单位和条码信息的数据
      Navigator.of(context).pop({
        'productUnits': productUnits,
        'auxiliaryBarcodes': auxiliaryBarcodes,
      });
    } else {
      print('🔍 数据无效或缺少基本单位，直接返回');
      Navigator.of(context).pop();
    }
  }

  void _loadFromFormProvider() {
    try {
      final formState = ref.read(unitEditFormProvider);

      if (formState.auxiliaryUnits.isNotEmpty) {
        _loadAuxiliaryUnitsFromFormData(formState.auxiliaryUnits);
        _auxiliaryCounter = formState.auxiliaryCounter;
      }
    } catch (e) {}
  }

  Future<void> _loadAuxiliaryUnitsFromFormData(
    List<AuxiliaryUnitData> auxiliaryUnitsData,
  ) async {
    try {
      final List<_AuxiliaryUnit> tempAuxiliaryUnits = [];
      final allUnits = await ref.read(allUnitsProvider.future);

      for (final auxData in auxiliaryUnitsData) {
        Unit? unit;

        if (auxData.unitName.trim().isNotEmpty) {
          unit = allUnits.firstWhere(
            (u) => u.name == auxData.unitName.trim(),
            orElse: () => Unit(id: '', name: ''),
          );

          if (unit.id.isEmpty) {
            unit = Unit(
              id:
                  auxData.unitId ??
                  'unit_${DateTime.now().millisecondsSinceEpoch}',
              name: auxData.unitName.trim(),
            );
          }
        }

        final auxiliaryUnit = _AuxiliaryUnit(
          id: auxData.id,
          unit: unit,
          conversionRate: auxData.conversionRate,
        );

        auxiliaryUnit.unitController.text = auxData.unitName;
        auxiliaryUnit.barcodeController.text = auxData.barcode;
        auxiliaryUnit.retailPriceController.text = auxData.retailPrice;
        print('=== 从表单数据加载售价 ===');
        print('auxData.retailPrice: "${auxData.retailPrice}"');
        print(
          'retailPriceController.text: "${auxiliaryUnit.retailPriceController.text}"',
        );
        print('=======================');

        tempAuxiliaryUnits.add(auxiliaryUnit);
      }

      if (mounted && tempAuxiliaryUnits.isNotEmpty) {
        setState(() {
          _auxiliaryUnits.clear();
          _auxiliaryUnits.addAll(tempAuxiliaryUnits);
        });
      }
    } catch (e) {}
  }
}

class _AuxiliaryUnit {
  final int id;
  Unit? unit;
  double conversionRate;
  late TextEditingController unitController;
  late TextEditingController barcodeController;
  late TextEditingController retailPriceController;

  // 焦点节点
  final FocusNode unitFocusNode = FocusNode();
  final FocusNode conversionRateFocusNode = FocusNode();
  final FocusNode retailPriceFocusNode = FocusNode();

  _AuxiliaryUnit({
    required this.id,
    this.unit,
    required this.conversionRate,
    double? initialSellingPrice,
  }) {
    print('🔍 构造_AuxiliaryUnit: initialSellingPrice=$initialSellingPrice');
    unitController = TextEditingController(text: unit?.name ?? '');
    barcodeController = TextEditingController();
    retailPriceController = TextEditingController(
      text: initialSellingPrice?.toString() ?? '',
    );
    print('🔍 retailPriceController.text=${retailPriceController.text}');
  }

  void dispose() {
    unitController.dispose();
    barcodeController.dispose();
    retailPriceController.dispose();
    unitFocusNode.dispose();
    conversionRateFocusNode.dispose();
    retailPriceFocusNode.dispose();
  }
}
