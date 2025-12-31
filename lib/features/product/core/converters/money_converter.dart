// lib/features/product/core/converters/money_converter.dart

import '../../domain/model/product.dart';

/// 金额转换工具
/// 
/// 处理元与分之间的转换
class MoneyConverter {
  /// 元转换为 Money 对象
  /// 
  /// [yuan] 金额（元），可为 null
  /// 返回 Money 对象，如果输入为 null 则返回 null
  static Money? yuanToMoney(double? yuan) {
    if (yuan == null) return null;
    return Money((yuan * 100).round());
  }

  /// Money 对象转换为元
  /// 
  /// [money] Money 对象，可为 null
  /// 返回金额（元），如果输入为 null 则返回 null
  static double? moneyToYuan(Money? money) {
    if (money == null) return null;
    return money.cents / 100.0;
  }

  /// 分转换为元
  /// 
  /// [cents] 金额（分），可为 null
  /// 返回金额（元），如果输入为 null 则返回 null
  static double? centsToYuan(int? cents) {
    if (cents == null) return null;
    return cents / 100.0;
  }

  /// 元转换为分
  /// 
  /// [yuan] 金额（元），可为 null
  /// 返回金额（分），如果输入为 null 则返回 null
  static int? yuanToCents(double? yuan) {
    if (yuan == null) return null;
    return (yuan * 100).round();
  }

  /// 字符串（元）转换为分
  /// 
  /// [yuanStr] 金额字符串（元），可为空字符串
  /// 返回金额（分），如果解析失败则返回 null
  static int? parseYuanStringToCents(String? yuanStr) {
    if (yuanStr == null || yuanStr.trim().isEmpty) return null;
    final yuan = double.tryParse(yuanStr.trim());
    if (yuan == null) return null;
    return (yuan * 100).round();
  }

  /// 分转换为格式化的元字符串
  /// 
  /// [cents] 金额（分），可为 null
  /// 返回格式化的金额字符串，如 "12.50"
  static String centsToYuanString(int? cents) {
    if (cents == null) return '';
    return (cents / 100.0).toStringAsFixed(2);
  }
}
