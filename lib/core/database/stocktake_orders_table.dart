import 'package:drift/drift.dart';
import 'shops_table.dart';
import 'categories_table.dart';

/// 盘点单表
class StocktakeOrder extends Table {
  /// 主键
  IntColumn get id => integer().autoIncrement()();

  /// 盘点单号 (PD + 时间戳)
  TextColumn get orderNumber => text().unique()();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 盘点类型: full(全盘) / partial(部分盘点)
  TextColumn get type => text().check(
        const CustomExpression<bool>("type IN ('full', 'partial')"),
      )();

  /// 状态: draft(草稿) / in_progress(进行中) / completed(已完成) / audited(已审核)
  TextColumn get status => text()
      .check(
        const CustomExpression<bool>(
          "status IN ('draft', 'in_progress', 'completed', 'audited')",
        ),
      )
      .withDefault(const Constant('draft'))();

  /// 分类ID (部分盘点时使用)
  IntColumn get categoryId =>
      integer().references(Category, #id).nullable()();

  /// 备注
  TextColumn get remarks => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 完成时间
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// 审核时间
  DateTimeColumn get auditedAt => dateTime().nullable()();
}
