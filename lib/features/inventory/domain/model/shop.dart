import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

/// 店铺领域模型
/// 表示店铺的业务实体
@freezed
abstract class Shop with _$Shop {
  const factory Shop({
    int? id,
    required String name,
    required String manager,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Shop;

  const Shop._();

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

  /// 创建新店铺
  factory Shop.create({required String name, required String manager}) {
    final now = DateTime.now();
    return Shop(
      id: null,
      name: name,
      manager: manager,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制并更新店铺信息
  Shop updateInfo({String? name, String? manager}) {
    return copyWith(
      name: name ?? this.name,
      manager: manager ?? this.manager,
      updatedAt: DateTime.now(),
    );
  }
}
