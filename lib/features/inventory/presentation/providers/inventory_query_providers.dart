import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/inventory_query_service.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../domain/model/aggregated_inventory.dart';
import '../../../../config/flavor_config.dart';

enum InventorySortType { none, byQuantity, byShelfLife }

/// 库存筛选状态
class InventoryFilterState {
  final String selectedShop;
  final String selectedCategory;
  final String selectedStatus;
  final InventorySortType sortBy;

  const InventoryFilterState({
    this.selectedShop = '所有仓库',
    this.selectedCategory = '所有分类',
    this.selectedStatus = '库存状态',
    this.sortBy = InventorySortType.none,
  });

  InventoryFilterState copyWith({
    String? selectedShop,
    String? selectedCategory,
    String? selectedStatus,
    InventorySortType? sortBy,
  }) {
    return InventoryFilterState(
      selectedShop: selectedShop ?? this.selectedShop,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// 库存筛选状态管理器
class InventoryFilterNotifier extends StateNotifier<InventoryFilterState> {
  InventoryFilterNotifier() : super(const InventoryFilterState());

  void updateShop(String? shop) {
    if (shop == '所有仓库') shop = null;
    state = state.copyWith(selectedShop: shop ?? '所有仓库');
  }

  void updateCategory(String? category) {
    if (category == '所有分类') category = null;
    state = state.copyWith(selectedCategory: category ?? '所有分类');
  }

  void updateStatus(String? status) {
    if (status == '库存状态') status = null;
    state = state.copyWith(selectedStatus: status ?? '库存状态');
  }

  void updateSortBy(InventorySortType sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void reset() {
    state = const InventoryFilterState();
  }
}

/// 库存筛选Provider
final inventoryFilterProvider =
    StateNotifierProvider<InventoryFilterNotifier, InventoryFilterState>((ref) {
      final flavor = ref.watch(flavorConfigProvider).flavor;
      final isGeneric = flavor == AppFlavor.generic;
      final notifier = InventoryFilterNotifier();
      if (isGeneric) {
        notifier.updateShop('我的店铺');
      }
      return notifier;
    });

/// 库存查询数据Provider - 使用真实数据库查询
/// 添加对产品数据变化的监听，确保产品图片更新后库存页面能同步刷新
/// 支持聚合模式：未筛选店铺时返回聚合数据，筛选店铺时返回原始数据
final inventoryQueryProvider = FutureProvider<dynamic>((
  ref,
) async {
  final filterState = ref.watch(inventoryFilterProvider);
  final queryService = ref.watch(inventoryQueryServiceProvider);
  
  // 监听产品数据变化，确保产品信息（包括图片）更新后库存页面能同步刷新
  ref.watch(productListStreamProvider);
  
  // 将默认值转换为null传递给查询服务
  final shopFilter = filterState.selectedShop == '所有仓库'
      ? null
      : filterState.selectedShop;
  final categoryFilter = filterState.selectedCategory == '所有分类'
      ? null
      : filterState.selectedCategory;
  final statusFilter = filterState.selectedStatus == '库存状态'
      ? null
      : filterState.selectedStatus;

  final sortBy = filterState.sortBy;

  // 判断是否需要聚合：未筛选店铺时使用聚合模式
  if (shopFilter == null) {
    // 聚合模式：返回聚合数据
    final aggregatedData = await queryService.getAggregatedInventory(
      categoryFilter: categoryFilter,
      statusFilter: statusFilter,
    );

    // 应用排序到聚合数据
    _applySortToAggregated(aggregatedData, sortBy);

    return aggregatedData;
  } else {
    // 原始模式：返回原始数据
    final data = await queryService.getInventoryWithDetails(
      shopFilter: shopFilter,
      categoryFilter: categoryFilter,
      statusFilter: statusFilter,
    );

    // 应用排序到原始数据
    _applySortToOriginal(data, sortBy);

    return data;
  }
});

/// 对聚合数据应用排序
void _applySortToAggregated(
  List<AggregatedInventoryItem> data,
  InventorySortType sortBy,
) {
  if (sortBy == InventorySortType.byQuantity) {
    data.sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));
  } else if (sortBy == InventorySortType.byShelfLife) {
    // 按最短剩余保质期排序
    data.sort((a, b) {
      final aMinDays = a.minRemainingDays;
      final bMinDays = b.minRemainingDays;
      
      // 没有保质期信息的排在后面
      if (aMinDays == null && bMinDays == null) return 0;
      if (aMinDays == null) return 1;
      if (bMinDays == null) return -1;
      
      return aMinDays.compareTo(bMinDays);
    });
  }
}

/// 对原始数据应用排序
void _applySortToOriginal(
  List<Map<String, dynamic>> data,
  InventorySortType sortBy,
) {
  if (sortBy == InventorySortType.byQuantity) {
    data.sort((a, b) => (a['quantity'] as num).compareTo(b['quantity'] as num));
  } else if (sortBy == InventorySortType.byShelfLife) {
    final now = DateTime.now();
    final filteredData = data.where((item) {
      final productionDateStr = item['productionDate'];
      final shelfLifeDays = item['shelfLifeDays'];
      final shelfLifeUnit = item['shelfLifeUnit'];
      return productionDateStr is String &&
          productionDateStr.isNotEmpty &&
          shelfLifeDays is int &&
          shelfLifeUnit is String;
    }).toList();

    filteredData.sort((a, b) {
      try {
        // 安全解析日期字符串
        final aDateStr = (a['productionDate'] as String).trim();
        final bDateStr = (b['productionDate'] as String).trim();
        
        // 尝试解析日期，如果失败则跳过
        DateTime aProductionDate;
        DateTime bProductionDate;
        
        try {
          aProductionDate = DateTime.parse(aDateStr);
        } catch (e) {
          return 1; // 解析失败的项排在后面
        }
        
        try {
          bProductionDate = DateTime.parse(bDateStr);
        } catch (e) {
          return -1; // 解析失败的项排在后面
        }
        
        final aShelfLife = a['shelfLifeDays'] as int;
        final aShelfLifeUnit = a['shelfLifeUnit'] as String;
        
        // 根据保质期单位转换为天数
        int aShelfLifeInDays;
        switch (aShelfLifeUnit) {
          case 'days':
            aShelfLifeInDays = aShelfLife;
            break;
          case 'months':
            aShelfLifeInDays = aShelfLife * 30; // 近似值
            break;
          case 'years':
            aShelfLifeInDays = aShelfLife * 365; // 近似值
            break;
          default:
            aShelfLifeInDays = aShelfLife; // 默认按天处理
        }
        
        final aExpiryDate = aProductionDate.add(Duration(days: aShelfLifeInDays));
        final aRemaining = aExpiryDate.difference(now);

        final bShelfLife = b['shelfLifeDays'] as int;
        final bShelfLifeUnit = b['shelfLifeUnit'] as String;
        
        // 根据保质期单位转换为天数
        int bShelfLifeInDays;
        switch (bShelfLifeUnit) {
          case 'days':
            bShelfLifeInDays = bShelfLife;
            break;
          case 'months':
            bShelfLifeInDays = bShelfLife * 30; // 近似值
            break;
          case 'years':
            bShelfLifeInDays = bShelfLife * 365; // 近似值
            break;
          default:
            bShelfLifeInDays = bShelfLife; // 默认按天处理
        }
        
        final bExpiryDate = bProductionDate.add(Duration(days: bShelfLifeInDays));
        final bRemaining = bExpiryDate.difference(now);

        return aRemaining.compareTo(bRemaining);
      } catch (e) {
        // 如果解析失败，则将该项排在后面
        return 1;
      }
    });
    
    // 将排序后的数据复制回原列表
    data.clear();
    data.addAll(filteredData);
  }
}
