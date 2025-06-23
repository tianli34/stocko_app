import 'package:freezed_annotation/freezed_annotation.dart';

part 'barcode.freezed.dart';
part 'barcode.g.dart';

@freezed
abstract class Barcode with _$Barcode {
  const factory Barcode({
    required String id, // 主键
    required String productUnitId, // 外键，指向 ProductUnit
    required String barcode, // 条码值
    DateTime? createdAt, // 创建时间
    DateTime? updatedAt, // 最后更新时间
  }) = _Barcode;

  const Barcode._();

  factory Barcode.fromJson(Map<String, dynamic> json) =>
      _$BarcodeFromJson(json);

  /// 检查条码是否有效（非空且非纯空格）
  bool get isValid => barcode.trim().isNotEmpty;

  /// 获取格式化的创建时间
  String get formattedCreatedAt {
    if (createdAt == null) return '未知';
    return '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.day.toString().padLeft(2, '0')}';
  }

  /// 获取格式化的更新时间
  String get formattedUpdatedAt {
    if (updatedAt == null) return '未知';
    return '${updatedAt!.year}-${updatedAt!.month.toString().padLeft(2, '0')}-${updatedAt!.day.toString().padLeft(2, '0')}';
  }
}
