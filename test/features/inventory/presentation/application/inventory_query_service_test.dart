import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';
import 'package:stocko_app/features/inventory/domain/repository/i_inventory_repository.dart';
import 'package:stocko_app/features/inventory/presentation/application/inventory_query_service.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_unit_repository.dart';
import 'package:stocko_app/features/product/domain/repository/i_unit_repository.dart';
import 'package:stocko_app/features/inventory/application/provider/shop_providers.dart';
import 'package:stocko_app/features/inventory/domain/model/shop.dart';
import 'package:stocko_app/features/product/application/category_notifier.dart';
import 'package:stocko_app/features/product/domain/model/category.dart';
import 'package:stocko_app/features/product/data/dao/batch_dao.dart';
import 'package:stocko_app/features/inventory/data/repository/inventory_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_unit_repository.dart';
import 'package:stocko_app/features/product/data/repository/unit_repository.dart';

class MockInventoryRepository extends Mock implements IInventoryRepository {}
class MockProductRepository extends Mock implements IProductRepository {}
class MockProductUnitRepository extends Mock implements IProductUnitRepository {}
class MockUnitRepository extends Mock implements IUnitRepository {}
class MockBatchDao extends Mock implements BatchDao {}

void main() {
  group('InventoryQueryService', () {
    late ProviderContainer container;
    late MockInventoryRepository inventoryRepo;
    late MockProductRepository productRepo;
    late MockProductUnitRepository productUnitRepo;
    late MockUnitRepository unitRepo;
    late MockBatchDao batchDao;

    setUpAll(() {
      // Register fallback value for StockModel to be used with mocktail `any()`
      registerFallbackValue(
        StockModel(id: 0, productId: 0, quantity: 0, shopId: 0),
      );
    });

  setUp(() {
      inventoryRepo = MockInventoryRepository();
      productRepo = MockProductRepository();
      productUnitRepo = MockProductUnitRepository();
      unitRepo = MockUnitRepository();
      batchDao = MockBatchDao();

      container = ProviderContainer(overrides: [
        // Provide simple streams/futures for shops and categories
        allShopsProvider.overrideWith((ref) => Stream.value([
              const Shop(id: 1, name: '总仓', manager: 'A'),
            ])),
        allCategoriesStreamProvider.overrideWith((ref) => Stream.value([
              const CategoryModel(id: 10, name: '饮料', parentId: null),
            ])),
        batchDaoProvider.overrideWithValue(batchDao),
        // repository overrides
        inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
        productRepositoryProvider.overrideWithValue(productRepo),
        productUnitRepositoryProvider.overrideWithValue(productUnitRepo),
        unitRepositoryProvider.overrideWithValue(unitRepo),
      ]);
    });

    tearDown(() => container.dispose());

    test('getInventoryWithDetails 聚合产品、单位、分类、店铺信息并支持筛选', () async {
      // Arrange inventory
      final now = DateTime.now();
      when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
            StockModel(id: 1, productId: 100, quantity: 20, shopId: 1, updatedAt: now),
          ]);

      // products
      when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
            ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
          ]);

      // units
      when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
            const Unit(id: 1, name: '瓶'),
          ]);

      // product base unit mapping (optional in service; simulate null to fallback to product.baseUnitId)
      when(() => productUnitRepo.getBaseUnitForProduct(100))
          .thenAnswer((_) async => null);

  final service = container.read(inventoryQueryServiceProvider);

      // Act
      final list = await service.getInventoryWithDetails(
        shopFilter: '所有仓库',
        categoryFilter: '所有分类',
        statusFilter: '库存状态',
      );

      // Assert
      expect(list, isNotEmpty);
      final item = list.first;
      expect(item['productName'], '可乐');
      expect(item['unit'], '瓶');
      expect(item['categoryName'], '饮料');
      expect(item['shopName'], '总仓');

      // filter by status "缺货" should exclude
      final filtered = await service.getInventoryWithDetails(statusFilter: '缺货');
      expect(filtered, isEmpty);
    });

    test('adjustStock 更新已存在记录，否则创建新记录', () async {
  final service = container.read(inventoryQueryServiceProvider);

      // existing -> update
      final existing = StockModel(id: 1, productId: 1, quantity: 5, shopId: 1);
      when(() => inventoryRepo.getInventoryByProductShopAndBatch(1, 1, null))
          .thenAnswer((_) async => existing);
      when(() => inventoryRepo.updateInventory(any()))
          .thenAnswer((_) async => true);

      await service.adjustStock(productId: 1, shopId: 1, newQuantity: 9);
      verify(() => inventoryRepo.updateInventory(any())).called(1);

      // non-existing -> add
      when(() => inventoryRepo.getInventoryByProductShopAndBatch(2, 1, null))
          .thenAnswer((_) async => null);
      when(() => inventoryRepo.addInventory(any())).thenAnswer((_) async => 1);

      await service.adjustStock(productId: 2, shopId: 1, newQuantity: 3);
      verify(() => inventoryRepo.addInventory(any())).called(1);
    });
  });
}
