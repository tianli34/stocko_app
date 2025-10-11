import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/domain/model/product.dart';

/// Represents an item in the inbound list UI.
/// This is a view model that combines data from Product, Unit,
/// and the temporary inbound state.
class InboundItemState {
  /// A unique identifier for the item in the UI list, generated on the client.
  final String id;
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final int quantity;
  final int unitPriceInCents;
  final int conversionRate; // 新增：单位换算率
  final DateTime? productionDate;
  final String? barcode;

  InboundItemState({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.quantity,
    required this.unitPriceInCents,
    required this.conversionRate, // 新增
    this.productionDate,
    this.barcode,
  });

  /// Total amount for this item line, in cents.
  int get amountInCents => quantity * unitPriceInCents;

  /// The total quantity in the base unit.
  // int get totalBaseQuantity => quantity * conversionRate;
  int get totalBaseQuantity => quantity;

  InboundItemState copyWith({
    String? id,
    int? productId,
    String? productName,
    int? unitId,
    String? unitName,
    int? quantity,
    int? unitPriceInCents,
    int? conversionRate, // 新增
    DateTime? productionDate,
    String? barcode,
    bool clearProductionDate = false,
  }) {
    return InboundItemState(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      quantity: quantity ?? this.quantity,
      unitPriceInCents: unitPriceInCents ?? this.unitPriceInCents,
      conversionRate: conversionRate ?? this.conversionRate, // 新增
      productionDate:
          clearProductionDate ? null : productionDate ?? this.productionDate,
      barcode: barcode ?? this.barcode,
    );
  }
}

/// 入库列表状态通知器
///
/// 管理入库项列表的状态，并提供增、删、改、查等操作。
class InboundListNotifier extends StateNotifier<List<InboundItemState>> {
  InboundListNotifier() : super([]);

  /// 添加单个入库项到列表头部
  void addItem(InboundItemState item) {
    state = [item, ...state];
  }

  /// 添加多个入库项到列表头部
  void addAllItems(List<InboundItemState> items) {
    state = [...items.reversed, ...state];
  }

  /// 根据ID移除入库项
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// 更新指定的入库项
  void updateItem(InboundItemState updatedItem) {
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
  }

  /// 添加一个新货品，或如果已存在则更新其数量
  /// 合并策略：优先按条码匹配，如果没有条码或条码不匹配，则按产品ID+单位ID匹配
  void addOrUpdateItem({
    required ProductModel product,
    required int unitId,
    String? unitName,
    required int conversionRate,
    String? barcode,
    int? wholesalePriceInCents,
    int quantity = 1,
  }) {
    int existingItemIndex = -1;
    
    // 优先按条码匹配（如果提供了条码）
    if (barcode != null && barcode.isNotEmpty) {
      existingItemIndex = state.indexWhere((item) => item.barcode == barcode);
    }
    
    // 如果按条码没找到，则按产品ID+单位ID匹配
    if (existingItemIndex == -1) {
      existingItemIndex = state.indexWhere((item) =>
          item.productId == product.id && item.unitId == unitId);
    }

    if (existingItemIndex != -1) {
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      updateItem(updatedItem);
    } else {
      final itemId =
          'item_${product.id}_${unitId}_${DateTime.now().millisecondsSinceEpoch}';
      final newItem = InboundItemState(
        id: itemId,
        productId: product.id!,
        productName: product.name,
        unitId: unitId,
        unitName: unitName ?? '未知单位',
        quantity: quantity,
        unitPriceInCents: wholesalePriceInCents ?? 0,
        conversionRate: conversionRate,
        barcode: barcode,
        productionDate: product.enableBatchManagement
            ? DateTime.now().subtract(const Duration(days: 90))
            : null,
      );
      addItem(newItem);
    }
  }

  /// 清空整个列表
  void clear() {
    state = [];
  }
}

/// 入库列表Provider
///
/// 这是UI层访问 [InboundListNotifier] 的入口。
final inboundListProvider =
    StateNotifierProvider<InboundListNotifier, List<InboundItemState>>(
  (ref) => InboundListNotifier(),
);

/// 入库统计信息Provider
///
/// 派生自 [inboundListProvider]，用于高效计算总计信息。
/// UI可以只监听这个Provider，从而避免在列表项内容变化时进行不必要的重算。
final inboundTotalsProvider = Provider<Map<String, double>>((ref) {
  final items = ref.watch(inboundListProvider);
  // 使用 `totalBaseQuantity` 计算基础单位总数
  final totalQuantity =
      items.fold(0.0, (sum, item) => sum + item.totalBaseQuantity);
  final totalAmountInCents =
      items.fold(0.0, (sum, item) => sum + item.amountInCents);
  return {
    'varieties': items.length.toDouble(),
    'quantity': totalQuantity,
    'amount': totalAmountInCents / 100.0, // 将总金额从分转换为元
  };
});
