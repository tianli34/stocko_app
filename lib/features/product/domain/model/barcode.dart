import 'package:freezed_annotation/freezed_annotation.dart';

part 'barcode.freezed.dart';
part 'barcode.g.dart';

@freezed
abstract class BarcodeModel with _$BarcodeModel {
  const factory BarcodeModel({
    int? id, // 主键
    required int productUnitId, // 外键，指向 ProductUnit
    required String barcodeValue, // 条码值
  }) = _BarcodeModel;

  const BarcodeModel._();

  factory BarcodeModel.fromJson(Map<String, dynamic> json) =>
      _$BarcodeModelFromJson(json);

  /// 检查条码是否有效（非空且非纯空格）
  bool get isValid => barcodeValue.trim().isNotEmpty;
}
