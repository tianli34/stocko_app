import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/auxiliary_unit_data.dart';

/// 单位编辑页面辅单位数据状态
class UnitEditFormState {
  /// 辅单位数据列表
  final List<AuxiliaryUnitData> auxiliaryUnits;

  /// 辅单位计数器
  final int auxiliaryCounter;

  const UnitEditFormState({
    this.auxiliaryUnits = const [],
    this.auxiliaryCounter = 1,
  });

  UnitEditFormState copyWith({
    List<AuxiliaryUnitData>? auxiliaryUnits,
    int? auxiliaryCounter,
  }) {
    return UnitEditFormState(
      auxiliaryUnits: auxiliaryUnits ?? this.auxiliaryUnits,
      auxiliaryCounter: auxiliaryCounter ?? this.auxiliaryCounter,
    );
  }

  /// 获取指定ID的辅单位数据
  AuxiliaryUnitData? getAuxiliaryUnit(int id) {
    try {
      return auxiliaryUnits.firstWhere((unit) => unit.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitEditFormState &&
        _listEquals(other.auxiliaryUnits, auxiliaryUnits) &&
        other.auxiliaryCounter == auxiliaryCounter;
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(auxiliaryUnits), auxiliaryCounter);
  }

  /// 比较两个列表是否相等
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 单位编辑页面表单状态管理器
class UnitEditFormNotifier extends Notifier<UnitEditFormState> {
  @override
  UnitEditFormState build() {
    return const UnitEditFormState();
  }

  /// 添加新的辅单位
  void addAuxiliaryUnit() {
    final newUnit = AuxiliaryUnitData.empty(state.auxiliaryCounter);
    final updatedUnits = [...state.auxiliaryUnits, newUnit];
    state = state.copyWith(
      auxiliaryUnits: updatedUnits,
      auxiliaryCounter: state.auxiliaryCounter + 1,
    );
  }

  /// 删除指定ID的辅单位
  void removeAuxiliaryUnit(int id) {
    final updatedUnits = state.auxiliaryUnits
        .where((unit) => unit.id != id)
        .toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 更新辅单位的单位名称
  void updateAuxiliaryUnitName(int id, String unitName, {int? unitId}) {
    final updatedUnits = state.auxiliaryUnits.map((unit) {
      if (unit.id == id) {
        return unit.copyWith(unitName: unitName, unitId: unitId);
      }
      return unit;
    }).toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 更新辅单位的换算率
  void updateAuxiliaryUnitConversionRate(int id, int conversionRate) {
    final updatedUnits = state.auxiliaryUnits.map((unit) {
      if (unit.id == id) {
        return unit.copyWith(conversionRate: conversionRate);
      }
      return unit;
    }).toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 更新辅单位的条码
  void updateAuxiliaryUnitBarcode(int id, String barcode) {
    final updatedUnits = state.auxiliaryUnits.map((unit) {
      if (unit.id == id) {
        return unit.copyWith(barcode: barcode);
      }
      return unit;
    }).toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 更新辅单位的建议零售价
  void updateAuxiliaryUnitRetailPrice(int id, String retailPriceInYuan) {
    // 将元转换为分存储
    String retailPriceInCents = '';
    if (retailPriceInYuan.trim().isNotEmpty) {
      final priceInYuan = double.tryParse(retailPriceInYuan.trim());
      if (priceInYuan != null) {
        retailPriceInCents = (priceInYuan * 100).round().toString();
      }
    }
    
    final updatedUnits = state.auxiliaryUnits.map((unit) {
      if (unit.id == id) {
        return unit.copyWith(retailPriceInCents: retailPriceInCents);
      }
      return unit;
    }).toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 更新辅单位的批发价
  void updateAuxiliaryUnitWholesalePrice(int id, String wholesalePriceInYuan) {
    // 将元转换为分存储
    String wholesalePriceInCents = '';
    if (wholesalePriceInYuan.trim().isNotEmpty) {
      final priceInYuan = double.tryParse(wholesalePriceInYuan.trim());
      if (priceInYuan != null) {
        wholesalePriceInCents = (priceInYuan * 100).round().toString();
      }
    }
    
    final updatedUnits = state.auxiliaryUnits.map((unit) {
      if (unit.id == id) {
        return unit.copyWith(wholesalePriceInCents: wholesalePriceInCents);
      }
      return unit;
    }).toList();
    state = state.copyWith(auxiliaryUnits: updatedUnits);
  }

  /// 批量设置辅单位数据（用于初始化）
  void setAuxiliaryUnits(List<AuxiliaryUnitData> units, {int? counter}) {
    state = state.copyWith(
      auxiliaryUnits: units,
      auxiliaryCounter: counter ?? state.auxiliaryCounter,
    );
  }

  /// 重置单位编辑表单
  void resetUnitEditForm() {
    state = const UnitEditFormState();
  }

  /// 清除辅单位数据，保留基本单位
  void clearAuxiliaryUnits() {
    state = state.copyWith(auxiliaryUnits: [], auxiliaryCounter: 1);
  }

  /// 从现有的_AuxiliaryUnit列表初始化数据
  void initializeFromExisting(List<dynamic> existingUnits, int counter) {
    final auxiliaryUnits = <AuxiliaryUnitData>[];

    for (final unit in existingUnits) {
      if (unit is Map<String, dynamic>) {
        // 从Map初始化
        auxiliaryUnits.add(AuxiliaryUnitData.fromJson(unit));
      } else {
        // 从现有的_AuxiliaryUnit对象初始化
        final auxUnit = unit as dynamic;
        
        // 将元转换为分
        String retailPriceInCents = '';
        final retailPriceText = auxUnit.retailPriceController?.text as String? ?? '';
        if (retailPriceText.trim().isNotEmpty) {
          final priceInYuan = double.tryParse(retailPriceText.trim());
          if (priceInYuan != null) {
            retailPriceInCents = (priceInYuan * 100).round().toString();
          }
        }
        
        String wholesalePriceInCents = '';
        final wholesalePriceText = auxUnit.wholesalePriceController?.text as String? ?? '';
        if (wholesalePriceText.trim().isNotEmpty) {
          final priceInYuan = double.tryParse(wholesalePriceText.trim());
          if (priceInYuan != null) {
            wholesalePriceInCents = (priceInYuan * 100).round().toString();
          }
        }
        
        auxiliaryUnits.add(
          AuxiliaryUnitData(
            id: auxUnit.id as int,
            unitId: auxUnit.unit?.id as int?,
            unitName: auxUnit.unitController?.text as String? ?? '',
            conversionRate: auxUnit.conversionRate ?? 0,
            barcode: auxUnit.barcodeController?.text as String? ?? '',
            retailPriceInCents: retailPriceInCents,
            wholesalePriceInCents: wholesalePriceInCents,
          ),
        );
      }
    }

    state = UnitEditFormState(
      auxiliaryUnits: auxiliaryUnits,
      auxiliaryCounter: counter,
    );
  }
}

/// 单位编辑页面表单状态提供者（保留状态，父页结束时手动清理）
final unitEditFormProvider =
    NotifierProvider<UnitEditFormNotifier, UnitEditFormState>(() {
      return UnitEditFormNotifier();
    });
