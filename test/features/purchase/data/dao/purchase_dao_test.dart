import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/core/database/purchase_orders_table.dart';
import 'package:stocko_app/features/purchase/data/dao/purchase_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase database;
  late PurchaseDao purchaseDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    purchaseDao = database.purchaseDao;
  });

  tearDown(() async {
    await database.close();
  });

  // Helper function to insert prerequisite data
  Future<int> _insertTestUnit() async {
    return await database.into(database.unit).insert(
          UnitCompanion.insert(name: 'g'),
        );
  }

  Future<int> _insertTestProduct(int unitId) async {
    return await database.into(database.product).insert(
          ProductCompanion.insert(
              name: 'Test Product', baseUnitId: unitId),
        );
  }
  
  Future<int> _insertTestSupplier() async {
    return await database.into(database.supplier).insert(
          SupplierCompanion.insert(name: 'Test Supplier'),
        );
  }

  Future<int> _insertTestShop() async {
    return await database.into(database.shop).insert(
          ShopCompanion.insert(name: 'Test Shop', manager: 'Test Manager'),
        );
  }


  test('createFullPurchaseOrder should create an order and its items',
      () async {
    // Arrange
    final supplierId = await _insertTestSupplier();
    final shopId = await _insertTestShop();
    final unitId = await _insertTestUnit();
    final productId = await _insertTestProduct(unitId);

    final orderCompanion = PurchaseOrderCompanion.insert(
      supplierId: supplierId,
      shopId: shopId,
      status: const Value(PurchaseOrderStatus.draft),
    );

    final itemCompanions = [
      PurchaseOrderItemCompanion.insert(
        purchaseOrderId: 0, // Placeholder, will be replaced by DAO
        productId: productId,
        quantity: 10,
  unitPriceInCents: 1000,
  // 设置生产日期以避免与同一产品在同一订单中的唯一约束冲突
  productionDate: Value(DateTime(2024, 1, 1)),
      ),
      PurchaseOrderItemCompanion.insert(
        purchaseOrderId: 0, // Placeholder, will be replaced by DAO
        productId: productId,
        quantity: 5,
  unitPriceInCents: 1200,
  // 与上一个明细使用不同的生产日期，满足 (order, product, production_date) 唯一约束
  productionDate: Value(DateTime(2024, 2, 1)),
      ),
    ];

    // Act
    final newOrderId = await purchaseDao.createFullPurchaseOrder(
      order: orderCompanion,
      items: itemCompanions,
    );

    // Assert
    expect(newOrderId, isA<int>());

    final createdOrder = await purchaseDao.getPurchaseOrderById(newOrderId);
    expect(createdOrder, isNotNull);
    expect(createdOrder!.supplierId, supplierId);

    final createdItems = await purchaseDao.getPurchaseOrderItems(newOrderId);
    expect(createdItems, hasLength(2));
    expect(createdItems.first.quantity, 10);
  });

  test('deletePurchaseOrder should remove the order and its items', () async {
    // Arrange
    final supplierId = await _insertTestSupplier();
    final shopId = await _insertTestShop();
    final unitId = await _insertTestUnit();
    final productId = await _insertTestProduct(unitId);

    final orderId = await purchaseDao.createFullPurchaseOrder(
      order: PurchaseOrderCompanion.insert(
        supplierId: supplierId,
        shopId: shopId,
      ),
      items: [
        PurchaseOrderItemCompanion.insert(
          purchaseOrderId: 0, // Placeholder
          productId: productId,
          quantity: 1,
          unitPriceInCents: 1,
        )
      ],
    );

    // Act
    final deletedRows = await purchaseDao.deletePurchaseOrder(orderId);

    // Assert
    // The transaction in deletePurchaseOrder returns the result of the *last* operation.
    // In this case, it's the deletion of the order itself, which is 1 row.
    expect(deletedRows, 1); 

    final orderAfterDelete = await purchaseDao.getPurchaseOrderById(orderId);
    expect(orderAfterDelete, isNull);

    final itemsAfterDelete = await purchaseDao.getPurchaseOrderItems(orderId);
    expect(itemsAfterDelete, isEmpty);
  });

  test('watchPurchaseOrderWithItems emits correct data', () async {
    // Arrange
    final supplierId = await _insertTestSupplier();
    final shopId = await _insertTestShop();
    final unitId = await _insertTestUnit();
    final productId = await _insertTestProduct(unitId);
    
    final orderCompanion = PurchaseOrderCompanion.insert(
      supplierId: supplierId,
      shopId: shopId,
    );
    final itemCompanion = PurchaseOrderItemCompanion.insert(
        purchaseOrderId: 0, // Placeholder
        productId: productId,
        quantity: 50,
        unitPriceInCents: 500);

    // Act
    final orderId = await purchaseDao.createFullPurchaseOrder(
      order: orderCompanion,
      items: [itemCompanion],
    );

    final stream = purchaseDao.watchPurchaseOrderWithItems(orderId);

    // Assert
    expect(
        stream,
        emits(isA<PurchaseOrderWithItems>()
            .having((e) => e.order.id, 'order.id', orderId)
            .having((e) => e.items.length, 'items.length', 1)
            .having((e) => e.items.first.item.quantity, 'item quantity', 50)
            .having((e) => e.items.first.product.name, 'product name', 'Test Product')
            ));
  });
}