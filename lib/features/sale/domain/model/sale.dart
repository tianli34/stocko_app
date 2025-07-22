import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

/// 销售领域模型
/// 表示销售的业务实体
@freezed
abstract class Sale with _$Sale {
  const factory Sale({
    required String id,
    required String customerId,
    required List<String> productIds,
    required double totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Sale;

  const Sale._();

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);

  /// 创建新销售
  factory Sale.create({
    required String customerId,
    required List<String> productIds,
    required double totalPrice,
  }) {
    final now = DateTime.now();
    return Sale(
      id: 'sale_${now.millisecondsSinceEpoch}',
      customerId: customerId,
      productIds: productIds,
      totalPrice: totalPrice,
      createdAt: now,
      updatedAt: now,
    );
  }
}
