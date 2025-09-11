import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory_transaction.dart';
import 'package:stocko_app/features/inventory/domain/repository/i_inventory_repository.dart';
import 'package:stocko_app/features/inventory/domain/repository/i_inventory_transaction_repository.dart';

class MockInventoryRepository extends Mock implements IInventoryRepository {}
class MockInventoryTransactionRepository extends Mock implements IInventoryTransactionRepository {}
class MockAppDatabase extends Mock implements AppDatabase {
  @override
  Future<T> transaction<T>(Future<T> Function() action, {bool requireNew = false}) async {
    return action();
  }
}

class FakeInventoryTransactionModel extends Fake implements InventoryTransactionModel {}
class FakeStockModel extends Fake implements StockModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeInventoryTransactionModel());
    registerFallbackValue(FakeStockModel());
  });

  group('InventoryService', () {
    late InventoryService inventoryService;
    late MockInventoryRepository mockInventoryRepository;
    late MockInventoryTransactionRepository mockTransactionRepository;
    late MockAppDatabase mockDatabase;

    setUp(() {
      mockInventoryRepository = MockInventoryRepository();
      mockTransactionRepository = MockInventoryTransactionRepository();
      mockDatabase = MockAppDatabase();
      inventoryService = InventoryService(
        mockInventoryRepository,
        mockTransactionRepository,
        mockDatabase,
      );
    });

    group('inbound', () {
      test('成功入库到现有库存', () async {
        // Arrange
        final existingInventory = StockModel(
          id: 1,
          productId: 1,
          quantity: 10,
          shopId: 1,
        );
        
        when(() => mockInventoryRepository.getInventoryByProductShopAndBatch(1, 1, null))
            .thenAnswer((_) async => existingInventory);
        when(() => mockInventoryRepository.addInventoryQuantityByBatch(1, 1, null, 5))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.inbound(
          productId: 1,
          shopId: 1,
          quantity: 5,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.addInventoryQuantityByBatch(1, 1, null, 5)).called(1);
        verify(() => mockTransactionRepository.addTransaction(any())).called(1);
      });

      test('成功入库到新库存记录', () async {
        // Arrange
        when(() => mockInventoryRepository.getInventoryByProductShopAndBatch(1, 1, null))
            .thenAnswer((_) async => null);
        when(() => mockInventoryRepository.addInventory(any()))
            .thenAnswer((_) async => 1);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.inbound(
          productId: 1,
          shopId: 1,
          quantity: 5,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.addInventory(any())).called(1);
        verify(() => mockTransactionRepository.addTransaction(any())).called(1);
      });

      test('入库失败时返回false', () async {
        // Arrange
        when(() => mockInventoryRepository.getInventoryByProductShopAndBatch(1, 1, null))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await inventoryService.inbound(
          productId: 1,
          shopId: 1,
          quantity: 5,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('outbound', () {
      test('成功出库', () async {
        // Arrange
        final existingInventory = StockModel(
          id: 1,
          productId: 1,
          quantity: 10,
          shopId: 1,
        );
        
        when(() => mockInventoryRepository.getInventoryByProductShopAndBatch(1, 1, null))
            .thenAnswer((_) async => existingInventory);
        when(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 5))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.outbound(
          productId: 1,
          shopId: 1,
          quantity: 5,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 5)).called(1);
        verify(() => mockTransactionRepository.addTransaction(any())).called(1);
      });

      test('库存不存在时创建初始记录并出库', () async {
        // Arrange
        when(() => mockInventoryRepository.getInventoryByProductShopAndBatch(1, 1, null))
            .thenAnswer((_) async => null);
        when(() => mockInventoryRepository.addInventory(any()))
            .thenAnswer((_) async => 1);
        when(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 5))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.outbound(
          productId: 1,
          shopId: 1,
          quantity: 5,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.addInventory(any())).called(1);
        verify(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 5)).called(1);
      });
    });

    group('adjust', () {
      test('正向调整库存', () async {
        // Arrange
        when(() => mockInventoryRepository.addInventoryQuantity(1, 1, 5))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.adjust(
          productId: 1,
          shopId: 1,
          adjustQuantity: 5,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.addInventoryQuantity(1, 1, 5)).called(1);
      });

      test('负向调整库存', () async {
        // Arrange
        when(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 3))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        final result = await inventoryService.adjust(
          productId: 1,
          shopId: 1,
          adjustQuantity: -3,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockInventoryRepository.subtractInventoryQuantity(1, 1, 3)).called(1);
      });
    });

    group('getInventory', () {
      test('成功获取库存信息', () async {
        // Arrange
        final inventory = StockModel(
          id: 1,
          productId: 1,
          quantity: 10,
          shopId: 1,
        );
        when(() => mockInventoryRepository.getInventoryByProductAndShop(1, 1))
            .thenAnswer((_) async => inventory);

        // Act
        final result = await inventoryService.getInventory(1, 1);

        // Assert
        expect(result, equals(inventory));
      });
    });

    group('adjustInventory', () {
      test('调整库存到目标数量', () async {
        // Arrange
        final currentInventory = StockModel(
          id: 1,
          productId: 1,
          quantity: 10,
          shopId: 1,
        );
        when(() => mockInventoryRepository.getInventoryByProductAndShop(1, 1))
            .thenAnswer((_) async => currentInventory);
        when(() => mockInventoryRepository.addInventoryQuantity(1, 1, 5))
            .thenAnswer((_) async => true);
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => 1);

        // Act
        await inventoryService.adjustInventory(
          productId: 1,
          quantity: 15,
          shopId: 1,
        );

        // Assert
        verify(() => mockInventoryRepository.addInventoryQuantity(1, 1, 5)).called(1);
      });

      test('目标数量与当前数量相同时不执行调整', () async {
        // Arrange
        final currentInventory = StockModel(
          id: 1,
          productId: 1,
          quantity: 10,
          shopId: 1,
        );
        when(() => mockInventoryRepository.getInventoryByProductAndShop(1, 1))
            .thenAnswer((_) async => currentInventory);

        // Act
        await inventoryService.adjustInventory(
          productId: 1,
          quantity: 10,
          shopId: 1,
        );

        // Assert
        verifyNever(() => mockInventoryRepository.addInventoryQuantity(any(), any(), any()));
        verifyNever(() => mockInventoryRepository.subtractInventoryQuantity(any(), any(), any()));
      });
    });
  });
}