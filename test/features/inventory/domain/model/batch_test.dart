import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/batch.dart';

void main() {
  group('BatchModel Test', () {
    final now = DateTime.now().toUtc();
    final productionDate = DateTime.utc(2023, 10, 26, 10); // With time part
    final normalizedDate = DateTime.utc(2023, 10, 26); // Date part only

    final batch = BatchModel(
      id: 1,
      productId: 101,
      productionDate: normalizedDate,
      totalInboundQuantity: 100,
      shopId: 1,
      createdAt: now,
      updatedAt: now,
    );

    test('create factory should normalize productionDate to UTC date', () {
      final newBatch = BatchModel.create(
        productId: 102,
        productionDate: productionDate,
        totalInboundQuantity: 50,
        shopId: 2,
      );

      expect(newBatch.productionDate, normalizedDate);
      expect(newBatch.productId, 102);
      expect(newBatch.totalInboundQuantity, 50);
      expect(newBatch.shopId, 2);
      expect(newBatch.id, isNull);
    });

    test('copyWith should work correctly', () {
      final updatedBatch = batch.copyWith(totalInboundQuantity: 120);
      expect(updatedBatch.totalInboundQuantity, 120);
      expect(updatedBatch.id, batch.id);
    });

    test('Equality should be based on id if both are not null', () {
      final sameBatch = batch.copyWith(productId: 999);
      final differentBatch = batch.copyWith(id: 2);

      expect(batch == sameBatch, isTrue);
      expect(batch.hashCode, sameBatch.hashCode);
      expect(batch == differentBatch, isFalse);
    });

    test('Equality should be based on business key if id is null', () {
      final batch1 = BatchModel.create(
        productId: 200,
        productionDate: productionDate,
        totalInboundQuantity: 10,
        shopId: 3,
      );
      final batch2 = BatchModel.create(
        productId: 200,
        productionDate: productionDate.add(const Duration(hours: 5)),
        totalInboundQuantity: 20,
        shopId: 3,
      );
      final batch3 = batch1.copyWith(shopId: 4);

      expect(batch1 == batch2, isTrue);
      expect(batch1.hashCode, batch2.hashCode);
      expect(batch1 == batch3, isFalse);
    });

    test('JSON serialization and deserialization should work', () {
      final json = batch.toJson();
      final fromJsonBatch = BatchModel.fromJson(json);

      expect(fromJsonBatch, batch);
    });
    
    test('toString should return a meaningful string', () {
      expect(batch.toString(), contains('id: 1'));
      expect(batch.toString(), contains('productId: 101'));
      expect(batch.toString(), contains('totalInboundQuantity: 100'));
    });
  });
}