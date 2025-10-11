import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';

void main() {
  print('=== 剩余保质期计算调试 ===\n');
  
  // 测试案例1: 实际数据示例
  print('【测试1】假设今天是 2025-10-10');
  print('生产日期: 2024-01-01');
  print('保质期: 12 个月\n');
  
  final map1 = {
    'id': 1,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2024-01-01',
    'shelfLifeDays': 12,
    'shelfLifeUnit': '月',
  };
  
  final detail1 = InventoryDetail.fromMap(map1);
  
  print('步骤1: 解析生产日期 = ${detail1.productionDate}');
  print('步骤2: shelfLifeDays = ${detail1.shelfLifeDays}');
  print('步骤3: shelfLifeUnit = ${detail1.shelfLifeUnit}');
  print('步骤4: 转换为天数 = 12 * 30 = 360 天');
  print('步骤5: 过期日期 = 2024-01-01 + 360天 = 2024-12-26');
  print('步骤6: 今天 = ${DateTime.now().toString().substring(0, 10)}');
  print('步骤7: 计算剩余天数 = ${detail1.remainingDays}');
  print('步骤8: 显示文本 = ${detail1.remainingDaysDisplayText}\n');
  
  // 测试案例2
  print('【测试2】');
  print('生产日期: 2023-01-01');
  print('保质期: 2 年\n');
  
  final map2 = {
    'id': 2,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2023-01-01',
    'shelfLifeDays': 2,
    'shelfLifeUnit': '年',
  };
  
  final detail2 = InventoryDetail.fromMap(map2);
  
  print('步骤1: 解析生产日期 = ${detail2.productionDate}');
  print('步骤2: shelfLifeDays = ${detail2.shelfLifeDays}');
  print('步骤3: shelfLifeUnit = ${detail2.shelfLifeUnit}');
  print('步骤4: 转换为天数 = 2 * 365 = 730 天');
  print('步骤5: 过期日期 = 2023-01-01 + 730天 = 2024-12-31');
  print('步骤6: 今天 = ${DateTime.now().toString().substring(0, 10)}');
  print('步骤7: 计算剩余天数 = ${detail2.remainingDays}');
  print('步骤8: 显示文本 = ${detail2.remainingDaysDisplayText}\n');
  
  // 测试案例3: 未来的日期
  print('【测试3】');
  print('生产日期: 2025-09-01');
  print('保质期: 90 天\n');
  
  final map3 = {
    'id': 3,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2025-09-01',
    'shelfLifeDays': 90,
    'shelfLifeUnit': '天',
  };
  
  final detail3 = InventoryDetail.fromMap(map3);
  
  print('步骤1: 解析生产日期 = ${detail3.productionDate}');
  print('步骤2: shelfLifeDays = ${detail3.shelfLifeDays}');
  print('步骤3: shelfLifeUnit = ${detail3.shelfLifeUnit}');
  print('步骤4: 转换为天数 = 90 天');
  print('步骤5: 过期日期 = 2025-09-01 + 90天 = 2025-11-30');
  print('步骤6: 今天 = ${DateTime.now().toString().substring(0, 10)}');
  print('步骤7: 计算剩余天数 = ${detail3.remainingDays}');
  print('步骤8: 显示文本 = ${detail3.remainingDaysDisplayText}\n');
  
  // 手动验证计算
  print('=== 手动验证计算逻辑 ===\n');
  final productionDate = DateTime.parse('2024-01-01');
  final shelfLifeDays = 12 * 30; // 12个月
  final expiryDate = productionDate.add(Duration(days: shelfLifeDays));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  final remaining = expiry.difference(today).inDays;
  
  print('生产日期: $productionDate');
  print('保质期天数: $shelfLifeDays');
  print('过期日期: $expiryDate');
  print('今天(归零): $today');
  print('过期日期(归零): $expiry');
  print('剩余天数: $remaining');
  
  print('\n请告诉我：');
  print('1. 你看到的实际剩余天数是多少？');
  print('2. 你期望的剩余天数应该是多少？');
  print('3. 实际的生产日期、保质期和单位是什么？');
}
