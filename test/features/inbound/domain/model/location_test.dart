import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inbound/domain/model/location.dart';

void main() {
  group('Location Model', () {
    final now = DateTime.now();
    final location = Location(
      id: '1',
      code: 'A-01',
      name: '货位A-01',
      shopId: 1,
      status: Location.statusActive,
      createdAt: now,
      updatedAt: now,
    );

    test('should be created correctly', () {
      expect(location.id, '1');
      expect(location.code, 'A-01');
      expect(location.name, '货位A-01');
      expect(location.isActive, isTrue);
    });

    test('create factory should generate a valid active location', () {
      final newLocation = Location.create(
        code: 'B-01',
        name: '货位B-01',
        shopId: 1,
      );
      expect(newLocation.code, 'B-01');
      expect(newLocation.name, '货位B-01');
      expect(newLocation.shopId, 1);
      expect(newLocation.status, Location.statusActive);
      expect(newLocation.isActive, isTrue);
      expect(newLocation.id, startsWith('location_'));
    });

    test('copyWith should update fields correctly', () {
      final updatedLocation = location.copyWith(
        name: '新的货位名称',
        status: Location.statusInactive,
      );
      expect(updatedLocation.name, '新的货位名称');
      expect(updatedLocation.status, Location.statusInactive);
      expect(updatedLocation.isInactive, isTrue);
      // Unchanged fields
      expect(updatedLocation.id, location.id);
      expect(updatedLocation.code, location.code);
    });

    group('Status properties', () {
      test('statusDisplayName should return correct Chinese name', () {
        expect(location.statusDisplayName, '活跃');
        final inactiveLocation = location.copyWith(status: Location.statusInactive);
        expect(inactiveLocation.statusDisplayName, '停用');
      });

      test('statusDisplayName should return status itself if unknown', () {
        final unknownStatusLocation = location.copyWith(status: 'unknown');
        expect(unknownStatusLocation.statusDisplayName, 'unknown');
      });

      test('isActive and isInactive should work correctly', () {
        expect(location.isActive, isTrue);
        expect(location.isInactive, isFalse);
        final inactiveLocation = location.copyWith(status: Location.statusInactive);
        expect(inactiveLocation.isActive, isFalse);
        expect(inactiveLocation.isInactive, isTrue);
      });
    });

    test('fullDisplayName should return correct format', () {
      expect(location.fullDisplayName, 'A-01 - 货位A-01');
    });

    group('Equality and-hashCode', () {
      test('should be equal if ids are the same', () {
        final location1 = Location(
          id: '1',
          code: 'A-01',
          name: '货位A-01',
          shopId: 1,
          status: Location.statusActive,
          createdAt: now,
          updatedAt: now,
        );
        final location2 = location1.copyWith(name: 'New Name');
        expect(location1 == location2, isTrue);
        expect(location1.hashCode == location2.hashCode, isTrue);
      });

      test('should not be equal if ids are different', () {
        final location1 = Location.create(code: 'C-01', name: '货位C-01', shopId: 1);
        final location2 = Location.create(code: 'C-01', name: '货位C-01', shopId: 1);
        expect(location1 == location2, isFalse);
      });
    });
  });
}