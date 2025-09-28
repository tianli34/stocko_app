import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

/// 库存领域模型
/// 表示产品在店铺的库存信息
@freezed
abstract class StockModel with _$StockModel {
  const factory StockModel({
    int? id,
    required int productId,
    required int quantity,
    required int shopId,
    int? batchId,
    @Default(0) int averageUnitPriceInCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StockModel;

  const StockModel._();
  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);

  /// 创建新库存记录
  factory StockModel.create({
    required int productId,
    required int quantity,
    required int shopId,
    int? batchId,
  }) {
    final now = DateTime.now();
    return StockModel(
      id: null,
      productId: productId,
      quantity: quantity,
      shopId: shopId,
      batchId: batchId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 更新库存数量
  StockModel updateQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity, updatedAt: DateTime.now());
  }
}
