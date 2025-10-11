import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';

void main() {
  print('=== 验证实际问题 ===\n');
  
  final map = {
    'id': 1,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2025-08-23',
    'shelfLifeDays': 9,
    'shelfLifeUnit': '月',
  };
  
  final detail = InventoryDetail.fromMap(map);
  
  print('生产日期: 2025-08-23');
  print('保质期: 9个月');
  print('');
  
  print('【当前计算】');
  print('步骤1: 9个月 × 30天 = 270天');
  print('步骤2: 过期日期 = 2025-08-23 + 270天 = 2026-05-20');
  print('步骤3: 今天 = ${DateTime.now().toString().substring(0, 10)}');
  print('步骤4: 剩余天数 = ${detail.remainingDays}');
  print('步骤5: 显示 = ${detail.remainingDaysDisplayText}');
  print('');
  
  print('【正确计算应该是】');
  final productionDate = DateTime(2025, 8, 23);
  print('生产日期: $productionDate');
  
  // 正确的月份计算
  final expiryDateCorrect = DateTime(
    productionDate.year,
    productionDate.month + 9,
    productionDate.day,
  );
  print('过期日期: $expiryDateCorrect (2025-08-23 + 9个月)');
  
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final expiryMidnight = DateTime(
    expiryDateCorrect.year,
    expiryDateCorrect.month,
    expiryDateCorrect.day,
  );
  final correctRemaining = expiryMidnight.difference(todayMidnight).inDays;
  
  print('今天: ${todayMidnight.toString().substring(0, 10)}');
  print('正确的剩余天数: $correctRemaining');
  
  if (correctRemaining < 0) {
    print('正确的显示: 已过期${-correctRemaining}天');
  } else if (correctRemaining == 0) {
    print('正确的显示: 今天过期');
  } else {
    print('正确的显示: 剩余$correctRemaining天');
  }
  
  print('');
  print('【问题分析】');
  print('问题: 9个月被错误地计算为 9 × 30 = 270天');
  print('实际: 2025-08-23 到 2026-05-23 是9个月，但天数不是固定的270天');
  print('解决: 应该使用 DateTime 的月份加法，而不是简单的天数乘法');
}
