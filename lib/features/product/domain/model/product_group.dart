import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_group.freezed.dart';
part 'product_group.g.dart';

/// 商品组模型 - 用于聚合同系列不同规格/口味的商品
@freezed
abstract class ProductGroupModel with _$ProductGroupModel {
  const factory ProductGroupModel({
    int? id,
    required String name,
    String? image,
    String? description,
    DateTime? createdAt,
  }) = _ProductGroupModel;

  factory ProductGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ProductGroupModelFromJson(json);
}
