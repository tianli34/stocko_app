import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../application/mapper/auxiliary_unit_mapper.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import '../../application/provider/unit_providers.dart';
import '../../domain/model/auxiliary_unit_data.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/unit.dart';
import '../../domain/service/unit_validation_service.dart';
import '../../shared/constants/product_constants.dart';
import '../widgets/auxiliary_unit/auxiliary_unit_card.dart';
import '../widgets/auxiliary_unit/auxiliary_unit_model.dart';
import 'unit_selection_screen.dart';

/// 调试日志工具
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// 辅单位编辑页面
class AuxiliaryUnitEditScreen extends ConsumerStatefulWidget {
  final int? productId;
  final String baseUnitId;
  final String? baseUnitName;

  const AuxiliaryUnitEditScreen({
    super.key,
    this.productId,
    required this.baseUnitId,
    this.baseUnitName,
  });

  @override
  ConsumerState<AuxiliaryUnitEditScreen> createState() =>
      _AuxiliaryUnitEditScreenState();
}

class _AuxiliaryUnitEditScreenState
    extends ConsumerState<AuxiliaryUnitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<AuxiliaryUnitModel> _auxiliaryUnits = [];

  int _auxiliaryCounter = 1;
  List<Unit>? _cachedUnits;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUnits();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (final aux in _auxiliaryUnits) {
      aux.dispose();
    }
    super.dispose();
  }

  // ==================== 初始化方法 ====================

  void _initializeUnits() async {
    _debugLog('_initializeUnits: productId=${widget.productId}');

    if (widget.productId != null) {
      await _initializeAuxiliaryUnits();
      return;
    }

    final formState = ref.read(unitEditFormProvider);
    if (formState.auxiliaryUnits.isNotEmpty) {
      _loadFromFormProvider();
      return;
    }

    await _initializeAuxiliaryUnits();
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
        final productUnitController =
            ref.read(productUnitControllerProvider.notifier);
        final allProductUnits = await productUnitController
            .getProductUnitsByProductId(widget.productId!);
        final auxiliaryUnits =
            allProductUnits.where((pu) => pu.conversionRate != 1.0).toList();

        if (auxiliaryUnits.isNotEmpty) {
          await _loadAuxiliaryUnits(auxiliaryUnits);
        } else {
          _addAuxiliaryUnit();
        }
      } else {
        _addAuxiliaryUnit();
      }
    } catch (e, s) {
      _debugLog('Error initializing auxiliary units: $e\n$s');
    }
  }

  Future<void> _loadAuxiliaryUnits(List<UnitProduct> auxiliaryUnits) async {
    final List<AuxiliaryUnitModel> tempAuxiliaryUnits = [];

    for (final unitProduct in auxiliaryUnits) {
      try {
        final allUnits = await _getCachedUnits();
        final unit = allUnits.firstWhere(
          (u) => u.id == unitProduct.unitId,
          orElse: () =>
              throw Exception('Unit not found: ${unitProduct.unitId}'),
        );

        final auxiliaryUnit = AuxiliaryUnitMapper.fromUnitProduct(
          unitProduct,
          unit,
          _auxiliaryCounter,
        );

        // 加载条码
        final barcodeController = ref.read(barcodeControllerProvider.notifier);
        final barcodes =
            await barcodeController.getBarcodesByProductUnitId(unitProduct.id);
        if (barcodes.isNotEmpty) {
          auxiliaryUnit.barcodeController.text = barcodes.first.barcodeValue;
        }

        tempAuxiliaryUnits.add(auxiliaryUnit);
        _auxiliaryCounter++;
      } catch (e, s) {
        _debugLog('加载辅单位失败: $e\n$s');
      }
    }

    if (mounted && tempAuxiliaryUnits.isNotEmpty) {
      setState(() {
        _auxiliaryUnits.clear();
        _auxiliaryUnits.addAll(tempAuxiliaryUnits);
      });
    }
  }

  Future<void> _loadAuxiliaryUnitsFromFormData(
    List<AuxiliaryUnitData> auxiliaryUnitsData,
  ) async {
    try {
      final List<AuxiliaryUnitModel> tempAuxiliaryUnits = [];
      final allUnits = await _getCachedUnits();

      for (final auxData in auxiliaryUnitsData) {
        Unit? unit;
        if (auxData.unitName.trim().isNotEmpty) {
          unit = allUnits.firstWhere(
            (u) => u.name == auxData.unitName.trim(),
            orElse: () => Unit.empty(),
          );

          if (unit.isNew) {
            unit = Unit(id: auxData.unitId, name: auxData.unitName.trim());
          }
        }

        final auxiliaryUnit =
            AuxiliaryUnitMapper.toAuxiliaryUnitModel(auxData, unit: unit);
        tempAuxiliaryUnits.add(auxiliaryUnit);
      }

      if (mounted && tempAuxiliaryUnits.isNotEmpty) {
        setState(() {
          _auxiliaryUnits.clear();
          _auxiliaryUnits.addAll(tempAuxiliaryUnits);
        });
      }
    } catch (e, s) {
      _debugLog('从表单数据加载辅单位失败: $e\n$s');
    }
  }

  void _loadFromFormProvider() {
    try {
      final formState = ref.read(unitEditFormProvider);
      if (formState.auxiliaryUnits.isNotEmpty) {
        _loadAuxiliaryUnitsFromFormData(formState.auxiliaryUnits);
        _auxiliaryCounter = formState.auxiliaryCounter;
      }
    } catch (e, s) {
      _debugLog('从 FormProvider 加载数据失败: $e\n$s');
    }
  }

  // ==================== 工具方法 ====================

  void _debouncedAction(VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kDebounceDelay, action);
  }

  Future<List<Unit>> _getCachedUnits() async {
    _cachedUnits ??= await ref.read(allUnitsProvider.future);
    return _cachedUnits!;
  }

  // ==================== UI 构建 ====================

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
          title: const Text('编辑辅单位'),
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
                    AuxiliaryUnitCard(
                      key: ValueKey(_auxiliaryUnits[index].id),
                      auxiliaryUnit: _auxiliaryUnits[index],
                      index: index,
                      baseUnitName: widget.baseUnitName,
                      onRemove: () => _removeAuxiliaryUnit(index),
                      onSelectUnit: () => _selectAuxiliaryUnit(index),
                      onScanBarcode: () => _scanBarcode(index),
                      onUnitNameChanged: (value) => _debouncedAction(
                        () => _onAuxiliaryUnitNameChanged(index, value),
                      ),
                      onConversionRateChanged: (value) => _debouncedAction(
                        () => _onConversionRateChanged(index, value),
                      ),
                      onBarcodeChanged: (value) => _debouncedAction(
                        () => _onBarcodeChanged(index, value),
                      ),
                      onRetailPriceChanged: (value) => _debouncedAction(
                        () => _onRetailPriceChanged(index, value),
                      ),
                      onWholesalePriceChanged: (value) => _debouncedAction(
                        () => _onWholesalePriceChanged(index, value),
                      ),
                      onReturnPressed: _handleReturn,
                    ),
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

  // ==================== 事件处理方法 ====================

  void _onConversionRateChanged(int index, String value) {
    final rate = double.tryParse(value.trim());
    if (rate != null) {
      _auxiliaryUnits[index].conversionRate = rate;
      ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitConversionRate(
            _auxiliaryUnits[index].id,
            rate.toInt(),
          );
    }
  }

  void _onBarcodeChanged(int index, String value) {
    ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitBarcode(
          _auxiliaryUnits[index].id,
          value,
        );
  }

  void _onRetailPriceChanged(int index, String value) {
    ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitRetailPrice(
          _auxiliaryUnits[index].id,
          value,
        );
  }

  void _onWholesalePriceChanged(int index, String value) {
    ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitWholesalePrice(
          _auxiliaryUnits[index].id,
          value,
        );
  }

  void _onAuxiliaryUnitNameChanged(int index, String unitName) async {
    final trimmedName = unitName.trim();

    if (trimmedName.isEmpty) {
      setState(() {
        _auxiliaryUnits[index].unit = null;
      });
      ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitName(
            _auxiliaryUnits[index].id,
            '',
          );
      return;
    }

    try {
      final allUnits = await _getCachedUnits();

      Unit? existingUnit = allUnits.firstWhere(
        (unit) => unit.name == trimmedName,
        orElse: () => Unit.empty(),
      );

      if (existingUnit.isNew) {
        existingUnit = Unit(name: trimmedName);
      }

      final validationResult = UnitValidationService.validateUnitSelection(
        unit: existingUnit,
        baseUnitName: widget.baseUnitName,
        auxiliaryUnits: _auxiliaryUnits,
        currentIndex: index,
      );

      if (!validationResult.isValid) {
        if (mounted) {
          showAppSnackBar(context,
              message: validationResult.errorMessage!, isError: true);
        }
        return;
      }

      setState(() {
        _auxiliaryUnits[index].unit = existingUnit;
      });

      ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitName(
            _auxiliaryUnits[index].id,
            trimmedName,
            unitId: existingUnit.id,
          );
    } catch (e, s) {
      _debugLog('辅单位名称变更异常: $e\n$s');
    }
  }

  void _addAuxiliaryUnit() {
    setState(() {
      _auxiliaryUnits.add(
        AuxiliaryUnitModel(id: _auxiliaryCounter, unit: null, conversionRate: 0),
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
    ref.read(unitEditFormProvider.notifier).removeAuxiliaryUnit(auxiliaryUnitId);
  }

  void _selectAuxiliaryUnit(int index) async {
    try {
      final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
        MaterialPageRoute(
          builder: (context) => UnitSelectionScreen(
            initialUnit: _auxiliaryUnits[index].unit,
          ),
        ),
      );

      if (selectedUnit != null) {
        final validationResult = UnitValidationService.validateUnitSelection(
          unit: selectedUnit,
          baseUnitName: widget.baseUnitName,
          auxiliaryUnits: _auxiliaryUnits,
          currentIndex: index,
        );

        if (!validationResult.isValid) {
          if (mounted) {
            showAppSnackBar(context,
                message: validationResult.errorMessage!, isError: true);
          }
          return;
        }

        setState(() {
          _auxiliaryUnits[index].unit = selectedUnit;
          _auxiliaryUnits[index].unitController.text = selectedUnit.name;
        });

        ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitName(
              _auxiliaryUnits[index].id,
              selectedUnit.name,
              unitId: selectedUnit.id,
            );
      }
    } catch (e, s) {
      _debugLog('选择单位失败: $e\n$s');
      if (mounted) {
        showAppSnackBar(context, message: '选择单位失败，请重试', isError: true);
      }
    }
  }

  void _scanBarcode(int index) async {
    try {
      final String? barcode = await BarcodeScannerService.quickScan(
        context,
        title: '扫描条码',
      );
      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _auxiliaryUnits[index].barcodeController.text = barcode;
        });

        ref.read(unitEditFormProvider.notifier).updateAuxiliaryUnitBarcode(
              _auxiliaryUnits[index].id,
              barcode,
            );

        _auxiliaryUnits[index].unitFocusNode.requestFocus();

        if (mounted) {
          showAppSnackBar(context, message: '扫描成功');
        }
      }
    } catch (e, s) {
      _debugLog('扫描失败: $e\n$s');
      if (mounted) {
        showAppSnackBar(context, message: '扫描失败，请重试', isError: true);
      }
    }
  }

  // ==================== 数据处理方法 ====================

  void _handleReturn() {
    try {
      final parsedBaseUnitId = int.tryParse(widget.baseUnitId);
      if (parsedBaseUnitId == null) {
        Navigator.of(context).pop();
        return;
      }

      final productUnits = AuxiliaryUnitMapper.buildProductUnits(
        auxiliaryUnits: _auxiliaryUnits,
        productId: widget.productId ?? 0,
        baseUnitId: parsedBaseUnitId,
      );

      final auxiliaryBarcodes = AuxiliaryUnitMapper.buildAuxiliaryUnitBarcodes(
        _auxiliaryUnits,
        productId: widget.productId,
      );

      if (productUnits.isNotEmpty) {
        _saveCurrentDataToFormProvider();

        Navigator.of(context).pop({
          'productUnits': productUnits,
          'auxiliaryBarcodes': auxiliaryBarcodes,
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      _debugLog('返回处理异常: $e\n$s');
      Navigator.of(context).pop();
    }
  }

  void _saveCurrentDataToFormProvider() {
    try {
      final auxiliaryUnitsData =
          AuxiliaryUnitMapper.toAuxiliaryUnitDataList(_auxiliaryUnits);

      ref.read(unitEditFormProvider.notifier).setAuxiliaryUnits(
            auxiliaryUnitsData,
            counter: _auxiliaryCounter,
          );
    } catch (e, s) {
      _debugLog('保存数据到 FormProvider 失败: $e\n$s');
    }
  }
}
