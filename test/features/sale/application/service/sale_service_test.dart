import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';
import 'package:stocko_app/features/sale/application/service/sale_service.dart';
import 'package:stocko_app/features/sale/data/repository/sales_transaction_repository.dart';
import 'package:stocko_app/features/sale/domain/model/sale_cart_item.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction.dart';
import 'package:stocko_app/features/sale/domain/repository/i_sales_transaction_repository.dart';

// Mocks
class MockSalesTransactionRepository extends Mock implements ISalesTransactionRepository {}
class MockInventoryService extends Mock implements InventoryService {}
class MockAppDatabase extends Mock implements AppDatabase {
  // Override transaction to simply execute the passed function.
  // This bypasses the need to mock the entire database transaction layer.
  @override
  Future<T> transaction<T>(Future<T> Function() action, {bool requireNew = false}) async {
    return action();
  }
}

// Fakes
class FakeSalesTransaction extends Fake implements SalesTransaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSalesTransaction());
  });

  group('SaleService', () {
    late ProviderContainer container;
    late MockSalesTransactionRepository mockSalesTransactionRepository;
    late MockInventoryService mockInventoryService;
    late MockAppDatabase mockAppDatabase;

    setUp(() {
      mockSalesTransactionRepository = MockSalesTransactionRepository();
      mockInventoryService = MockInventoryService();
      mockAppDatabase = MockAppDatabase();

      container = ProviderContainer(
        overrides: [
          salesTransactionRepositoryProvider.overrideWithValue(mockSalesTransactionRepository),
          inventoryServiceProvider.overrideWithValue(mockInventoryService),
          // We provide the mocked AppDatabase, but the key is its overridden transaction method.
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('processOneClickSale success for sale mode', () async {
      // Arrange
      final saleService = container.read(saleServiceProvider);
      final saleItems = [
        SaleCartItem(
            id: '1',
            productId: 1,
            quantity: 2,
            sellingPriceInCents: 1000,
            amount: 2000,
            productName: 'Test Product',
            unitId: 1,
            unitName: '个'),
      ];

      // Mock the repository and service calls that happen *inside* the transaction
      when(() => mockSalesTransactionRepository.addSalesTransaction(any())).thenAnswer((_) async => 1);
      when(() => mockSalesTransactionRepository.handleOutbound(1, 1, saleItems)).thenAnswer((_) async => 1);
      when(() => mockInventoryService.getInventory(1, 1)).thenAnswer(
          (_) async => StockModel(id: 1, productId: 1, shopId: 1, quantity: 10));
      when(() => mockInventoryService.outbound(
          productId: 1, shopId: 1, quantity: 2, batchId: null, time: any(named: 'time')))
          .thenAnswer((_) async => true);

      // Act
      final result = await saleService.processOneClickSale(
        salesOrderNo: 1,
        shopId: 1,
        saleItems: saleItems,
        isSaleMode: true,
      );

      // Assert
      expect(result, startsWith('SALE-'));
      verify(() => mockSalesTransactionRepository.addSalesTransaction(any())).called(1);
      verify(() => mockSalesTransactionRepository.handleOutbound(1, 1, saleItems)).called(1);
      verify(() => mockInventoryService.outbound(
          productId: 1, shopId: 1, quantity: 2, batchId: null, time: any(named: 'time')))
          .called(1);
    });
  });
}