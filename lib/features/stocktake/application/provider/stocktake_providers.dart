import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/stocktake_order.dart';
import '../../domain/model/stocktake_item.dart';
import '../../domain/model/stocktake_status.dart';
import '../stocktake_service.dart';

/// 盘点单列表 Provider
final stocktakeListProvider = StreamProvider.family<List<StocktakeOrderModel>, int?>((ref, shopId) {
  final service = ref.watch(stocktakeServiceProvider);
  return service.watchStocktakeList(shopId: shopId);
});

/// 当前盘点单 Provider
final currentStocktakeProvider = FutureProvider.family<StocktakeOrderModel?, int>((ref, stocktakeId) {
  final service = ref.watch(stocktakeServiceProvider);
  return service.getStocktakeOrder(stocktakeId);
});

/// 盘点项列表 Provider
final stocktakeItemsProvider = StreamProvider.family<List<StocktakeItemModel>, int>((ref, stocktakeId) {
  final service = ref.watch(stocktakeServiceProvider);
  return service.watchStocktakeItems(stocktakeId);
});

/// 盘点汇总 Provider
final stocktakeSummaryProvider = FutureProvider.family<StocktakeSummary, int>((ref, stocktakeId) {
  final service = ref.watch(stocktakeServiceProvider);
  return service.getSummary(stocktakeId);
});

/// 差异项列表 Provider
final stocktakeDiffItemsProvider = FutureProvider.family<List<StocktakeItemModel>, int>((ref, stocktakeId) {
  final service = ref.watch(stocktakeServiceProvider);
  return service.getDiffItems(stocktakeId);
});

/// 创建盘点单状态
class CreateStocktakeState {
  final int? shopId;
  final StocktakeType type;
  final int? categoryId;
  final String? remarks;
  final bool isLoading;
  final String? error;

  const CreateStocktakeState({
    this.shopId,
    this.type = StocktakeType.full,
    this.categoryId,
    this.remarks,
    this.isLoading = false,
    this.error,
  });

  CreateStocktakeState copyWith({
    int? shopId,
    StocktakeType? type,
    int? categoryId,
    String? remarks,
    bool? isLoading,
    String? error,
  }) {
    return CreateStocktakeState(
      shopId: shopId ?? this.shopId,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      remarks: remarks ?? this.remarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 创建盘点单 Notifier
class CreateStocktakeNotifier extends StateNotifier<CreateStocktakeState> {
  final Ref _ref;

  CreateStocktakeNotifier(this._ref) : super(const CreateStocktakeState());

  void setShopId(int shopId) {
    state = state.copyWith(shopId: shopId);
  }

  void setType(StocktakeType type) {
    state = state.copyWith(type: type, categoryId: null);
  }

  void setCategoryId(int? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setRemarks(String? remarks) {
    state = state.copyWith(remarks: remarks);
  }

  Future<StocktakeOrderModel?> createStocktake() async {
    if (state.shopId == null) {
      state = state.copyWith(error: '请选择店铺');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final order = await service.createStocktake(
        shopId: state.shopId!,
        type: state.type,
        categoryId: state.categoryId,
        remarks: state.remarks,
      );

      state = state.copyWith(isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const CreateStocktakeState();
  }
}

final createStocktakeNotifierProvider =
    StateNotifierProvider<CreateStocktakeNotifier, CreateStocktakeState>((ref) {
  return CreateStocktakeNotifier(ref);
});

/// 盘点录入状态
class StocktakeEntryState {
  final int stocktakeId;
  final int shopId;
  final bool isLoading;
  final String? error;

  const StocktakeEntryState({
    required this.stocktakeId,
    required this.shopId,
    this.isLoading = false,
    this.error,
  });

  StocktakeEntryState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return StocktakeEntryState(
      stocktakeId: stocktakeId,
      shopId: shopId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 盘点录入 Notifier
class StocktakeEntryNotifier extends StateNotifier<StocktakeEntryState> {
  final Ref _ref;

  StocktakeEntryNotifier(this._ref, int stocktakeId, int shopId)
      : super(StocktakeEntryState(stocktakeId: stocktakeId, shopId: shopId));

  Future<StocktakeItemModel?> addItem({
    required int productId,
    required int actualQuantity,
    int? batchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final item = await service.addStocktakeItem(
        stocktakeId: state.stocktakeId,
        productId: productId,
        actualQuantity: actualQuantity,
        batchId: batchId,
        shopId: state.shopId,
      );

      state = state.copyWith(isLoading: false);

      // 刷新盘点项列表
      _ref.invalidate(stocktakeItemsProvider(state.stocktakeId));
      _ref.invalidate(stocktakeSummaryProvider(state.stocktakeId));

      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> updateQuantity(int itemId, int quantity) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final success = await service.updateActualQuantity(itemId, quantity);

      state = state.copyWith(isLoading: false);

      if (success) {
        _ref.invalidate(stocktakeItemsProvider(state.stocktakeId));
        _ref.invalidate(stocktakeSummaryProvider(state.stocktakeId));
      }

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final success = await service.deleteStocktakeItem(itemId);

      state = state.copyWith(isLoading: false);

      if (success) {
        _ref.invalidate(stocktakeItemsProvider(state.stocktakeId));
        _ref.invalidate(stocktakeSummaryProvider(state.stocktakeId));
      }

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<StocktakeSummary?> completeStocktake() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final summary = await service.completeStocktake(state.stocktakeId);

      state = state.copyWith(isLoading: false);

      if (summary != null) {
        _ref.invalidate(currentStocktakeProvider(state.stocktakeId));
        _ref.invalidate(stocktakeListProvider(null));
      }

      return summary;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final stocktakeEntryNotifierProvider = StateNotifierProvider.family<
    StocktakeEntryNotifier, StocktakeEntryState, ({int stocktakeId, int shopId})>(
  (ref, params) => StocktakeEntryNotifier(ref, params.stocktakeId, params.shopId),
);

/// 差异确认 Notifier
class StocktakeDiffNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final int stocktakeId;

  StocktakeDiffNotifier(this._ref, this.stocktakeId) : super(false);

  Future<bool> confirmAdjustment() async {
    state = true;

    try {
      final service = _ref.read(stocktakeServiceProvider);
      final success = await service.confirmAdjustment(stocktakeId);

      state = false;

      if (success) {
        _ref.invalidate(currentStocktakeProvider(stocktakeId));
        _ref.invalidate(stocktakeListProvider(null));
        _ref.invalidate(stocktakeDiffItemsProvider(stocktakeId));
      }

      return success;
    } catch (e) {
      state = false;
      return false;
    }
  }

  Future<bool> updateReason(int itemId, String reason) async {
    try {
      final service = _ref.read(stocktakeServiceProvider);
      final success = await service.updateDifferenceReason(itemId, reason);

      if (success) {
        _ref.invalidate(stocktakeDiffItemsProvider(stocktakeId));
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}

final stocktakeDiffNotifierProvider =
    StateNotifierProvider.family<StocktakeDiffNotifier, bool, int>(
  (ref, stocktakeId) => StocktakeDiffNotifier(ref, stocktakeId),
);
