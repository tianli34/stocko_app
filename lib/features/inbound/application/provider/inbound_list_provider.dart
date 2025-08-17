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
    this.productionDate,
    this.barcode,
  });

  /// Total amount for this item line, in cents.
  int get amountInCents => quantity * unitPriceInCents;

  InboundItemState copyWith({
    String? id,
    int? productId,
    String? productName,
    int? unitId,
    String? unitName,
    int? quantity,
    int? unitPriceInCents,
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
  ///
  /// [product] - 要添加的货品对象
  /// [unitName] - 单位名称
  /// [barcode] - 条码
  void addOrUpdateItem({
    required ProductModel product,
    required int unitId,
    String? unitName,
    String? barcode,
    int? wholesalePriceInCents,
  }) {
    // 优先通过条码匹配，其次通过货品ID和单位匹配
    final existingItemIndex = state.indexWhere((item) {
      if (barcode != null && barcode.isNotEmpty && item.barcode == barcode) {
        return true;
      }
      // Fallback to product and unit if no barcode match or barcode is not provided
      return item.productId == product.id && item.unitId == unitId;
    });

    if (existingItemIndex != -1) {
      // 如果货品已存在，增加数量
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      updateItem(updatedItem);
    } else {
      // 如果是新货品，创建新的入库项
      // 使用条码或货品+单位作为唯一标识符的一部分，以确保列表中的唯一性
      final itemId = (barcode != null && barcode.isNotEmpty)
          ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
          : 'item_${product.id}_${unitId}_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = InboundItemState(
        id: itemId,
        productId: product.id!,
        productName: product.name,
        unitId: unitId,
        unitName: unitName ?? '未知单位',
        quantity: 1,
        unitPriceInCents: wholesalePriceInCents ?? 0,
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
  final totalQuantity = items.fold(0.0, (sum, item) => sum + item.quantity);
  final totalAmountInCents =
      items.fold(0.0, (sum, item) => sum + item.amountInCents);
  return {
    'varieties': items.length.toDouble(),
    'quantity': totalQuantity,
    'amount': totalAmountInCents / 100.0, // 将总金额从分转换为元
  };
});
