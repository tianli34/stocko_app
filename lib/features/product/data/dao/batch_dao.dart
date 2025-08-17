import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/batches_table.dart';

part 'batch_dao.g.dart';

/// 批次数据访问对象
/// 负责处理批次表的数据库操作
@DriftAccessor(tables: [ProductBatch])
class BatchDao extends DatabaseAccessor<AppDatabase> with _$BatchDaoMixin {
  BatchDao(super.db);

  /// 创建新批次
  Future<void> createBatch({
    required int productId,
    required DateTime productionDate,
    required int totalInboundQuantity,
    required int shopId,
  }) async {
    await into(db.productBatch).insert(
      ProductBatchCompanion.insert(
        productId: productId,
        productionDate: productionDate,
        totalInboundQuantity: totalInboundQuantity,
        shopId: shopId,
      ),
    );
  }

  /// 使用 ON CONFLICT DO UPDATE 在唯一键冲突时累加数量
  /// 若 (productId, productionDate, shopId) 已存在，则 total_inbound_quantity += increment 并刷新 updated_at
  Future<void> upsertBatchIncrement({
    required int productId,
    required DateTime productionDate,
    required int shopId,
    required int increment,
  }) async {
    // 可选：将时间标准化为日期粒度（与唯一键语义一致）。
    final d = productionDate.toUtc();
    final dateOnly = DateTime.utc(d.year, d.month, d.day);

    await db.customInsert(
      'INSERT INTO product_batch (product_id, production_date, total_inbound_quantity, shop_id) '
      'VALUES (?1, ?2, ?3, ?4) '
      'ON CONFLICT(product_id, production_date, shop_id) DO UPDATE SET '
      'total_inbound_quantity = product_batch.total_inbound_quantity + excluded.total_inbound_quantity, '
      'updated_at = CURRENT_TIMESTAMP',
      variables: [
        Variable(productId),
        Variable(dateOnly),
        Variable(increment),
        Variable(shopId),
      ],
      updates: {db.productBatch},
    );
  }

  /// 通过 (productId, productionDate, shopId) 查询批次
  Future<ProductBatchData?> getBatchByBusinessKey({
    required int productId,
    required DateTime productionDate,
    required int shopId,
  }) {
    final d = productionDate.toUtc();
    final dateOnly = DateTime.utc(d.year, d.month, d.day);
    final q = select(db.productBatch)
      ..where((t) => t.productId.equals(productId) &
          t.productionDate.equals(dateOnly) &
          t.shopId.equals(shopId));
    return q.getSingleOrNull();
  }

  /// 获取所有批次
  Future<List<ProductBatchData>> getAllBatches() {
    return select(db.productBatch).get();
  }

  /// 根据店铺ID获取批次
  Future<List<ProductBatchData>> getBatchesByShop(int shopId) {
    return (select(db.productBatch)..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据批次号获取批次
  Future<ProductBatchData?> getBatchByNumber(int id) {
    return (select(
      db.productBatch,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 更新批次初始数量
  /// 用于同一批次多次入库时的数量累加
  Future<void> updateBatchQuantity(
    int id,
    int newInitialQuantity,
  ) {
    return (update(
      db.productBatch,
    )..where((t) => t.id.equals(id))).write(
      ProductBatchCompanion(totalInboundQuantity: Value(newInitialQuantity)),
    );
  }

  /// 删除批次
  Future<void> deleteBatch(int id) {
    return (delete(
      db.productBatch,
    )..where((t) => t.id.equals(id))).go();
  }

  /// 根据货品ID获取批次
  Future<List<ProductBatchData>> getBatchesByProduct(int productId) {
    return (select(
      db.productBatch,
    )..where((t) => t.productId.equals(productId))).get();
  }
}
