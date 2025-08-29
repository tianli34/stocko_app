import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/shop.dart';

void main() {
  group('Shop Model Test', () {
    final now = DateTime.now();
    final shop = Shop(
      id: 1,
      name: '总店',
      manager: '张三',
      createdAt: now,
      updatedAt: now,
    );

    test('Shop.create factory should create a new shop with default values', () {
      final newShop = Shop.create(name: '分店', manager: '李四');

      expect(newShop.id, isNull);
      expect(newShop.name, '分店');
      expect(newShop.manager, '李四');
      expect(newShop.createdAt, isA<DateTime>());
      expect(newShop.updatedAt, isA<DateTime>());
    });

    test('updateInfo should return a new instance with updated values', () {
      final updatedShop = shop.updateInfo(name: '总店-更新', manager: '王五');

      expect(updatedShop.id, shop.id);
      expect(updatedShop.name, '总店-更新');
      expect(updatedShop.manager, '王五');
      expect(updatedShop.updatedAt, isNot(shop.updatedAt));
    });

    test('updateInfo should only update provided values', () {
      final updatedShop = shop.updateInfo(name: '总店-仅更新名称');

      expect(updatedShop.name, '总店-仅更新名称');
      expect(updatedShop.manager, shop.manager);
    });

    test('fromJson and toJson should work correctly', () {
      final json = shop.toJson();
      final fromJsonShop = Shop.fromJson(json);

      // DateTime precision might be lost in JSON, so a direct object comparison might fail.
      // We compare properties instead.
      expect(fromJsonShop.id, shop.id);
      expect(fromJsonShop.name, shop.name);
      expect(fromJsonShop.manager, shop.manager);
      // Comparing string representations is a pragmatic way to handle DateTime precision.
      expect(fromJsonShop.createdAt?.toIso8601String(), shop.createdAt?.toIso8601String());
      expect(fromJsonShop.updatedAt?.toIso8601String(), shop.updatedAt?.toIso8601String());
    });
  });
}