import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/model/home_stats.dart';

/// 首页统计数据 Provider
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  
  // 获取今日的开始和结束时间
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  
  // 1. 获取今日销售数据
  final salesResult = await db.customSelect(
    '''
    SELECT 
      COALESCE(SUM(total_amount), 0) as total_sales,
      COALESCE(SUM(actual_amount), 0) as actual_sales,
      COUNT(DISTINCT customer_id) as customer_count,
      COUNT(*) as order_count
    FROM sales_transaction 
    WHERE created_at >= ? AND created_at < ?
      AND status != 'cancelled'
    ''',
    variables: [
      Variable.withInt(todayStart.millisecondsSinceEpoch ~/ 1000),
      Variable.withInt(todayEnd.millisecondsSinceEpoch ~/ 1000),
    ],
  ).getSingleOrNull();
  
  final todaySales = (salesResult?.read<double>('total_sales') ?? 0.0);
  final todayActualSales = (salesResult?.read<double>('actual_sales') ?? 0.0);
  final todayCustomerCount = salesResult?.read<int>('customer_count') ?? 0;
  final todayOrderCount = salesResult?.read<int>('order_count') ?? 0;
  
  // 2. 计算今日利润（参考商品排行榜的逻辑：实收金额 - 成本）
  // 优先级：库存均价(Sis) > 商品成本(Cents->Sis) > 单位批发价(Cents->Sis) > 0
  final costResult = await db.customSelect(
    '''
    SELECT COALESCE(SUM(
      sti.quantity * COALESCE(
        CASE WHEN s.average_unit_price_in_sis > 0 THEN s.average_unit_price_in_sis ELSE NULL END,
        p.cost * 1000,
        up.wholesale_price_in_cents * 1000,
        0
      )
    ), 0) as total_cost
    FROM sales_transaction_item sti
    JOIN sales_transaction st ON st.id = sti.sales_transaction_id
    JOIN product p ON p.id = sti.product_id
    LEFT JOIN stock s ON s.product_id = sti.product_id 
      AND s.shop_id = st.shop_id
      AND (s.batch_id = sti.batch_id OR (s.batch_id IS NULL AND sti.batch_id IS NULL))
    LEFT JOIN unit_product up ON up.product_id = sti.product_id 
      AND up.unit_id = sti.unit_id
    WHERE st.created_at >= ? AND st.created_at < ?
      AND st.status != 'cancelled'
    ''',
    variables: [
      Variable.withInt(todayStart.millisecondsSinceEpoch ~/ 1000),
      Variable.withInt(todayEnd.millisecondsSinceEpoch ~/ 1000),
    ],
  ).getSingleOrNull();
  
  final totalCostInSis = costResult?.read<double>('total_cost') ?? 0.0;
  final totalCost = totalCostInSis / 100000.0; // 丝转元
  final todayProfit = todayActualSales - totalCost;
  
  // 3. 获取库存预警数量（库存 <= 10 的商品数）
  final lowStockResult = await db.customSelect(
    '''
    SELECT COUNT(DISTINCT product_id) as low_stock_count
    FROM stock 
    WHERE quantity <= 10 AND quantity > 0
    ''',
  ).getSingleOrNull();
  
  final lowStockCount = lowStockResult?.read<int>('low_stock_count') ?? 0;
  
  // 4. 获取今日入库数量
  final inboundResult = await db.customSelect(
    '''
    SELECT COUNT(*) as inbound_count
    FROM inbound_receipt 
    WHERE created_at >= ? AND created_at < ?
    ''',
    variables: [
      Variable.withInt(todayStart.millisecondsSinceEpoch ~/ 1000),
      Variable.withInt(todayEnd.millisecondsSinceEpoch ~/ 1000),
    ],
  ).getSingleOrNull();
  
  final todayInboundCount = inboundResult?.read<int>('inbound_count') ?? 0;
  
  return HomeStats(
    todaySales: todaySales,
    todayProfit: todayProfit,
    todayCustomerCount: todayCustomerCount,
    todayOrderCount: todayOrderCount,
    lowStockCount: lowStockCount,
    todayInboundCount: todayInboundCount,
  );
});

/// 刷新首页统计数据
void refreshHomeStats(WidgetRef ref) {
  ref.invalidate(homeStatsProvider);
}
