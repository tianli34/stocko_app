import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// 客户领域模型
/// 表示客户的业务实体
@freezed
abstract class Customer with _$Customer {
  const factory Customer({int? id, required String name}) = _Customer;

  const Customer._();

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
