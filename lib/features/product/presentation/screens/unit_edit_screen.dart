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

  Unit? _baseUnit;
  late TextEditingController _baseUnitController;

  final List<_AuxiliaryUnit> _auxiliaryUnits = [];

  int _auxiliaryCounter = 1;
  @override
  void initState() {
    super.initState();
    _baseUnitController = TextEditingController();
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
    final formState = ref.read(unitEditFormProvider);
    final hasPersistedData = formState.auxiliaryUnits.isNotEmpty;

    if (hasPersistedData) {
      _loadFromFormProvider();
      return;
    }

    await _initializeBaseUnit();

    await _initializeAuxiliaryUnits();
  }

  Future<void> _initializeBaseUnit() async {
    if (widget.baseUnitId != null && widget.baseUnitName != null) {
      try {
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
      } catch (e) {}
    } else {}
  }

  Future<void> _initializeAuxiliaryUnits() async {
    try {
      final formState = ref.read(unitEditFormProvider);
      if (formState.auxiliaryUnits.isNotEmpty) {
        await _loadAuxiliaryUnitsFromFormData(formState.auxiliaryUnits);
        _auxiliaryCounter = formState.auxiliaryCounter;
        return;
      }
      if (widget.productId != null) {
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
        } else {}
      } else {}
    } catch (e) {}
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
        final auxiliaryUnit = _AuxiliaryUnit(
          id: _auxiliaryCounter,
          unit: unit,
          conversionRate: productUnit.conversionRate,
        );

        auxiliaryUnit.unitController.text = unit.name;

        if (productUnit.sellingPrice != null) {
          auxiliaryUnit.retailPriceController.text = productUnit.sellingPrice!
              .toString();
        }

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
    final auxiliaryUnits = ref.watch(unitEditFormProvider).auxiliaryUnits;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {}
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('添加辅单位页'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final productUnits = _buildProductUnits();
              if (productUnits.isNotEmpty && _baseUnit != null) {
                ref.read(unitEditFormProvider.notifier).resetUnitEditForm();

                Navigator.of(context).pop(productUnits);
              } else {
                Navigator.of(context).pop();
              }
            },
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
                      _buildBaseUnitSection(),

                      const SizedBox(height: 24),
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

  Widget _buildBaseUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '辅单位',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: '请输入辅单位名称',
                  border: OutlineInputBorder(),
                  helperText: '可直接输入单位名称，如：个、箱、包、瓶等',
                ),
                controller: _baseUnitController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入辅单位名称';
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

  Widget _buildAuxiliaryUnitsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  icon: const Icon(Icons.delete, color: Colors.red),
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
                      hintText: '请输入或扫描条码',
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
              onChanged: (value) {
                ref
                    .read(unitEditFormProvider.notifier)
                    .updateAuxiliaryUnitRetailPrice(auxiliaryUnit.id, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onBaseUnitNameChanged(String unitName) async {
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _baseUnit = null;
      });
      return;
    }

    try {
      final allUnits = await ref.read(allUnitsProvider.future);
      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit(id: '', name: ''),
      );

      if (existingUnit.id.isEmpty) {
        existingUnit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmedName,
        );
      }
      setState(() {
        _baseUnit = existingUnit;
      });
    } catch (e) {}
  }

  void _onAuxiliaryUnitNameChanged(int index, String unitName) async {
    final trimmedName = unitName.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _auxiliaryUnits[index].unit = null;
      });
      ref
          .read(unitEditFormProvider.notifier)
          .updateAuxiliaryUnitName(_auxiliaryUnits[index].id, '');
      return;
    }

    try {
      final allUnits = await ref.read(allUnitsProvider.future);
      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit(id: '', name: ''),
      );

      if (existingUnit.id.isEmpty) {
        existingUnit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmedName,
        );
      }

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

      ref
          .read(unitEditFormProvider.notifier)
          .updateAuxiliaryUnitName(
            _auxiliaryUnits[index].id,
            trimmedName,
            unitId: existingUnit.id,
          );
    } catch (e) {}
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择单位失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    final List<ProductUnit> productUnits = [];

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

  _AuxiliaryUnit({required this.id, this.unit, required this.conversionRate}) {
    unitController = TextEditingController(text: unit?.name ?? '');
    barcodeController = TextEditingController();
    retailPriceController = TextEditingController();
  }

  void dispose() {
    unitController.dispose();
    barcodeController.dispose();
    retailPriceController.dispose();
  }
}
