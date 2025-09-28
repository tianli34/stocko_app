import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' as drift;

import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inbound/application/service/inbound_service.dart';
import 'package:stocko_app/features/inbound/application/provider/inbound_list_provider.dart';
import 'package:stocko_app/features/inbound/data/dao/inbound_item_dao.dart';
import 'package:stocko_app/features/inbound/data/dao/inbound_receipt_dao.dart';
import 'package:stocko_app/features/product/data/dao/batch_dao.dart';
import 'package:stocko_app/features/product/data/dao/product_dao.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/inventory/application/service/weighted_average_price_service.dart';
import 'package:stocko_app/features/purchase/data/dao/purchase_dao.dart';
import 'package:stocko_app/features/purchase/domain/repository/i_supplier_repository.dart';
import 'package:stocko_app/features/purchase/domain/model/supplier.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/core/database/purchase_orders_table.dart';

// Mocks
class MockAppDatabase extends Mock implements AppDatabase {}
class MockPurchaseDao extends Mock implements PurchaseDao {}
class MockBatchDao extends Mock implements BatchDao {}
class MockInboundReceiptDao extends Mock implements InboundReceiptDao {}
class MockInboundItemDao extends Mock implements InboundItemDao {}
class MockProductDao extends Mock implements ProductDao {}
class MockInventoryService extends Mock implements InventoryService {}
class MockSupplierRepository extends Mock implements ISupplierRepository {}
class MockWeightedAveragePriceService extends Mock implements WeightedAveragePriceService {}

void main() {
  setUpAll(() {
    // Register fallback values required by mocktail for complex types
    registerFallbackValue(
      InboundReceiptCompanion.insert(
        shopId: 1,
        source: 'x',
      ),
    );
    registerFallbackValue(
      InboundItemCompanion.insert(
        receiptId: 1,
        productId: 1,
        quantity: 1,
      ),
    );
    registerFallbackValue(
      PurchaseOrderCompanion(
        supplierId: const drift.Value(1),
        shopId: const drift.Value(1),
        status: const drift.Value(PurchaseOrderStatus.completed),
      ),
    );
    registerFallbackValue(
      PurchaseOrderItemCompanion(
        productId: const drift.Value(1),
        quantity: const drift.Value(1),
        unitPriceInCents: const drift.Value(1),
      ),
    );
    registerFallbackValue(<PurchaseOrderItemCompanion>[]);
    registerFallbackValue(const Supplier(name: 'fallback'));
  });

  group('InboundService.processOneClickInbound', () {
    late MockAppDatabase db;
    late MockPurchaseDao purchaseDao;
    late MockBatchDao batchDao;
    late MockInboundReceiptDao inboundReceiptDao;
    late MockInboundItemDao inboundItemDao;
    late MockProductDao productDao;
    late MockInventoryService inventoryService;
    late MockWeightedAveragePriceService weightedAveragePriceService;
    late MockSupplierRepository supplierRepo;
    late InboundService service;

    setUp(() {
      db = MockAppDatabase();
      purchaseDao = MockPurchaseDao();
      batchDao = MockBatchDao();
      inboundReceiptDao = MockInboundReceiptDao();
      inboundItemDao = MockInboundItemDao();
      productDao = MockProductDao();
      inventoryService = MockInventoryService();
      weightedAveragePriceService = MockWeightedAveragePriceService();
      supplierRepo = MockSupplierRepository();

      // transaction passthrough
      when(() => db.transaction<String>(any(), requireNew: any(named: 'requireNew')))
          .thenAnswer((invocation) async {
        final fn = invocation.positionalArguments.first as Future<String> Function();
        return await fn();
      });

      // wire DAOs
      when(() => db.purchaseDao).thenReturn(purchaseDao);
      when(() => db.batchDao).thenReturn(batchDao);
      when(() => db.inboundReceiptDao).thenReturn(inboundReceiptDao);
      when(() => db.inboundItemDao).thenReturn(inboundItemDao);
      when(() => db.productDao).thenReturn(productDao);

      service = InboundService(db, inventoryService, weightedAveragePriceService, supplierRepo);
      
      // Mock weightedAveragePriceService methods
      when(() => weightedAveragePriceService.updateWeightedAveragePrice(
        productId: any(named: 'productId'),
        shopId: any(named: 'shopId'),
        batchId: any(named: 'batchId'),
        inboundQuantity: any(named: 'inboundQuantity'),
        inboundUnitPriceInCents: any(named: 'inboundUnitPriceInCents'),
      )).thenAnswer((_) async => {});
    });

    test('采购模式：自动创建供应商 + 创建采购单 + 写批次 + 入库单/明细(含批次) + 更新库存', () async {
      // Arrange
      // supplier flow
      when(() => supplierRepo.getSupplierById(any())).thenAnswer((_) async => null);
      when(() => supplierRepo.getSupplierByName('Acme')).thenAnswer((_) async => null);
      when(() => supplierRepo.addSupplier(any())).thenAnswer((_) async => 99);

      // purchase order creation
      when(() => purchaseDao.createFullPurchaseOrder(
        order: any(named: 'order'),
        items: any(named: 'items'),
      )).thenAnswer((_) async => 1001);

      // product enable batch
      final p = ProductData(
        id: 1,
        name: 'Prod',
        sku: null,
        image: null,
        baseUnitId: 1,
        categoryId: null,
        specification: null,
        brand: null,
        suggestedRetailPrice: null,
        retailPrice: null,
        promotionalPrice: null,
        stockWarningValue: null,
        shelfLife: null,
        shelfLifeUnit: ShelfLifeUnit.months,
        enableBatchManagement: true,
        status: ProductStatus.active,
        remarks: null,
        lastUpdated: null,
      );
      when(() => productDao.getProductById(1)).thenAnswer((_) async => p);

      // batch upsert + get id
      when(() => batchDao.upsertBatchIncrement(
            productId: 1,
            productionDate: any(named: 'productionDate'),
            shopId: 10,
            increment: 5,
          )).thenAnswer((_) async => Future.value());
      when(() => batchDao.getBatchIdByBusinessKey(
            productId: 1,
            productionDate: any(named: 'productionDate'),
            shopId: 10,
          )).thenAnswer((_) async => 777);

      // inbound receipt/id
      when(() => inboundReceiptDao.insertInboundReceipt(any())).thenAnswer((_) async => 123);
      when(() => inboundItemDao.insertMultipleInboundItems(any())).thenAnswer((_) async => Future.value());

      // inventory
      when(() => inventoryService.inbound(
            productId: 1,
            shopId: 10,
            batchId: 777,
            quantity: 5,
            time: any(named: 'time'),
          )).thenAnswer((_) async => true);

      final items = [
        InboundItemState(
          id: 'x',
          productId: 1,
          productName: 'Prod',
          unitId: 1,
          unitName: '个',
          quantity: 5,
          unitPriceInCents: 1234,
          productionDate: DateTime(2024, 1, 1),
          conversionRate: 1,
        ),
      ];

      // Act
      final receipt = await service.processOneClickInbound(
        shopId: 10,
        inboundItems: items,
        source: 'purchase',
        isPurchaseMode: true,
        supplierName: 'Acme',
      );

      // Assert
      expect(receipt, startsWith('PO'));

      // verify batch upsert called
      verify(() => batchDao.upsertBatchIncrement(
            productId: 1,
            productionDate: any(named: 'productionDate'),
            shopId: 10,
            increment: 5,
          )).called(1);

      // capture inbound items to ensure batchId set
      final captured = verify(() => inboundItemDao.insertMultipleInboundItems(captureAny()))
          .captured
          .single as List<InboundItemCompanion>;
      expect(captured.length, 1);
      final first = captured.first;
      expect(first.receiptId.present, true);
      expect(first.productId.value, 1);
      expect(first.quantity.value, 5);
      expect(first.batchId.present, true);

      verify(() => inventoryService.inbound(
            productId: 1,
            shopId: 10,
            batchId: 777,
            quantity: 5,
            time: any(named: 'time'),
          )).called(1);
    });

    test('非采购模式：无批次产品不写入批次ID，返回 receiptId 字符串', () async {
      // Arrange
      when(() => supplierRepo.getSupplierById(any())).thenAnswer((_) async => null);

      // product without batch management
      final p = ProductData(
        id: 2,
        name: 'Prod2',
        sku: null,
        image: null,
        baseUnitId: 1,
        categoryId: null,
        specification: null,
        brand: null,
        suggestedRetailPrice: null,
        retailPrice: null,
        promotionalPrice: null,
        stockWarningValue: null,
        shelfLife: null,
        shelfLifeUnit: ShelfLifeUnit.months,
        enableBatchManagement: false,
        status: ProductStatus.active,
        remarks: null,
        lastUpdated: null,
      );
      when(() => productDao.getProductById(2)).thenAnswer((_) async => p);

      // inbound receipt
      when(() => inboundReceiptDao.insertInboundReceipt(any())).thenAnswer((_) async => 456);
      when(() => inboundItemDao.insertMultipleInboundItems(any())).thenAnswer((_) async => Future.value());

      // inventory
      when(() => inventoryService.inbound(
            productId: 2,
            shopId: 11,
            batchId: null,
            quantity: 3,
            time: any(named: 'time'),
          )).thenAnswer((_) async => true);

      final items = [
        InboundItemState(
          id: 'y',
          productId: 2,
          productName: 'Prod2',
          unitId: 1,
          unitName: '个',
          quantity: 3,
          unitPriceInCents: 500,
          conversionRate: 1,
        ),
      ];

      // Act
      final receipt = await service.processOneClickInbound(
        shopId: 11,
        inboundItems: items,
        source: 'manual',
        isPurchaseMode: false,
      );

      // Assert
      expect(receipt, '456');

      // ensure no batch upsert
      verifyNever(() => batchDao.upsertBatchIncrement(
            productId: any(named: 'productId'),
            productionDate: any(named: 'productionDate'),
            shopId: any(named: 'shopId'),
            increment: any(named: 'increment'),
          ));

      // items without batchId
      final captured = verify(() => inboundItemDao.insertMultipleInboundItems(captureAny()))
          .captured
          .single as List<InboundItemCompanion>;
      expect(captured.first.batchId.present, false);

      verify(() => inventoryService.inbound(
            productId: 2,
            shopId: 11,
            batchId: null,
            quantity: 3,
            time: any(named: 'time'),
          )).called(1);
    });

    test('库存更新失败应抛出异常并回滚', () async {
      // Arrange
      final p = ProductData(
        id: 3,
        name: 'P3',
        sku: null,
        image: null,
        baseUnitId: 1,
        categoryId: null,
        specification: null,
        brand: null,
        suggestedRetailPrice: null,
        retailPrice: null,
        promotionalPrice: null,
        stockWarningValue: null,
        shelfLife: null,
        shelfLifeUnit: ShelfLifeUnit.months,
        enableBatchManagement: false,
        status: ProductStatus.active,
        remarks: null,
        lastUpdated: null,
      );
      when(() => productDao.getProductById(3)).thenAnswer((_) async => p);

      when(() => inboundReceiptDao.insertInboundReceipt(any())).thenAnswer((_) async => 789);
      when(() => inboundItemDao.insertMultipleInboundItems(any())).thenAnswer((_) async => Future.value());

      when(() => inventoryService.inbound(
            productId: 3,
            shopId: 12,
            batchId: null,
            quantity: 1,
            time: any(named: 'time'),
          )).thenAnswer((_) async => false);

      final items = [
        InboundItemState(
          id: 'z',
          productId: 3,
          productName: 'P3',
          unitId: 1,
          unitName: '个',
          quantity: 1,
          unitPriceInCents: 100,
          conversionRate: 1,
        ),
      ];

      // Act & Assert
      expect(
        () => service.processOneClickInbound(
          shopId: 12,
          inboundItems: items,
          source: 'manual',
          isPurchaseMode: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('采购模式但未提供供应商信息时抛出异常', () async {
      // Arrange
      when(() => db.transaction<String>(any(), requireNew: any(named: 'requireNew')))
          .thenAnswer((invocation) async {
        final fn = invocation.positionalArguments.first as Future<String> Function();
        return await fn();
      });

      final items = [
        InboundItemState(
          id: 'n',
          productId: 1,
          productName: 'X',
          unitId: 1,
          unitName: '个',
          quantity: 1,
          unitPriceInCents: 100,
          conversionRate: 1,
        ),
      ];

      // Act & Assert
      expect(
        () => service.processOneClickInbound(
          shopId: 1,
          inboundItems: items,
          source: 'purchase',
          isPurchaseMode: true,
        ),
        throwsException,
      );
    });
  });
}
