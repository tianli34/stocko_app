import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_stats.freezed.dart';

/// 首页统计数据模型
@freezed
abstract class HomeStats with _$HomeStats {
  const factory HomeStats({
    /// 今日销售额（元）
    required double todaySales,
    /// 今日利润（元）
    required double todayProfit,
    /// 今日顾客数
    required int todayCustomerCount,
    /// 今日订单数
    required int todayOrderCount,
    /// 库存预警数量
    required int lowStockCount,
    /// 今日入库数量
    required int todayInboundCount,
  }) = _HomeStats;
}
