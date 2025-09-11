import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

void main() {
  group('Money', () {
    test('正确转换分到元', () {
      final money = Money(1500);
      expect(money.yuan, equals(15.0));
    });

    test('格式化显示正确', () {
      final money = Money(1500);
      expect(money.format(), equals('¥15.00'));
    });

    test('自定义符号和区域设置', () {
      final money = Money(2500);
      expect(money.format(symbol: '\$', locale: 'en_US'), equals('\$25.00'));
    });

    test('JSON序列化和反序列化', () {
      final money = Money(1000);
      final json = money.toJson();
      final restored = Money.fromJson(json);
      
      expect(restored.cents, equals(1000));
      expect(restored.yuan, equals(10.0));
    });
  });

  group('ProductModel', () {
    test('获取有效价格 - 促销价优先', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        suggestedRetailPrice: Money(1000),
        retailPrice: Money(1200),
        promotionalPrice: Money(800),
      );

      expect(product.effectivePrice, equals(Money(800)));
      expect(product.hasPromotionalPrice, isTrue);
    });

    test('获取有效价格 - 零售价次之', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        suggestedRetailPrice: Money(1000),
        retailPrice: Money(1200),
      );

      expect(product.effectivePrice, equals(Money(1200)));
      expect(product.hasPromotionalPrice, isFalse);
    });

    test('获取有效价格 - 建议零售价最后', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        suggestedRetailPrice: Money(1000),
      );

      expect(product.effectivePrice, equals(Money(1000)));
    });

    test('库存预警判断', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        stockWarningValue: 10,
      );

      expect(product.isStockWarning(5), isTrue);
      expect(product.isStockWarning(10), isTrue);
      expect(product.isStockWarning(15), isFalse);
    });

    test('无预警值时不触发预警', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
      );

      expect(product.isStockWarning(0), isFalse);
    });

    test('产品状态判断', () {
      final activeProduct = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        status: ProductStatus.active,
      );

      final inactiveProduct = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        status: ProductStatus.inactive,
      );

      expect(activeProduct.isActive, isTrue);
      expect(inactiveProduct.isActive, isFalse);
    });

    test('格式化价格显示', () {
      final productWithPrice = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
        suggestedRetailPrice: Money(1500),
      );

      final productWithoutPrice = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
      );

      expect(productWithPrice.formattedPrice, equals('¥15.00'));
      expect(productWithoutPrice.formattedPrice, equals('价格待定'));
    });

    test('更新时间戳', () {
      final product = ProductModel(
        name: '测试产品',
        baseUnitId: 1,
      );

      final updatedProduct = product.updateTimestamp();
      
      expect(updatedProduct.lastUpdated, isNotNull);
      expect(updatedProduct.lastUpdated!.isUtc, isTrue);
    });

    test('JSON序列化和反序列化', () {
      final product = ProductModel(
        id: 1,
        name: '测试产品',
        baseUnitId: 1,
        categoryId: 2,
        brand: '测试品牌',
        suggestedRetailPrice: Money(1000),
        stockWarningValue: 5,
        status: ProductStatus.active,
      );

      final json = product.toJson();
      final restored = ProductModel.fromJson(json);

      expect(restored.id, equals(1));
      expect(restored.name, equals('测试产品'));
      expect(restored.baseUnitId, equals(1));
      expect(restored.categoryId, equals(2));
      expect(restored.brand, equals('测试品牌'));
      expect(restored.suggestedRetailPrice?.cents, equals(1000));
      expect(restored.stockWarningValue, equals(5));
      expect(restored.status, equals(ProductStatus.active));
    });
  });
}