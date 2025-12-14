import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/model/stocktake_item.dart';
import '../../domain/repository/i_stocktake_item_repository.dart';
import '../dao/stocktake_item_dao.dart';

class StocktakeItemRepository implements IStocktakeItemRepository {
  final StocktakeItemDao _dao;

  StocktakeItemRepository(this._dao);

  @override
  Future<int> addItem(StocktakeItemModel item) {
    return _dao.insertItem(_toCompanion(item));
  }

  @override
  Future<void> addItems(List<StocktakeItemModel> items) {
    return _dao.insertItems(items.map(_toCompanion).toList());
  }

  @override
  Future<bool> updateItem(StocktakeItemModel item) {
    if (item.id == null) return Future.value(false);
    return _dao.updateItem(_toCompanion(item), item.id!);
  }

  @override
  Future<bool> deleteItem(int id) async {
    final rows = await _dao.deleteItem(id);
    return rows > 0;
  }

  @override
  Future<bool> deleteItemsByStocktakeId(int stocktakeId) async {
    final rows = await _dao.deleteItemsByStocktakeId(stocktakeId);
    return rows >= 0;
  }

  @override
  Future<StocktakeItemModel?> getItemById(int id) async {
    final data = await _dao.getItemById(id);
    return data != null ? _toModel(data) : null;
  }

  @override
  Future<List<StocktakeItemModel>> getItemsByStocktakeId(
      int stocktakeId) async {
    final dataList = await _dao.getItemsByStocktakeId(stocktakeId);
    return dataList.map(_toModel).toList();
  }

  @override
  Future<StocktakeItemModel?> getItemByProductId(
      int stocktakeId, int productId, int? batchId) async {
    final data = await _dao.getItemByProductId(stocktakeId, productId, batchId);
    return data != null ? _toModel(data) : null;
  }

  @override
  Future<bool> updateActualQuantity(int id, int actualQuantity) async {
    final item = await _dao.getItemById(id);
    if (item == null) return false;
    final differenceQty = actualQuantity - item.systemQuantity;
    return _dao.updateActualQuantity(id, actualQuantity, differenceQty);
  }

  @override
  Future<bool> updateDifferenceReason(int id, String reason) {
    return _dao.updateDifferenceReason(id, reason);
  }

  @override
  Future<bool> markAsAdjusted(int id) {
    return _dao.markAsAdjusted(id);
  }

  @override
  Future<int> markAllAsAdjusted(int stocktakeId) {
    return _dao.markAllAsAdjusted(stocktakeId);
  }

  @override
  Future<List<StocktakeItemModel>> getDiffItems(int stocktakeId) async {
    final dataList = await _dao.getDiffItems(stocktakeId);
    return dataList.map(_toModel).toList();
  }

  @override
  Future<List<StocktakeItemModel>> getUnadjustedDiffItems(
      int stocktakeId) async {
    final dataList = await _dao.getUnadjustedDiffItems(stocktakeId);
    return dataList.map(_toModel).toList();
  }

  @override
  Stream<List<StocktakeItemModel>> watchItemsByStocktakeId(int stocktakeId) {
    return _dao
        .watchItemsByStocktakeId(stocktakeId)
        .map((list) => list.map(_toModel).toList());
  }

  @override
  Future<StocktakeSummary> getSummary(int stocktakeId) async {
    final items = await getItemsByStocktakeId(stocktakeId);
    
    int overageItems = 0;
    int shortageItems = 0;
    int totalOverageQty = 0;
    int totalShortageQty = 0;
    
    for (final item in items) {
      if (item.differenceQty > 0) {
        overageItems++;
        totalOverageQty += item.differenceQty;
      } else if (item.differenceQty < 0) {
        shortageItems++;
        totalShortageQty += item.differenceQty.abs();
      }
    }
    
    return StocktakeSummary(
      totalItems: items.length,
      checkedItems: items.length,
      diffItems: overageItems + shortageItems,
      overageItems: overageItems,
      shortageItems: shortageItems,
      totalOverageQty: totalOverageQty,
      totalShortageQty: totalShortageQty,
    );
  }

  StocktakeItemModel _toModel(StocktakeItemData data) {
    return StocktakeItemModel(
      id: data.id,
      stocktakeId: data.stocktakeId,
      productId: data.productId,
      batchId: data.batchId,
      systemQuantity: data.systemQuantity,
      actualQuantity: data.actualQuantity,
      differenceQty: data.differenceQty,
      differenceReason: data.differenceReason,
      isAdjusted: data.isAdjusted,
      scannedAt: data.scannedAt,
    );
  }

  StocktakeItemCompanion _toCompanion(StocktakeItemModel model) {
    return StocktakeItemCompanion(
      id: model.id != null ? Value(model.id!) : const Value.absent(),
      stocktakeId: Value(model.stocktakeId),
      productId: Value(model.productId),
      batchId:
          model.batchId != null ? Value(model.batchId!) : const Value.absent(),
      systemQuantity: Value(model.systemQuantity),
      actualQuantity: Value(model.actualQuantity),
      differenceQty: Value(model.differenceQty),
      differenceReason: model.differenceReason != null
          ? Value(model.differenceReason!)
          : const Value.absent(),
      isAdjusted: Value(model.isAdjusted),
      scannedAt: model.scannedAt != null
          ? Value(model.scannedAt!)
          : const Value.absent(),
    );
  }
}

/// Provider
final stocktakeItemDaoProvider = Provider<StocktakeItemDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StocktakeItemDao(db);
});

final stocktakeItemRepositoryProvider =
    Provider<IStocktakeItemRepository>((ref) {
  final dao = ref.watch(stocktakeItemDaoProvider);
  return StocktakeItemRepository(dao);
});
