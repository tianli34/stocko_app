import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/purchase/application/provider/supplier_providers.dart';
import 'package:stocko_app/features/purchase/domain/model/supplier.dart';
import 'package:stocko_app/features/purchase/domain/repository/i_supplier_repository.dart';

// Mock ISupplierRepository
class MockSupplierRepository extends Mock implements ISupplierRepository {}

void main() {
  late SupplierController controller;
  late MockSupplierRepository mockRepository;

  setUpAll(() {
    // 为 mocktail 注册 Supplier 的回退值，供 any<Supplier>() 使用
    registerFallbackValue(const Supplier(id: 0, name: 'fallback'));
  });

  setUp(() {
    mockRepository = MockSupplierRepository();
    controller = SupplierController(mockRepository);
  });

  group('SupplierController', () {
    const testSupplier = Supplier(id: 1, name: 'Test Supplier');

    test('initial state is correct', () {
      expect(controller.debugState.status, SupplierOperationStatus.initial);
    });

    group('addSupplier', () {
      test('should succeed when supplier name is unique', () async {
        // Arrange
        when(() => mockRepository.isSupplierNameExists(any())).thenAnswer((_) async => false);
        when(() => mockRepository.addSupplier(any())).thenAnswer((_) async => 1);

        // Act
        await controller.addSupplier(testSupplier);

        // Assert
        expect(controller.debugState.status, SupplierOperationStatus.success);
        expect(controller.debugState.lastOperatedSupplier, testSupplier);
        verify(() => mockRepository.isSupplierNameExists(testSupplier.name)).called(1);
        verify(() => mockRepository.addSupplier(testSupplier)).called(1);
      });

      test('should fail and set error state when supplier name already exists', () async {
        // Arrange
        when(() => mockRepository.isSupplierNameExists(any())).thenAnswer((_) async => true);

        // Act & Assert
        await expectLater(
          controller.addSupplier(testSupplier),
          throwsA(isA<Exception>()),
        );
        expect(controller.debugState.status, SupplierOperationStatus.error);
        expect(controller.debugState.errorMessage, isNotNull);
      });
    });

    group('updateSupplier', () {
      test('should succeed when new name is unique', () async {
        // Arrange
        when(() => mockRepository.isSupplierNameExists(any(), any())).thenAnswer((_) async => false);
        when(() => mockRepository.updateSupplier(any())).thenAnswer((_) async => true);

        // Act
        await controller.updateSupplier(testSupplier);

        // Assert
        expect(controller.debugState.status, SupplierOperationStatus.success);
        verify(() => mockRepository.isSupplierNameExists(testSupplier.name, testSupplier.id)).called(1);
        verify(() => mockRepository.updateSupplier(testSupplier)).called(1);
      });

      test('should fail if updated name already exists', () async {
        // Arrange
        when(() => mockRepository.isSupplierNameExists(any(), any())).thenAnswer((_) async => true);
        
        // Act & Assert
        await expectLater(
          controller.updateSupplier(testSupplier),
          throwsA(isA<Exception>()),
        );
        expect(controller.debugState.status, SupplierOperationStatus.error);
      });
    });

    group('deleteSupplier', () {
      test('should succeed when supplier exists', () async {
        // Arrange
        when(() => mockRepository.deleteSupplier(any())).thenAnswer((_) async => 1);

        // Act
        await controller.deleteSupplier(testSupplier.id!);

        // Assert
        expect(controller.debugState.status, SupplierOperationStatus.success);
        verify(() => mockRepository.deleteSupplier(testSupplier.id!)).called(1);
      });

      test('should fail if supplier does not exist', () async {
        // Arrange
        when(() => mockRepository.deleteSupplier(any())).thenAnswer((_) async => 0);

        // Act & Assert
        await expectLater(
          controller.deleteSupplier(999),
          throwsA(isA<Exception>()),
        );
        expect(controller.debugState.status, SupplierOperationStatus.error);
      });
    });

    test('resetState should reset the state to initial', () {
      // Arrange
      controller.state = const SupplierControllerState(status: SupplierOperationStatus.success);
      
      // Act
      controller.resetState();

      // Assert
      expect(controller.debugState.status, SupplierOperationStatus.initial);
    });
  });
}