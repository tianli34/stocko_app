import 'package:flutter/foundation.dart';

/// 辅单位数据模型
/// 用于表单数据的跨页面持久化
@immutable
class AuxiliaryUnitData {
  /// 唯一标识符
  final int id;

  /// 单位ID
  final int? unitId;

  /// 单位名称
  final String unitName;

  /// 换算率
  final int conversionRate;

  /// 条码
  final String barcode;

  /// 建议零售价
  final String retailPriceInCents;

  /// 批发价
  final String wholesalePriceInCents;

  const AuxiliaryUnitData({
    required this.id,
    this.unitId,
    this.unitName = '',
    this.conversionRate = 0,
    this.barcode = '',
    this.retailPriceInCents = '',
    this.wholesalePriceInCents = '',
  });

  /// 创建空的辅单位数据
  const AuxiliaryUnitData.empty(this.id)
    : unitId = null,
      unitName = '',
      conversionRate = 0,
      barcode = '',
      retailPriceInCents = '',
      wholesalePriceInCents = '';

  /// 复制并更新指定字段
  AuxiliaryUnitData copyWith({
    int? id,
    int? unitId,
    String? unitName,
    int? conversionRate,
    String? barcode,
    String? retailPriceInCents,
    String? wholesalePriceInCents,
  }) {
    return AuxiliaryUnitData(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      conversionRate: conversionRate ?? this.conversionRate,
      barcode: barcode ?? this.barcode,
      retailPriceInCents: retailPriceInCents ?? this.retailPriceInCents,
      wholesalePriceInCents: wholesalePriceInCents ?? this.wholesalePriceInCents,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitId': unitId,
      'unitName': unitName,
      'conversionRate': conversionRate,
      'barcode': barcode,
      'retailPriceInCents': retailPriceInCents,
      'wholesalePriceInCents': wholesalePriceInCents,
    };
  }

  /// 从JSON创建实例
  factory AuxiliaryUnitData.fromJson(Map<String, dynamic> json) {
    return AuxiliaryUnitData(
      id: json['id'] as int,
      unitId: json['unitId'] as int?,
      unitName: json['unitName'] as String? ?? '',
      conversionRate: (json['conversionRate'] as int?) ?? 0,
      barcode: json['barcode'] as String? ?? '',
      retailPriceInCents: json['retailPriceInCents'] as String? ?? '',
      wholesalePriceInCents: json['wholesalePriceInCents'] as String? ?? '',
    );
  }

  /// 检查是否为有效的辅单位数据
  bool get isValid {
    return unitName.trim().isNotEmpty &&
        conversionRate > 0 &&
        conversionRate != 1.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuxiliaryUnitData &&
        other.id == id &&
        other.unitId == unitId &&
        other.unitName == unitName &&
        other.conversionRate == conversionRate &&
        other.barcode == barcode &&
        other.retailPriceInCents == retailPriceInCents &&
        other.wholesalePriceInCents == wholesalePriceInCents;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      unitId,
      unitName,
      conversionRate,
      barcode,
      retailPriceInCents,
      wholesalePriceInCents,
    );
  }

  @override
  String toString() {
    return 'AuxiliaryUnitData(id: $id, unitId: $unitId, unitName: $unitName, '
        'conversionRate: $conversionRate, barcode: $barcode, retailPriceInCents: $retailPriceInCents, '
        'wholesalePriceInCents: $wholesalePriceInCents)';
  }
}
