import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';

void main() {
  group('剩余保质期计算测试', () {
    test('测试1: 生产日期2024-01-01，保质期365天，当前2024-10-10', () {
      // 模拟当前日期为 2024-10-10
      final productionDate = DateTime(2024, 1, 1);
      final shelfLifeDays = 365;
      final expiryDate = productionDate.add(Duration(days: shelfLifeDays));
      
      print('生产日期: ${productionDate.toString()}');
      print('保质期天数: $shelfLifeDays');
      print('过期日期: ${expiryDate.toString()}');
      
      // 假设当前日期是 2024-10-10
      final currentDate = DateTime(2024, 10, 10);
      final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
      final remainingDays = expiry.difference(today).inDays;
      
      print('当前日期: ${currentDate.toString()}');
      print('计算的剩余天数: $remainingDays');
      
      // 2024-01-01 + 365天 = 2024-12-31
      // 2024-12-31 - 2024-10-10 = 82天
      expect(remainingDays, 82);
    });

    test('测试2: 使用 fromMap 方法验证', () {
      final map = {
        'id': 1,
        'shopId': 1,
        'shopName': '测试店铺',
        'quantity': 10,
        'productionDate': '2024-01-01',
        'shelfLifeDays': 365,
      };
      
      final detail = InventoryDetail.fromMap(map);
      
      print('生产日期: ${detail.productionDate}');
      print('保质期天数: ${detail.shelfLifeDays}');
      print('计算的剩余天数: ${detail.remainingDays}');
      
      // 验证剩余天数是否合理（应该是负数或很小的正数，因为现在是2025年）
      expect(detail.remainingDays, isNotNull);
      print('剩余天数显示: ${detail.remainingDaysDisplayText}');
    });

    test('测试3: 检查 shelfLifeUnit 字段的影响', () {
      // 测试如果 shelfLifeDays 实际上是月份
      final map1 = {
        'id': 1,
        'shopId': 1,
        'shopName': '测试店铺',
        'quantity': 10,
        'productionDate': '2024-01-01',
        'shelfLifeDays': 12, // 12个月
        'shelfLifeUnit': '月',
      };
      
      final detail1 = InventoryDetail.fromMap(map1);
      print('\n测试场景: shelfLifeDays=12, unit=月');
      print('生产日期: 2024-01-01');
      print('保质期: 12个月 = 360天');
      print('过期日期: 2024-12-26');
      print('计算的剩余天数: ${detail1.remainingDays}');
      print('剩余天数显示: ${detail1.remainingDaysDisplayText}');
      
      // 2024-01-01 + 360天 = 2024-12-26
      // 从2025-10-10看，应该已经过期
      expect(detail1.remainingDays, lessThan(0));
      
      // 如果 shelfLifeDays 是年
      final map2 = {
        'id': 2,
        'shopId': 1,
        'shopName': '测试店铺',
        'quantity': 10,
        'productionDate': '2024-01-01',
        'shelfLifeDays': 2, // 2年
        'shelfLifeUnit': '年',
      };
      
      final detail2 = InventoryDetail.fromMap(map2);
      print('\n测试场景: shelfLifeDays=2, unit=年');
      print('生产日期: 2024-01-01');
      print('保质期: 2年 = 730天');
      print('过期日期: 2026-01-01');
      print('计算的剩余天数: ${detail2.remainingDays}');
      print('剩余天数显示: ${detail2.remainingDaysDisplayText}');
      
      // 2024-01-01 + 730天 = 2026-01-01
      // 从2025-10-10看，应该还有约83天
      expect(detail2.remainingDays, greaterThan(0));
      expect(detail2.remainingDays, greaterThan(80));
    });
    
    test('测试4: 保质期单位为"天"', () {
      final map = {
        'id': 3,
        'shopId': 1,
        'shopName': '测试店铺',
        'quantity': 10,
        'productionDate': '2025-09-01',
        'shelfLifeDays': 60,
        'shelfLifeUnit': '天',
      };
      
      final detail = InventoryDetail.fromMap(map);
      print('\n测试场景: shelfLifeDays=60, unit=天');
      print('生产日期: 2025-09-01');
      print('保质期: 60天');
      print('过期日期: 2025-10-31');
      print('计算的剩余天数: ${detail.remainingDays}');
      print('剩余天数显示: ${detail.remainingDaysDisplayText}');
      
      // 2025-09-01 + 60天 = 2025-10-31
      // 从2025-10-10看，应该还有21天
      expect(detail.remainingDays, greaterThan(0));
    });
  });
}
