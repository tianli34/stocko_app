import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/purchase/domain/model/supplier.dart';

void main() {
  group('Supplier', () {
    test('should be created successfully with valid data', () {
      // Act
      const supplier = Supplier(id: 1, name: 'Test Supplier');

      // Assert
      expect(supplier.id, 1);
      expect(supplier.name, 'Test Supplier');
    });

    test('fromJson should create a model from a map', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'Supplier From JSON',
      };

      // Act
      final supplier = Supplier.fromJson(json);

      // Assert
      expect(supplier.id, 2);
      expect(supplier.name, 'Supplier From JSON');
    });
  });
}