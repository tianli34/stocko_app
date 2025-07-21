import 'package:drift/drift.dart';

/// 入库单表
/// 存储入库单的基本信息
class InboundReceiptsTable extends Table {
  @override
  String get tableName => 'inbound_receipts';

  /// 主键 - 入库单ID
  TextColumn get id => text().named('id')();

  /// 入库单号（系统自动生成）
  TextColumn get receiptNumber => text().named('receipt_number').unique()();

  /// 入库单状态：draft(草稿), submitted(已提交), completed(已完成), cancelled(已取消)
  TextColumn get status =>
      text().named('status').withDefault(const Constant('draft'))();

  /// 来源
  TextColumn get source => text().named('source').nullable()();

  /// 备注
  TextColumn get remarks => text().named('remarks').nullable()();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  /// 提交时间（状态变为submitted时的时间）
  DateTimeColumn get submittedAt =>
      dateTime().named('submitted_at').nullable()();

  /// 完成时间（状态变为completed时的时间）
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
