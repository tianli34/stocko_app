import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/stocktake_items_table.dart';

part 'stocktake_item_dao.g.dart';

@DriftAccessor(tables: [StocktakeItem])
class StocktakeItemDao extends DatabaseAccessor<AppDatabase>
    with _$StocktakeItemDaoMixin {
  StocktakeItemDao(super.db);

  /// 插入盘点项
  Future<int> insertItem(StocktakeItemCompanion item) {
    return into(stocktakeItem).insert(item);
  }

  /// 批量插入盘点项
  Future<void> insertItems(List<StocktakeItemCompanion> items) async {
    await batch((batch) {
      batch.insertAll(stocktakeItem, items);
    });
  }

  /// 更新盘点项
  Future<bool> updateItem(StocktakeItemCompanion item, int id) {
    return (update(stocktakeItem)..where((t) => t.id.equals(id)))
        .write(item)
        .then((rows) => rows > 0);
  }

  /// 删除盘点项
  Future<int> deleteItem(int id) {
    return (delete(stocktakeItem)..where((t) => t.id.equals(id))).go();
  }

  /// 删除盘点单的所有盘点项
  Future<int> deleteItemsByStocktakeId(int stocktakeId) {
    return (delete(stocktakeItem)
          ..where((t) => t.stocktakeId.equals(stocktakeId)))
        .go();
  }

  /// 根据ID获取盘点项
  Future<StocktakeItemData?> getItemById(int id) {
    return (select(stocktakeItem)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取盘点单的所有盘点项
  Future<List<StocktakeItemData>> getItemsByStocktakeId(int stocktakeId) {
    return (select(stocktakeItem)
          ..where((t) => t.stocktakeId.equals(stocktakeId))
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .get();
  }

  /// 根据商品ID获取盘点项（同一盘点单内）
  Future<StocktakeItemData?> getItemByProductId(
      int stocktakeId, int productId, int? batchId) {
    final query = select(stocktakeItem)
      ..where((t) =>
          t.stocktakeId.equals(stocktakeId) & t.productId.equals(productId));
    
    if (batchId != null) {
      query.where((t) => t.batchId.equals(batchId));
    } else {
      query.where((t) => t.batchId.isNull());
    }
    
    return query.getSingleOrNull();
  }

  /// 更新实盘数量
  Future<bool> updateActualQuantity(int id, int actualQuantity, int differenceQty) {
    return (update(stocktakeItem)..where((t) => t.id.equals(id)))
        .write(StocktakeItemCompanion(
          actualQuantity: Value(actualQuantity),
          differenceQty: Value(differenceQty),
        ))
        .then((rows) => rows > 0);
  }

  /// 更新差异原因
  Future<bool> updateDifferenceReason(int id, String reason) {
    return (update(stocktakeItem)..where((t) => t.id.equals(id)))
        .write(StocktakeItemCompanion(differenceReason: Value(reason)))
        .then((rows) => rows > 0);
  }

  /// 标记为已调整
  Future<bool> markAsAdjusted(int id) {
    return (update(stocktakeItem)..where((t) => t.id.equals(id)))
        .write(const StocktakeItemCompanion(isAdjusted: Value(true)))
        .then((rows) => rows > 0);
  }

  /// 批量标记为已调整
  Future<int> markAllAsAdjusted(int stocktakeId) {
    return (update(stocktakeItem)
          ..where((t) => t.stocktakeId.equals(stocktakeId)))
        .write(const StocktakeItemCompanion(isAdjusted: Value(true)));
  }

  /// 获取有差异的盘点项
  Future<List<StocktakeItemData>> getDiffItems(int stocktakeId) {
    return (select(stocktakeItem)
          ..where((t) =>
              t.stocktakeId.equals(stocktakeId) & t.differenceQty.equals(0).not())
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .get();
  }

  /// 获取未调整的差异项
  Future<List<StocktakeItemData>> getUnadjustedDiffItems(int stocktakeId) {
    return (select(stocktakeItem)
          ..where((t) =>
              t.stocktakeId.equals(stocktakeId) &
              t.differenceQty.equals(0).not() &
              t.isAdjusted.equals(false)))
        .get();
  }

  /// 监听盘点项列表
  Stream<List<StocktakeItemData>> watchItemsByStocktakeId(int stocktakeId) {
    return (select(stocktakeItem)
          ..where((t) => t.stocktakeId.equals(stocktakeId))
          ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
        .watch();
  }

  /// 统计盘点项数量
  Future<int> countItems(int stocktakeId) async {
    final count = stocktakeItem.id.count();
    final query = selectOnly(stocktakeItem)
      ..addColumns([count])
      ..where(stocktakeItem.stocktakeId.equals(stocktakeId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// 统计有差异的盘点项数量
  Future<int> countDiffItems(int stocktakeId) async {
    final count = stocktakeItem.id.count();
    final query = selectOnly(stocktakeItem)
      ..addColumns([count])
      ..where(stocktakeItem.stocktakeId.equals(stocktakeId) &
          stocktakeItem.differenceQty.equals(0).not());
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
