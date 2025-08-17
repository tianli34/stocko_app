import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/domain/model/product.dart';
import '../../domain/model/sale_cart_item.dart';

/// 销售列表状态通知器
///
/// 管理销售项列表的状态，并提供增、删、改、查等操作。
class SaleListNotifier extends StateNotifier<List<SaleCartItem>> {
  SaleListNotifier() : super([]);

  /// 添加单个销售项到列表头部
  void addItem(SaleCartItem item) {
    state = [item, ...state];
  }

  /// 添加多个销售项到列表头部
  void addAllItems(List<SaleCartItem> items) {
    state = [...items.reversed, ...state];
  }

  /// 根据ID移除销售项
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// 更新指定的销售项
  void updateItem(SaleCartItem updatedItem) {
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
  /// [sellingPriceInCents] - 销售价
  void addOrUpdateItem({
    required ProductModel product,
    required int unitId,
    String? unitName,
    String? barcode,
    String? batchId,
    int? sellingPriceInCents,
  }) {
    final actualUnitName = unitName ?? '未知单位';
    // 优先通过条码匹配，其次通过货品ID和单位匹配
    final existingItemIndex = state.indexWhere((item) {
      if (barcode != null && item.id.contains('item_${barcode}_')) {
        return true;
      }
      return item.productId == product.id! && item.unitId == unitId;
    });

    if (existingItemIndex != -1) {
      // 如果货品已存在，增加数量
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
        amount: (existingItem.quantity + 1) * existingItem.sellingPriceInCents/100,
      );
      updateItem(updatedItem);
    } else {
      // 如果是新货品，创建新的销售项
      final itemId = barcode != null
          ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
          : 'item_${product.id!}_${unitId}_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = SaleCartItem(
        id: itemId,
        productId: product.id!,
        productName: product.name,
        unitId: unitId,
        unitName: actualUnitName,
        batchId: batchId,
        sellingPriceInCents: sellingPriceInCents ?? 0,
        quantity: 1,
        amount: (sellingPriceInCents ?? 0.0) / 100, // 转换为元
      );
      addItem(newItem);
    }
  }

  /// 清空整个列表
  void clear() {
    state = [];
  }
}

/// 销售列表Provider
///
/// 这是UI层访问 [SaleListNotifier] 的入口。
final saleListProvider =
    StateNotifierProvider<SaleListNotifier, List<SaleCartItem>>(
      (ref) => SaleListNotifier(),
    );

/// 销售统计信息Provider
///
/// 派生自 [saleListProvider]，用于高效计算总计信息。
final saleTotalsProvider = Provider<Map<String, double>>((ref) {
  final items = ref.watch(saleListProvider);
  final totalQuantity = items.fold(0.0, (sum, item) => sum + item.quantity);
  final totalAmount = items.fold(0.0, (sum, item) => sum + item.amount);
  return {
    'varieties': items.length.toDouble(),
    'quantity': totalQuantity,
    'amount': totalAmount,
  };
});