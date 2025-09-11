import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/core/database/purchase_orders_table.dart';
import 'purchase_order_item.dart';
part 'purchase_order.freezed.dart';
part 'purchase_order.g.dart';

@freezed
abstract class PurchaseOrderModel with _$PurchaseOrderModel {
  const factory PurchaseOrderModel({
    int? id,
    required int supplierId,
    required int shopId,
    @Default(PurchaseOrderStatus.preset) PurchaseOrderStatus status,
    @Default(<PurchaseOrderItemModel>[]) List<PurchaseOrderItemModel> items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PurchaseOrderModel;

  const PurchaseOrderModel._();

  PurchaseOrderCompanion toTableCompanion() {
    return PurchaseOrderCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      supplierId: Value(supplierId),
      shopId: Value(shopId),
      status: Value(status),
      // createdAt/updatedAt 由数据库默认值维护，除非外部指定
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt!),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderModelFromJson(json);

  factory PurchaseOrderModel.fromTableData(
    PurchaseOrderData data, {
    List<PurchaseOrderItemModel> items = const [],
  }) {
    return PurchaseOrderModel(
      id: data.id,
      supplierId: data.supplierId,
      shopId: data.shopId,
      status: data.status,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      items: items,
    );
  }
}
