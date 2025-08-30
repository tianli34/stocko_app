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
    final now = DateTime.now();

    await db.customInsert(
      'INSERT INTO product_batch (product_id, production_date, total_inbound_quantity, shop_id, created_at, updated_at) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6) '
      'ON CONFLICT(product_id, production_date, shop_id) DO UPDATE SET '
      'total_inbound_quantity = product_batch.total_inbound_quantity + excluded.total_inbound_quantity, '
      // 关键修复：避免使用 CURRENT_TIMESTAMP（TEXT），绑定 DateTime，匹配 Drift 的整数存储。
      'updated_at = ?6',
      variables: [
        Variable(productId),
        Variable(dateOnly),
        Variable(increment),
        Variable(shopId),
        Variable(now), // created_at
        Variable(now), // updated_at
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

  /// 仅返回批次 id，避免映射 DateTime 列（兼容旧数据 TEXT 时间存储）
  Future<int?> getBatchIdByBusinessKey({
    required int productId,
    required DateTime productionDate,
    required int shopId,
  }) async {
    final d = productionDate.toUtc();
    final dateOnly = DateTime.utc(d.year, d.month, d.day);
    final query = selectOnly(db.productBatch)
      ..addColumns([db.productBatch.id])
      ..where(db.productBatch.productId.equals(productId) &
          db.productBatch.productionDate.equals(dateOnly) &
          db.productBatch.shopId.equals(shopId));
    final row = await query.getSingleOrNull();
    return row?.read(db.productBatch.id);
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
  Future<ProductBatchData?> getBatchByNumber(int id) async {
    try {
      return await (select(
        db.productBatch,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
    } catch (e) {
      print('获取批次数据失败 (ID: $id): $e');
      return null;
    }
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
/// 根据货品ID和店铺ID获取批次
  Future<List<ProductBatchData>> getBatchesByProductAndShop(int productId, int shopId) {
    return (select(db.productBatch)
          ..where((t) => t.productId.equals(productId) & t.shopId.equals(shopId)))
        .get();
  }
}
