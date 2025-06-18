import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/inventory_query_service.dart';

/// 库存筛选状态
class InventoryFilterState {
  final String selectedShop;
  final String selectedCategory;
  final String selectedStatus;

  const InventoryFilterState({
    this.selectedShop = '全部',
    this.selectedCategory = '全部',
    this.selectedStatus = '全部',
  });

  InventoryFilterState copyWith({
    String? selectedShop,
    String? selectedCategory,
    String? selectedStatus,
  }) {
    return InventoryFilterState(
      selectedShop: selectedShop ?? this.selectedShop,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

/// 库存筛选状态管理器
class InventoryFilterNotifier extends StateNotifier<InventoryFilterState> {
  InventoryFilterNotifier() : super(const InventoryFilterState());
  void updateShop(String? shop) {
    if (shop == '所有仓库') shop = null;
    state = state.copyWith(selectedShop: shop);
  }

  void updateCategory(String? category) {
    if (category == '所有类别') category = null;
    state = state.copyWith(selectedCategory: category);
  }

  void updateStatus(String? status) {
    if (status == '库存状态') status = null;
    state = state.copyWith(selectedStatus: status);
  }

  void reset() {
    state = const InventoryFilterState();
  }
}

/// 库存筛选Provider
final inventoryFilterProvider =
    StateNotifierProvider<InventoryFilterNotifier, InventoryFilterState>((ref) {
      return InventoryFilterNotifier();
    });

/// 库存查询数据Provider - 使用真实数据库查询
final inventoryQueryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final filterState = ref.watch(inventoryFilterProvider);
  final queryService = ref.watch(inventoryQueryServiceProvider);

  // 将"全部"转换为null传递给查询服务
  final shopFilter = filterState.selectedShop == '全部'
      ? null
      : filterState.selectedShop;
  final categoryFilter = filterState.selectedCategory == '全部'
      ? null
      : filterState.selectedCategory;
  final statusFilter = filterState.selectedStatus == '全部'
      ? null
      : filterState.selectedStatus;

  // 调用真实的库存查询服务
  return await queryService.getInventoryWithDetails(
    shopFilter: shopFilter,
    categoryFilter: categoryFilter,
    statusFilter: statusFilter,
  );
});
