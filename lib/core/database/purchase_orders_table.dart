import 'package:drift/drift.dart';
import 'shops_table.dart';
import 'suppliers_table.dart';

/// 采购订单表
/// 存储采购订单的宏观信息，如供应商、店铺、采购日期等。
class PurchaseOrder extends Table {
  /// 主键 - 采购订单号
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 供应商ID
  IntColumn get supplierId => integer().references(Supplier, #id)();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 订单状态
  TextColumn get status => textEnum<PurchaseOrderStatus>()
      .withDefault(const Constant('pendingInbound'))();

  /// 采购流程类型
  TextColumn get flowType =>
      textEnum<PurchaseFlowType>().withDefault(const Constant('twoStep'))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 订单状态枚举
enum PurchaseOrderStatus { preset, draft, completed, pendingInbound, inbounded, voided, cancelled }

/// 采购流程类型
enum PurchaseFlowType {
  oneClick, // 一键入库（采购+入库同时完成）
  twoStep // 分步操作（先采购，后入库）
}
