import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/supplier.dart';
import '../../domain/repository/i_supplier_repository.dart';
import '../../data/repository/supplier_repository.dart';
import '../../../../core/database/database.dart';

/// 供应商操作状态
enum SupplierOperationStatus { initial, loading, success, error }

/// 供应商控制器状态
class SupplierControllerState {
  final SupplierOperationStatus status;
  final String? errorMessage;
  final Supplier? lastOperatedSupplier;

  const SupplierControllerState({
    this.status = SupplierOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedSupplier,
  });

  SupplierControllerState copyWith({
    SupplierOperationStatus? status,
    String? errorMessage,
    Supplier? lastOperatedSupplier,
  }) {
    return SupplierControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedSupplier: lastOperatedSupplier ?? this.lastOperatedSupplier,
    );
  }

  bool get isLoading => status == SupplierOperationStatus.loading;
  bool get isError => status == SupplierOperationStatus.error;
  bool get isSuccess => status == SupplierOperationStatus.success;
}

/// 供应商控制器 - 管理供应商的增删改操作
class SupplierController extends StateNotifier<SupplierControllerState> {
  final ISupplierRepository _repository;

  SupplierController(this._repository) : super(const SupplierControllerState());

  /// 添加供应商
  Future<void> addSupplier(Supplier supplier) async {
    state = state.copyWith(status: SupplierOperationStatus.loading);

    try {
      print('🎮 控制器：开始添加供应商 - ${supplier.name}');

      // 检查名称是否已存在
      final exists = await _repository.isSupplierNameExists(supplier.name);
      if (exists) {
        throw Exception('供应商名称已存在');
      }

      await _repository.addSupplier(supplier);

      state = state.copyWith(
        status: SupplierOperationStatus.success,
        lastOperatedSupplier: supplier,
      );

      print('🎮 控制器：供应商添加成功');
    } catch (e) {
      print('🎮 控制器：供应商添加失败: $e');
      state = state.copyWith(
        status: SupplierOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 更新供应商
  Future<void> updateSupplier(Supplier supplier) async {
    state = state.copyWith(status: SupplierOperationStatus.loading);

    try {
      print('🎮 控制器：开始更新供应商 - ${supplier.name}');

      // 检查名称是否已存在（排除当前供应商）
      final exists = await _repository.isSupplierNameExists(
        supplier.name,
        supplier.id,
      );
      if (exists) {
        throw Exception('供应商名称已存在');
      }

      final success = await _repository.updateSupplier(supplier);
      if (!success) {
        throw Exception('更新供应商失败');
      }

      state = state.copyWith(
        status: SupplierOperationStatus.success,
        lastOperatedSupplier: supplier,
      );

      print('🎮 控制器：供应商更新成功');
    } catch (e) {
      print('🎮 控制器：供应商更新失败: $e');
      state = state.copyWith(
        status: SupplierOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 删除供应商
  Future<void> deleteSupplier(String id) async {
    state = state.copyWith(status: SupplierOperationStatus.loading);

    try {
      print('🎮 控制器：开始删除供应商 - $id');

      final deletedCount = await _repository.deleteSupplier(id);
      if (deletedCount == 0) {
        throw Exception('删除供应商失败，未找到指定供应商');
      }

      state = state.copyWith(status: SupplierOperationStatus.success);

      print('🎮 控制器：供应商删除成功');
    } catch (e) {
      print('🎮 控制器：供应商删除失败: $e');
      state = state.copyWith(
        status: SupplierOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 重置状态
  void resetState() {
    state = const SupplierControllerState();
  }
}

// =============================================================================
// Riverpod 提供者定义
// =============================================================================

/// 供应商仓储提供者
final supplierRepositoryProvider = Provider<ISupplierRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SupplierRepository(database);
});

/// 供应商控制器提供者
final supplierControllerProvider =
    StateNotifierProvider<SupplierController, SupplierControllerState>((ref) {
      final repository = ref.watch(supplierRepositoryProvider);
      return SupplierController(repository);
    });

/// 获取所有供应商提供者
final allSuppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.watchAllSuppliers();
});

/// 根据ID获取供应商提供者
final supplierByIdProvider = FutureProvider.family<Supplier?, String>((
  ref,
  id,
) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.getSupplierById(id);
});

/// 根据名称搜索供应商提供者
final searchSuppliersProvider = FutureProvider.family<List<Supplier>, String>((
  ref,
  searchTerm,
) {
  final repository = ref.watch(supplierRepositoryProvider);
  if (searchTerm.isEmpty) {
    return repository.getAllSuppliers();
  }
  return repository.searchSuppliersByName(searchTerm);
});

/// 供应商数量提供者
final supplierCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.getSupplierCount();
});

/// 检查供应商名称是否存在提供者
final supplierNameExistsProvider =
    FutureProvider.family<bool, Map<String, String?>>((ref, params) {
      final repository = ref.watch(supplierRepositoryProvider);
      final name = params['name']!;
      final excludeId = params['excludeId'];
      return repository.isSupplierNameExists(name, excludeId);
    });
