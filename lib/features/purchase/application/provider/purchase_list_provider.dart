import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/purchase_item.dart';
import '../../../product/domain/model/product.dart';

/// 采购列表状态通知器
///
/// 管理采购项列表的状态，并提供增、删、改、查等操作。
class PurchaseListNotifier extends StateNotifier<List<PurchaseItem>> {
  PurchaseListNotifier() : super([]);

  /// 添加单个采购项到列表头部
  void addItem(PurchaseItem item) {
    state = [item, ...state];
  }

  /// 添加多个采购项到列表头部
  void addAllItems(List<PurchaseItem> items) {
    state = [...items.reversed, ...state];
  }

  /// 根据ID移除采购项
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// 更新指定的采购项
  void updateItem(PurchaseItem updatedItem) {
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
  /// [defaultUnitName] - 默认单位名称
  void addOrUpdateItem({
    required Product product,
    String? unitName,
    String? barcode,
  }) {
    final actualUnitName = unitName ?? '未知单位';
    // 优先通过条码匹配，其次通过货品ID和单位匹配
    final existingItemIndex = state.indexWhere((item) {
      if (barcode != null && item.id.contains('item_${barcode}_')) {
        return true;
      }
      return item.productId == product.id && item.unitName == actualUnitName;
    });

    if (existingItemIndex != -1) {
      // 如果货品已存在，增加数量
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
        amount: (existingItem.quantity + 1) * existingItem.unitPrice,
      );
      updateItem(updatedItem);
      // 可以返回一个值或状态，用于在UI层显示提示信息
    } else {
      // 如果是新货品，创建新的采购项
      // 使用条码作为唯一标识符的一部分，以确保唯一性
      final itemId = barcode != null
          ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
          : 'item_${product.id}_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = PurchaseItem(
        id: itemId,
        productId: product.id,
        productName: product.name,
        unitName: actualUnitName,
        unitPrice: 0.0, // 初始单价为0
        quantity: 1, // 初始数量为1
        amount: 0.0, // 初始金额为0
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

/// 采购列表Provider
///
/// 这是UI层访问 [PurchaseListNotifier] 的入口。
final purchaseListProvider =
    StateNotifierProvider<PurchaseListNotifier, List<PurchaseItem>>(
      (ref) => PurchaseListNotifier(),
    );

/// 采购统计信息Provider
///
/// 派生自 [purchaseListProvider]，用于高效计算总计信息。
/// UI可以只监听这个Provider，从而避免在列表项内容变化时进行不必要的重算。
final purchaseTotalsProvider = Provider<Map<String, double>>((ref) {
  final items = ref.watch(purchaseListProvider);
  final totalQuantity = items.fold(0.0, (sum, item) => sum + item.quantity);
  final totalAmount = items.fold(0.0, (sum, item) => sum + item.amount);
  return {
    'varieties': items.length.toDouble(),
    'quantity': totalQuantity,
    'amount': totalAmount,
  };
});
