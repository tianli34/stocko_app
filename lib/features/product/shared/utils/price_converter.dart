/// 价格转换工具
/// 
/// 提供分/元之间的转换功能
library;

import '../constants/product_constants.dart';

/// 分转元
/// 
/// [cents] 以分为单位的价格
/// 返回以元为单位的价格，如果输入为 null 则返回 null
double? centsToYuan(int? cents) {
  if (cents == null) return null;
  return cents / kCentsPerYuan;
}

/// 元转分
/// 
/// [yuanStr] 以元为单位的价格字符串
/// 返回以分为单位的价格，如果输入无效则返回 null
int? yuanToCents(String? yuanStr) {
  if (yuanStr == null || yuanStr.trim().isEmpty) return null;
  final yuan = double.tryParse(yuanStr.trim());
  if (yuan == null) return null;
  return (yuan * kCentsPerYuan).round();
}

/// 格式化价格显示
/// 
/// [price] 价格数值
/// 返回格式化后的字符串，整数不显示小数位
String formatPrice(double price) {
  if (price == price.truncateToDouble()) {
    return price.toInt().toString();
  }
  return price.toStringAsFixed(kPriceDecimalPlaces);
}

/// 解析分字符串为元
/// 
/// [centsStr] 以分为单位的价格字符串
/// 返回以元为单位的价格
double? parseCentsStringToYuan(String centsStr) {
  if (centsStr.isEmpty) return null;
  final cents = double.tryParse(centsStr);
  if (cents == null) return null;
  return cents / kCentsPerYuan;
}
