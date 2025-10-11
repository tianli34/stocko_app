import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';

void main() {
  print('=== 最终验证 ===\n');
  
  print('【场景1】生产日期 2025-08-23，保质期 9天（数据库存储）');
  final map1 = {
    'id': 1,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2025-08-23',
    'shelfLifeDays': 9, // 数据库中存储的是9天
    'shelfLifeUnit': '月', // 这只是显示标签
  };
  
  final detail1 = InventoryDetail.fromMap(map1);
  print('生产日期: 2025-08-23');
  print('保质期(数据库): 9天');
  print('过期日期: 2025-09-01');
  print('今天: ${DateTime.now().toString().substring(0, 10)}');
  print('计算的剩余天数: ${detail1.remainingDays}');
  print('显示: ${detail1.remainingDaysDisplayText}');
  print('');
  
  print('【场景2】生产日期 2025-08-23，保质期 270天（9个月转换后）');
  final map2 = {
    'id': 2,
    'shopId': 1,
    'shopName': '测试店铺',
    'quantity': 10,
    'productionDate': '2025-08-23',
    'shelfLifeDays': 270, // 数据库中存储的是270天（9个月 × 30天）
    'shelfLifeUnit': '月',
  };
  
  final detail2 = InventoryDetail.fromMap(map2);
  print('生产日期: 2025-08-23');
  print('保质期(数据库): 270天');
  print('过期日期: 2026-05-20');
  print('今天: ${DateTime.now().toString().substring(0, 10)}');
  print('计算的剩余天数: ${detail2.remainingDays}');
  print('显示: ${detail2.remainingDaysDisplayText}');
  print('');
  
  print('【结论】');
  print('数据库中的 shelfLifeDays 字段存储的是天数');
  print('shelfLifeUnit 只是一个显示标签，用于告诉用户这个天数是从什么单位转换来的');
  print('代码不应该再次进行单位转换');
}
