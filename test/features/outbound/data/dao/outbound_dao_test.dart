import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/outbound/data/dao/outbound_item_dao.dart';
import 'package:stocko_app/features/outbound/data/dao/outbound_receipt_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase database;
  late OutboundReceiptDao receiptDao;
  late OutboundItemDao itemDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    receiptDao = database.outboundReceiptDao;
    itemDao = database.outboundItemDao;
  });

  tearDown(() async {
    await database.close();
  });

  // Helper function to insert prerequisite data
  Future<int> insertTestShop() async {
    return await database
        .into(database.shop)
        .insert(ShopCompanion.insert(name: 'Test Shop', manager: 'Test Manager'));
  }
  
  Future<int> insertTestProduct() async {
    var unitId = await (database.select(database.unit)
          ..where((tbl) => tbl.name.equals('box')))
        .getSingleOrNull()
        .then((value) => value?.id);
    unitId ??= await database
          .into(database.unit)
          .insert(UnitCompanion.insert(name: 'box'));

    return await database.into(database.product).insert(
          ProductCompanion.insert(name: 'Test Product', baseUnitId: unitId),
        );
  }

  test('should insert and get an outbound receipt', () async {
    // Arrange
    final shopId = await insertTestShop();
    final receiptCompanion = OutboundReceiptCompanion.insert(
      shopId: shopId,
      reason: 'Sale',
      createdAt: Value(DateTime.now()),
    );

    // Act
    final newId = await receiptDao.insertOutboundReceipt(receiptCompanion);
    final fetchedReceipt = await receiptDao.getOutboundReceiptById(newId);

    // Assert
    expect(fetchedReceipt, isNotNull);
    expect(fetchedReceipt!.id, newId);
    expect(fetchedReceipt.shopId, shopId);
  });

  test('should insert a full outbound receipt with items in a transaction', () async {
    // Arrange
    final shopId = await insertTestShop();
    final productId1 = await insertTestProduct();
    final productId2 = await insertTestProduct();

    // Act
    final newReceiptId = await database.transaction(() async {
      final receiptId = await receiptDao.insertOutboundReceipt(
        OutboundReceiptCompanion.insert(
          shopId: shopId,
          reason: 'Manual',
          createdAt: Value(DateTime.now()),
        ),
      );

      await database.batch((batch) {
        batch.insertAll(database.outboundItem, [
          OutboundItemCompanion.insert(
            receiptId: receiptId,
            productId: productId1,
            quantity: 10,
          ),
          OutboundItemCompanion.insert(
            receiptId: receiptId,
            productId: productId2,
            quantity: 5,
          ),
        ]);
      });

      return receiptId;
    });

    // Assert
    final items = await itemDao.getOutboundItemsByReceiptId(newReceiptId);
    expect(items, hasLength(2));
    expect(items.first.productId, productId1);
    expect(items.last.quantity, 5);
  });
}