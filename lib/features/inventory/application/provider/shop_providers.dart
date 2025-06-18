import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/shop.dart';
import '../../domain/repository/i_shop_repository.dart';
import '../../data/repository/shop_repository.dart';

/// 店铺操作状态
enum ShopOperationStatus { initial, loading, success, error }

/// 店铺控制器状态
class ShopControllerState {
  final ShopOperationStatus status;
  final String? errorMessage;
  final Shop? lastOperatedShop;

  const ShopControllerState({
    this.status = ShopOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedShop,
  });

  ShopControllerState copyWith({
    ShopOperationStatus? status,
    String? errorMessage,
    Shop? lastOperatedShop,
  }) {
    return ShopControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedShop: lastOperatedShop ?? this.lastOperatedShop,
    );
  }

  bool get isLoading => status == ShopOperationStatus.loading;
  bool get isError => status == ShopOperationStatus.error;
  bool get isSuccess => status == ShopOperationStatus.success;
}

/// 店铺控制器 - 管理店铺的增删改操作
class ShopController extends StateNotifier<ShopControllerState> {
  final IShopRepository _repository;

  ShopController(this._repository) : super(const ShopControllerState());

  /// 添加店铺
  Future<void> addShop(Shop shop) async {
    state = state.copyWith(status: ShopOperationStatus.loading);

    try {
      print('🎮 控制器：开始添加店铺 - ${shop.name}');

      // 检查名称是否已存在
      final exists = await _repository.isShopNameExists(shop.name);
      if (exists) {
        throw Exception('店铺名称已存在');
      }

      await _repository.addShop(shop);

      state = state.copyWith(
        status: ShopOperationStatus.success,
        lastOperatedShop: shop,
      );

      print('🎮 控制器：店铺添加成功');
    } catch (e) {
      print('🎮 控制器：店铺添加失败: $e');
      state = state.copyWith(
        status: ShopOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 更新店铺
  Future<void> updateShop(Shop shop) async {
    state = state.copyWith(status: ShopOperationStatus.loading);

    try {
      print('🎮 控制器：开始更新店铺 - ${shop.name}');

      // 检查名称是否已存在（排除当前店铺）
      final exists = await _repository.isShopNameExists(shop.name, shop.id);
      if (exists) {
        throw Exception('店铺名称已存在');
      }

      final success = await _repository.updateShop(shop);
      if (!success) {
        throw Exception('更新店铺失败');
      }

      state = state.copyWith(
        status: ShopOperationStatus.success,
        lastOperatedShop: shop,
      );

      print('🎮 控制器：店铺更新成功');
    } catch (e) {
      print('🎮 控制器：店铺更新失败: $e');
      state = state.copyWith(
        status: ShopOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 删除店铺
  Future<void> deleteShop(String id) async {
    state = state.copyWith(status: ShopOperationStatus.loading);

    try {
      print('🎮 控制器：开始删除店铺ID: $id');

      final deletedCount = await _repository.deleteShop(id);
      if (deletedCount == 0) {
        throw Exception('删除店铺失败，店铺不存在');
      }

      state = state.copyWith(status: ShopOperationStatus.success);

      print('🎮 控制器：店铺删除成功');
    } catch (e) {
      print('🎮 控制器：店铺删除失败: $e');
      state = state.copyWith(
        status: ShopOperationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 重置状态
  void resetState() {
    state = const ShopControllerState();
  }
}

// =============================================================================
// Riverpod 提供者定义
// =============================================================================

/// 店铺控制器提供者
final shopControllerProvider =
    StateNotifierProvider<ShopController, ShopControllerState>((ref) {
      final repository = ref.watch(shopRepositoryProvider);
      return ShopController(repository);
    });

/// 获取所有店铺提供者
final allShopsProvider = StreamProvider<List<Shop>>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.watchAllShops();
});

/// 根据ID获取店铺提供者
final shopByIdProvider = FutureProvider.family<Shop?, String>((ref, id) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShopById(id);
});

/// 根据名称搜索店铺提供者
final searchShopsProvider = FutureProvider.family<List<Shop>, String>((
  ref,
  searchTerm,
) {
  final repository = ref.watch(shopRepositoryProvider);
  if (searchTerm.isEmpty) {
    return repository.getAllShops();
  }
  return repository.searchShopsByName(searchTerm);
});

/// 店铺数量提供者
final shopCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShopCount();
});

/// 检查店铺名称是否存在提供者
final shopNameExistsProvider =
    FutureProvider.family<bool, Map<String, String?>>((ref, params) {
      final repository = ref.watch(shopRepositoryProvider);
      final name = params['name']!;
      final excludeId = params['excludeId'];
      return repository.isShopNameExists(name, excludeId);
    });

/// 当前选中的店铺ID提供者
final selectedShopIdProvider = StateProvider<String?>((ref) => null);

/// 当前活跃店铺提供者
final activeShopProvider = Provider<Shop?>((ref) {
  final selectedShopId = ref.watch(selectedShopIdProvider);
  if (selectedShopId == null) return null;

  final shopAsync = ref.watch(shopByIdProvider(selectedShopId));
  return shopAsync.when(
    data: (shop) => shop,
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});
