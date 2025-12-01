import 'package:drift/drift.dart';
import 'package:decimal/decimal.dart';

/// 丝价格转换器
/// 将数据库中的 int（丝为单位，1元 = 100,000丝）自动映射为 Dart 的 Decimal 类型
/// 
/// 存储精度：采用"丝"为原子单位
/// - 1元 = 100,000丝
/// - 数据库存储值放大 100,000 倍
/// 
/// 禁止使用 double 进行中间运算，防止 IEEE 754 精度丢失
class SisPriceConverter extends TypeConverter<Decimal, int> {
  /// 1元 = 100,000丝
  static final Decimal sisPerYuan = Decimal.fromInt(100000);
  
  const SisPriceConverter();

  @override
  Decimal fromSql(int fromDb) {
    // 从数据库读取丝值，转换为元（Decimal）
    // 使用 toDecimal() 将 Rational 转换为 Decimal
    return (Decimal.fromInt(fromDb) / sisPerYuan).toDecimal();
  }

  @override
  int toSql(Decimal value) {
    // 将元（Decimal）转换为丝值存入数据库
    return (value * sisPerYuan).toBigInt().toInt();
  }
}

/// 扩展方法：方便在业务层使用
extension DecimalPriceExtension on Decimal {
  /// 转换为丝（int）
  int toSis() {
    return (this * SisPriceConverter.sisPerYuan).toBigInt().toInt();
  }
  
  /// 格式化为人民币字符串（保留2位小数）
  String toYuanString({int decimalPlaces = 2}) {
    return toStringAsFixed(decimalPlaces);
  }
}

extension IntSisExtension on int {
  /// 从丝转换为元（Decimal）
  Decimal toYuanDecimal() {
    return (Decimal.fromInt(this) / SisPriceConverter.sisPerYuan).toDecimal();
  }
}
