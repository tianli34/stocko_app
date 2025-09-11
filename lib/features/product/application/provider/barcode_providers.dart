import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/barcode.dart';
import '../../domain/repository/i_barcode_repository.dart';
import '../../data/repository/barcode_repository.dart';
import '../../domain/model/product_unit.dart';
import '../../data/repository/product_unit_repository.dart';

/// 条码操作状态
enum BarcodeOperationStatus { initial, loading, success, error }

/// 条码控制器状态
class BarcodeControllerState {
  final BarcodeOperationStatus status;
  final String? errorMessage;
  final List<BarcodeModel>? lastOperatedBarcodes;

  const BarcodeControllerState({
    this.status = BarcodeOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedBarcodes,
  });

  BarcodeControllerState copyWith({
    BarcodeOperationStatus? status,
    String? errorMessage,
    List<BarcodeModel>? lastOperatedBarcodes,
  }) {
    return BarcodeControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedBarcodes: lastOperatedBarcodes ?? this.lastOperatedBarcodes,
    );
  }

  bool get isLoading => status == BarcodeOperationStatus.loading;
  bool get isSuccess => status == BarcodeOperationStatus.success;
  bool get isError => status == BarcodeOperationStatus.error;
}

/// 条码控制器
class BarcodeController extends StateNotifier<BarcodeControllerState> {
  final IBarcodeRepository _repository;

  BarcodeController(this._repository) : super(const BarcodeControllerState());

  /// 添加条码
  Future<void> addBarcode(BarcodeModel barcode) async {
    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      // 检查条码是否已存在
      final exists = await _repository.barcodeExists(barcode.barcodeValue);
      if (exists) {
        state = state.copyWith(
          status: BarcodeOperationStatus.error,
          errorMessage: '条码 ${barcode.barcodeValue} 已存在',
        );
        return;
      }

      await _repository.addBarcode(barcode);
      state = state.copyWith(
        status: BarcodeOperationStatus.success,
        lastOperatedBarcodes: [barcode],
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '添加条码失败: ${e.toString()}',
      );
    }
  }

  /// 批量添加条码
  Future<void> addMultipleBarcodes(List<BarcodeModel> barcodes) async {
    if (barcodes.isEmpty) return;

    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      // 检查是否有重复的条码
      for (final barcode in barcodes) {
        final exists = await _repository.barcodeExists(barcode.barcodeValue);
        if (exists) {
          state = state.copyWith(
            status: BarcodeOperationStatus.error,
            errorMessage: '条码 ${barcode.barcodeValue} 已存在',
          );
          return;
        }
      }

      await _repository.addMultipleBarcodes(barcodes);
      state = state.copyWith(
        status: BarcodeOperationStatus.success,
        lastOperatedBarcodes: barcodes,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '批量添加条码失败: ${e.toString()}',
      );
    }
  }

  /// 更新条码
  Future<void> updateBarcode(BarcodeModel barcode) async {
    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      final success = await _repository.updateBarcode(barcode);
      if (success) {
        state = state.copyWith(
          status: BarcodeOperationStatus.success,
          lastOperatedBarcodes: [barcode],
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: BarcodeOperationStatus.error,
          errorMessage: '更新条码失败：未找到对应的记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '更新条码失败: ${e.toString()}',
      );
    }
  }

  /// 删除条码
  Future<void> deleteBarcode(int id) async {
    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      final deletedCount = await _repository.deleteBarcode(id);
      if (deletedCount > 0) {
        state = state.copyWith(
          status: BarcodeOperationStatus.success,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: BarcodeOperationStatus.error,
          errorMessage: '删除条码失败：未找到对应的记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '删除条码失败: ${e.toString()}',
      );
    }
  }

  /// 删除产品单位的所有条码
  Future<void> deleteBarcodesByProductUnitId(int id) async {
    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      final deletedCount = await _repository.deleteBarcodesByProductUnitId(
        id,
      );
      state = state.copyWith(
        status: BarcodeOperationStatus.success,
        errorMessage: null,
      );
      print('删除了 $deletedCount 个条码');
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '删除产品单位条码失败: ${e.toString()}',
      );
    }
  }

  /// 根据条码值获取条码信息
  Future<BarcodeModel?> getBarcodeByValue(String barcode) async {
    try {
      return await _repository.getBarcodeByValue(barcode);
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '获取条码信息失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 根据产品单位ID获取所有条码
  Future<List<BarcodeModel>> getBarcodesByProductUnitId(int? id) async {
    try {
      return await _repository.getBarcodesByProductUnitId(id);
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '获取产品单位条码失败: ${e.toString()}',
      );
      return [];
    }
  }

  /// 检查条码是否存在
  Future<bool> barcodeExists(String barcode) async {
    try {
      return await _repository.barcodeExists(barcode);
    } catch (e) {
      state = state.copyWith(
        status: BarcodeOperationStatus.error,
        errorMessage: '检查条码是否存在失败: ${e.toString()}',
      );
      return false;
    }
  }

  /// 清除错误状态
  void clearError() {
    if (state.isError) {
      state = state.copyWith(
        status: BarcodeOperationStatus.initial,
        errorMessage: null,
      );
    }
  }
}

/// 条码控制器 Provider
final barcodeControllerProvider =
    StateNotifierProvider<BarcodeController, BarcodeControllerState>((ref) {
      final repository = ref.watch(barcodeRepositoryProvider);
      return BarcodeController(repository);
    });

/// 根据产品单位ID获取条码列表的 Provider
final barcodesByProductUnitIdProvider =
    StreamProvider.family<List<BarcodeModel>, int>((ref, id) {
      final repository = ref.watch(barcodeRepositoryProvider);
      return repository.watchBarcodesByProductUnitId(id);
    });

/// 获取所有条码的 Provider
final allBarcodesProvider = FutureProvider<List<BarcodeModel>>((ref) async {
  final repository = ref.watch(barcodeRepositoryProvider);
  return repository.getAllBarcodes();
});

/// 根据货品ID获取主条码的 Provider
final mainBarcodeProvider =
    FutureProvider.family<String?, int>((ref, productId) async {
  final productUnitRepo = ref.watch(productUnitRepositoryProvider);
  final barcodeRepo = ref.watch(barcodeRepositoryProvider);

  print('======== 调试日志：mainBarcodeProvider 内部 ========');
  print('货品ID: $productId');

  // 1. 查找货品的基础单位配置
  final productUnits = await productUnitRepo.getProductUnitsByProductId(productId);
  print('查找到的货品单位配置: ${productUnits.map((e) => 'id: ${e.id}, rate: ${e.conversionRate}').toList()}');

  if (productUnits.isEmpty) {
    print('未找到任何货品单位配置，返回 null');
    print('=============================================');
    return null; // 没有单位配置，自然没有条码
  }

  UnitProduct? baseProductUnit;
  try {
    baseProductUnit =
        productUnits.firstWhere((unit) => unit.conversionRate == 1.0);
    print('找到基础单位 (conversionRate == 1.0): id: ${baseProductUnit.id}');
  } catch (e) {
    // 如果没有严格意义上的基础单位，使用第一个作为备选
    print('未找到严格的基础单位 (conversionRate == 1.0)，使用列表中的第一个单位作为备选');
    baseProductUnit = productUnits.first;
    print('备选的基础单位: id: ${baseProductUnit.id}');
  }
  final barcodes =
      await barcodeRepo.getBarcodesByProductUnitId(baseProductUnit.id);
  print('根据单位ID ${baseProductUnit.id} 查找到的条码: ${barcodes.map((e) => e.barcodeValue).toList()}');

  if (barcodes.isNotEmpty) {
    final barcodeValue = barcodes.first.barcodeValue;
    print('返回第一个条码: $barcodeValue');
    print('=============================================');
    return barcodeValue;
  }

  print('未找到任何条码，返回 null');
  print('=============================================');
  return null;
});
