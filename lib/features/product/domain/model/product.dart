// ignore_for_file: invalid_annotation_target
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'product.freezed.dart';
part 'product.g.dart';

// 帮助函数，用于 JSON 转换
int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

Money? _moneyFromJson(int? cents) => cents == null ? null : Money(cents);
int? _moneyToJson(Money? money) => money?.cents;

/// 价格封装类（单位为分）
class Money extends Equatable {
  final int cents;
  const Money(this.cents);

  double get yuan => cents / 100;

  String format({String symbol = '¥', String locale = 'zh_CN'}) {
    final cacheKey = '$locale|$symbol';
    final formatter = _formatterCache.putIfAbsent(
      cacheKey,
      () => NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 2),
    );
    return formatter.format(yuan);
  }

  static final _formatterCache = <String, NumberFormat>{};

  factory Money.fromJson(int cents) => Money(cents);
  int toJson() => cents;

  @override
  List<Object?> get props => [cents];
}


/// 保质期单位
@JsonEnum(alwaysCreate: true)
enum ShelfLifeUnit { days, months, years }

/// 产品状态
@JsonEnum(alwaysCreate: true)
enum ProductStatus { active, inactive }

@freezed
abstract class ProductModel with _$ProductModel {
  const factory ProductModel({
    @JsonKey(fromJson: _intFromJson) int? id,
    required String name,
    String? sku,
    String? image,
    required int baseUnitId,
    @JsonKey(fromJson: _intFromJson) int? categoryId,
    String? specification,
    String? brand,
    @JsonKey(fromJson: _moneyFromJson, toJson: _moneyToJson)
    Money? suggestedRetailPrice,
    @JsonKey(fromJson: _moneyFromJson, toJson: _moneyToJson)
    Money? retailPrice,
    @JsonKey(fromJson: _moneyFromJson, toJson: _moneyToJson)
    Money? promotionalPrice,
    int? stockWarningValue,
    int? shelfLife,
    @Default(ShelfLifeUnit.months) ShelfLifeUnit shelfLifeUnit,
    @Default(false) bool enableBatchManagement,
    @Default(ProductStatus.active) ProductStatus status,
    String? remarks,
    DateTime? lastUpdated,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  const ProductModel._();

  /// 获取有效价格（促销价 > 零售价 > 建议零售价）
  Money? get effectivePrice =>
      promotionalPrice ?? retailPrice ?? suggestedRetailPrice;

  /// 是否有促销价
  bool get hasPromotionalPrice => promotionalPrice != null;

  /// 是否需要库存预警 (优化后)
  bool isStockWarning(int currentStock) {
    final limit = stockWarningValue;
    if (limit == null || limit <= 0) {
      return false;
    }
    return currentStock <= limit;
  }

  /// 是否有效（状态为活跃）
  bool get isActive => status == ProductStatus.active;

  /// 获取格式化的价格显示
  String get formattedPrice => effectivePrice?.format() ?? '价格待定';

  /// 复制并更新最后更新时间（统一用 UTC）
  ProductModel updateTimestamp() {
    return copyWith(lastUpdated: DateTime.now().toUtc());
  }
}
