/// 产品模块常量定义
library;

/// 元转分的换算常量
const int kCentsPerYuan = 100;

/// 防抖延迟时间
const Duration kDebounceDelay = Duration(milliseconds: 300);

/// 条码格式正则表达式
/// 允许字母、数字和横线
final RegExp kBarcodePattern = RegExp(r'^[a-zA-Z0-9\-]+$');

/// 默认换算率（基本单位）
const double kBaseUnitConversionRate = 1.0;

/// 价格小数位数
const int kPriceDecimalPlaces = 2;
