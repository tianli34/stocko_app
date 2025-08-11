import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/barcode.dart';
import '../../domain/repository/i_barcode_repository.dart';
import '../../data/repository/barcode_repository.dart';

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
  Future<void> deleteBarcodesByProductUnitId(int productUnitId) async {
    state = state.copyWith(status: BarcodeOperationStatus.loading);

    try {
      final deletedCount = await _repository.deleteBarcodesByProductUnitId(
        productUnitId,
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
  Future<List<BarcodeModel>> getBarcodesByProductUnitId(int? productUnitId) async {
    try {
      return await _repository.getBarcodesByProductUnitId(productUnitId);
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
    StreamProvider.family<List<BarcodeModel>, int>((ref, productUnitId) {
      final repository = ref.watch(barcodeRepositoryProvider);
      return repository.watchBarcodesByProductUnitId(productUnitId);
    });

/// 获取所有条码的 Provider
final allBarcodesProvider = FutureProvider<List<BarcodeModel>>((ref) async {
  final repository = ref.watch(barcodeRepositoryProvider);
  return repository.getAllBarcodes();
});
