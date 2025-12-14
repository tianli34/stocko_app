import '../model/stocktake_item.dart';

/// 盘点明细仓库接口
abstract class IStocktakeItemRepository {
  /// 添加盘点项
  Future<int> addItem(StocktakeItemModel item);

  /// 批量添加盘点项
  Future<void> addItems(List<StocktakeItemModel> items);

  /// 更新盘点项
  Future<bool> updateItem(StocktakeItemModel item);

  /// 删除盘点项
  Future<bool> deleteItem(int id);

  /// 删除盘点单的所有盘点项
  Future<bool> deleteItemsByStocktakeId(int stocktakeId);

  /// 根据ID获取盘点项
  Future<StocktakeItemModel?> getItemById(int id);

  /// 获取盘点单的所有盘点项
  Future<List<StocktakeItemModel>> getItemsByStocktakeId(int stocktakeId);

  /// 根据商品ID获取盘点项（同一盘点单内）
  Future<StocktakeItemModel?> getItemByProductId(
      int stocktakeId, int productId, int? batchId);

  /// 更新实盘数量
  Future<bool> updateActualQuantity(int id, int actualQuantity);

  /// 更新差异原因
  Future<bool> updateDifferenceReason(int id, String reason);

  /// 标记为已调整
  Future<bool> markAsAdjusted(int id);

  /// 批量标记为已调整
  Future<int> markAllAsAdjusted(int stocktakeId);

  /// 获取有差异的盘点项
  Future<List<StocktakeItemModel>> getDiffItems(int stocktakeId);

  /// 获取未调整的差异项
  Future<List<StocktakeItemModel>> getUnadjustedDiffItems(int stocktakeId);

  /// 监听盘点项列表
  Stream<List<StocktakeItemModel>> watchItemsByStocktakeId(int stocktakeId);

  /// 获取盘点汇总
  Future<StocktakeSummary> getSummary(int stocktakeId);
}
