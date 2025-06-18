import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/batches_table.dart';

part 'batch_dao.g.dart';

/// 批次数据访问对象
/// 负责处理批次表的数据库操作
@DriftAccessor(tables: [BatchesTable])
class BatchDao extends DatabaseAccessor<AppDatabase> with _$BatchDaoMixin {
  BatchDao(super.db);

  /// 根据货品ID和生产日期自动生成批次号
  /// 格式：货品ID前3位 + YYYYMMDD (例如：ABC20250523)
  String generateBatchNumber(String productId, DateTime productionDate) {
    final productPrefix = productId.length >= 3
        ? productId.substring(0, 3).toUpperCase()
        : productId.padRight(3, '0').toUpperCase();

    final dateString = productionDate
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');

    return '$productPrefix$dateString';
  }

  /// 创建新批次
  Future<void> createBatch({
    required String productId,
    required DateTime productionDate,
    required double initialQuantity,
    required String shopId,
  }) async {
    final batchNumber = generateBatchNumber(productId, productionDate);
    await into(batchesTable).insert(
      BatchesTableCompanion.insert(
        batchNumber: batchNumber,
        productId: productId,
        productionDate: productionDate,
        initialQuantity: initialQuantity,
        shopId: shopId,
      ),
    );
  }

  /// 获取所有批次
  Future<List<BatchesTableData>> getAllBatches() {
    return select(batchesTable).get();
  }

  /// 根据店铺ID获取批次
  Future<List<BatchesTableData>> getBatchesByShop(String shopId) {
    return (select(batchesTable)..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据批次号获取批次
  Future<BatchesTableData?> getBatchByNumber(String batchNumber) {
    return (select(
      batchesTable,
    )..where((t) => t.batchNumber.equals(batchNumber))).getSingleOrNull();
  }

  /// 更新批次初始数量
  /// 用于同一批次多次入库时的数量累加
  Future<void> updateBatchQuantity(
    String batchNumber,
    double newInitialQuantity,
  ) {
    return (update(
      batchesTable,
    )..where((t) => t.batchNumber.equals(batchNumber))).write(
      BatchesTableCompanion(initialQuantity: Value(newInitialQuantity)),
    );
  }

  /// 删除批次
  Future<void> deleteBatch(String batchNumber) {
    return (delete(
      batchesTable,
    )..where((t) => t.batchNumber.equals(batchNumber))).go();
  }

  /// 根据货品ID获取批次
  Future<List<BatchesTableData>> getBatchesByProduct(String productId) {
    return (select(
      batchesTable,
    )..where((t) => t.productId.equals(productId))).get();
  }
}
