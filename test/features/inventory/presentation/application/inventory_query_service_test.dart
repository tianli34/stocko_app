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
import 'package:stocko_app/features/purchase/data/dao/purchase_dao.dart';
import 'package:stocko_app/features/inventory/data/repository/inventory_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_unit_repository.dart';
import 'package:stocko_app/features/product/data/repository/unit_repository.dart';

class MockInventoryRepository extends Mock implements IInventoryRepository {}
class MockProductRepository extends Mock implements IProductRepository {}
class MockProductUnitRepository extends Mock implements IProductUnitRepository {}
class MockUnitRepository extends Mock implements IUnitRepository {}
class MockBatchDao extends Mock implements BatchDao {}
class MockPurchaseDao extends Mock implements PurchaseDao {}

void main() {
  group('InventoryQueryService', () {
    late ProviderContainer container;
    late MockInventoryRepository inventoryRepo;
    late MockProductRepository productRepo;
    late MockProductUnitRepository productUnitRepo;
    late MockUnitRepository unitRepo;
    late MockBatchDao batchDao;
    late MockPurchaseDao purchaseDao;

    setUpAll(() {
      // Register fallback value for StockModel to be used with mocktail `any()`
      registerFallbackValue(
        StockModel(id: 0, productId: 0, quantity: 0, shopId: 0),
      );
    });

  setUp(() {
      // 初始化Flutter绑定
      TestWidgetsFlutterBinding.ensureInitialized();
      
      inventoryRepo = MockInventoryRepository();
      productRepo = MockProductRepository();
      productUnitRepo = MockProductUnitRepository();
      unitRepo = MockUnitRepository();
      batchDao = MockBatchDao();
      purchaseDao = MockPurchaseDao();

      container = ProviderContainer(overrides: [
        // Provide simple streams/futures for shops and categories
        allShopsProvider.overrideWith((ref) => Stream.value([
              const Shop(id: 1, name: '总仓', manager: 'A'),
            ])),
        allCategoriesStreamProvider.overrideWith((ref) => Stream.value([
              const CategoryModel(id: 10, name: '饮料', parentId: null),
            ])),
        batchDaoProvider.overrideWithValue(batchDao),
        purchaseDaoProvider.overrideWithValue(purchaseDao),
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
      
      // mock purchase dao
      when(() => purchaseDao.getLatestPurchasePrice(any()))
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

    group('getAggregatedInventory', () {
      test('应该正确聚合相同货品的库存', () async {
        // Arrange - 创建同一货品在不同店铺的库存
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 1, updatedAt: now),
              StockModel(id: 2, productId: 100, quantity: 30, shopId: 2, updatedAt: now),
              StockModel(id: 3, productId: 200, quantity: 20, shopId: 1, updatedAt: now),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
              ProductModel(id: 200, name: '雪碧', baseUnitId: 1, categoryId: 10),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        // Mock shop with id 2
        container = ProviderContainer(overrides: [
          allShopsProvider.overrideWith((ref) => Stream.value([
                const Shop(id: 1, name: '总仓', manager: 'A'),
                const Shop(id: 2, name: '分店A', manager: 'B'),
              ])),
          allCategoriesStreamProvider.overrideWith((ref) => Stream.value([
                const CategoryModel(id: 10, name: '饮料', parentId: null),
              ])),
          batchDaoProvider.overrideWithValue(batchDao),
          purchaseDaoProvider.overrideWithValue(purchaseDao),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          productRepositoryProvider.overrideWithValue(productRepo),
          productUnitRepositoryProvider.overrideWithValue(productUnitRepo),
          unitRepositoryProvider.overrideWithValue(unitRepo),
        ]);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 2); // 2个不同的货品
        
        // 验证可乐的聚合数据
        final colaItem = result.firstWhere((item) => item.productId == 100);
        expect(colaItem.productName, '可乐');
        expect(colaItem.totalQuantity, 80); // 50 + 30
        expect(colaItem.details.length, 2); // 2个店铺
        
        // 验证雪碧的聚合数据
        final spriteItem = result.firstWhere((item) => item.productId == 200);
        expect(spriteItem.productName, '雪碧');
        expect(spriteItem.totalQuantity, 20);
        expect(spriteItem.details.length, 1); // 1个店铺
      });

      test('应该正确处理无批次信息的库存', () async {
        // Arrange - 创建没有批次信息的库存
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 1, batchId: null, updatedAt: now),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 1);
        final item = result.first;
        expect(item.totalQuantity, 50);
        expect(item.details.first.batchId, isNull);
        expect(item.details.first.batchNumber, isNull);
      });

      test('应该正确应用分类筛选', () async {
        // Arrange - 创建不同分类的库存
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 1, updatedAt: now),
              StockModel(id: 2, productId: 200, quantity: 30, shopId: 1, updatedAt: now),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
              ProductModel(id: 200, name: '薯片', baseUnitId: 1, categoryId: 20),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        // Mock categories
        container = ProviderContainer(overrides: [
          allShopsProvider.overrideWith((ref) => Stream.value([
                const Shop(id: 1, name: '总仓', manager: 'A'),
              ])),
          allCategoriesStreamProvider.overrideWith((ref) => Stream.value([
                const CategoryModel(id: 10, name: '饮料', parentId: null),
                const CategoryModel(id: 20, name: '零食', parentId: null),
              ])),
          batchDaoProvider.overrideWithValue(batchDao),
          purchaseDaoProvider.overrideWithValue(purchaseDao),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          productRepositoryProvider.overrideWithValue(productRepo),
          productUnitRepositoryProvider.overrideWithValue(productUnitRepo),
          unitRepositoryProvider.overrideWithValue(unitRepo),
        ]);

        final service = container.read(inventoryQueryServiceProvider);

        // Act - 筛选饮料分类
        final result = await service.getAggregatedInventory(categoryFilter: '饮料');

        // Assert
        expect(result.length, 1);
        expect(result.first.productName, '可乐');
        expect(result.first.categoryName, '饮料');
      });

      test('应该返回空列表当没有库存时', () async {
        // Arrange
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => []);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result, isEmpty);
      });

      test('应该正确应用库存状态筛选', () async {
        // Arrange - 创建不同库存状态的数据
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 1, updatedAt: now), // 正常
              StockModel(id: 2, productId: 200, quantity: 5, shopId: 1, updatedAt: now),  // 低库存
              StockModel(id: 3, productId: 300, quantity: 0, shopId: 1, updatedAt: now),  // 缺货
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
              ProductModel(id: 200, name: '雪碧', baseUnitId: 1, categoryId: 10),
              ProductModel(id: 300, name: '芬达', baseUnitId: 1, categoryId: 10),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        final service = container.read(inventoryQueryServiceProvider);

        // Act - 筛选低库存
        final lowStockResult = await service.getAggregatedInventory(statusFilter: '低库存');

        // Assert
        expect(lowStockResult.length, 1);
        expect(lowStockResult.first.productName, '雪碧');
        expect(lowStockResult.first.totalQuantity, 5);

        // Act - 筛选缺货
        final outOfStockResult = await service.getAggregatedInventory(statusFilter: '缺货');

        // Assert
        expect(outOfStockResult.length, 1);
        expect(outOfStockResult.first.productName, '芬达');
        expect(outOfStockResult.first.totalQuantity, 0);
      });

      test('应该正确构建详细记录列表的所有字段', () async {
        // Arrange - 创建包含完整信息的库存
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(
                id: 1, 
                productId: 100, 
                quantity: 50, 
                shopId: 1, 
                batchId: 1001,
                updatedAt: now,
              ),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(
                id: 100, 
                name: '可乐', 
                baseUnitId: 1, 
                categoryId: 10,
                shelfLife: 365,
                shelfLifeUnit: ShelfLifeUnit.days,
              ),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        // Mock batch data - ProductBatchData is generated by Drift, so we can't construct it directly
        // Instead, we'll mock it to return null to test the no-batch scenario
        when(() => batchDao.getBatchByNumber(1001)).thenAnswer((_) async => null);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 1);
        final item = result.first;
        expect(item.details.length, 1);
        
        final detail = item.details.first;
        expect(detail.stockId, 1);
        expect(detail.shopId, 1);
        expect(detail.shopName, '总仓');
        expect(detail.quantity, 50);
        // Since batch lookup returns null, these fields should be null
        expect(detail.batchId, isNull);
        expect(detail.batchNumber, isNull);
        expect(detail.productionDate, isNull);
        expect(detail.shelfLifeDays, isNull);
        expect(detail.shelfLifeUnit, isNull);
        expect(detail.remainingDays, isNull);
      });

      test('应该正确处理同一货品在同一店铺的多个批次', () async {
        // Arrange - 创建同一货品同一店铺的多个批次
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(
                id: 1, 
                productId: 100, 
                quantity: 30, 
                shopId: 1, 
                batchId: 1001,
                updatedAt: now,
              ),
              StockModel(
                id: 2, 
                productId: 100, 
                quantity: 20, 
                shopId: 1, 
                batchId: 1002,
                updatedAt: now,
              ),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(
                id: 100, 
                name: '可乐', 
                baseUnitId: 1, 
                categoryId: 10,
                shelfLife: 365,
                shelfLifeUnit: ShelfLifeUnit.days,
              ),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        // Mock batch data for both batches - return null to simplify test
        when(() => batchDao.getBatchByNumber(1001)).thenAnswer((_) async => null);
        when(() => batchDao.getBatchByNumber(1002)).thenAnswer((_) async => null);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 1); // 只有一个货品
        final item = result.first;
        expect(item.productName, '可乐');
        expect(item.totalQuantity, 50); // 30 + 20
        expect(item.details.length, 2); // 2个批次
        
        // 验证两个批次的数量
        final quantities = item.details.map((d) => d.quantity).toList();
        expect(quantities, containsAll([30, 20]));
      });

      test('应该正确计算总库存数量（多店铺多批次）', () async {
        // Arrange - 创建复杂的多店铺多批次场景
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 1, batchId: 1001, updatedAt: now),
              StockModel(id: 2, productId: 100, quantity: 30, shopId: 1, batchId: 1002, updatedAt: now),
              StockModel(id: 3, productId: 100, quantity: 20, shopId: 2, batchId: 1001, updatedAt: now),
              StockModel(id: 4, productId: 100, quantity: 15, shopId: 2, batchId: 1003, updatedAt: now),
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        // Mock multiple shops
        container = ProviderContainer(overrides: [
          allShopsProvider.overrideWith((ref) => Stream.value([
                const Shop(id: 1, name: '总仓', manager: 'A'),
                const Shop(id: 2, name: '分店A', manager: 'B'),
              ])),
          allCategoriesStreamProvider.overrideWith((ref) => Stream.value([
                const CategoryModel(id: 10, name: '饮料', parentId: null),
              ])),
          batchDaoProvider.overrideWithValue(batchDao),
          purchaseDaoProvider.overrideWithValue(purchaseDao),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          productRepositoryProvider.overrideWithValue(productRepo),
          productUnitRepositoryProvider.overrideWithValue(productUnitRepo),
          unitRepositoryProvider.overrideWithValue(unitRepo),
        ]);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 1);
        final item = result.first;
        expect(item.totalQuantity, 115); // 50 + 30 + 20 + 15
        expect(item.details.length, 4); // 4条详细记录
        
        // 验证每个店铺的记录都存在
        final shopIds = item.details.map((d) => d.shopId).toSet();
        expect(shopIds, containsAll([1, 2]));
      });

      test('应该正确处理缺少店铺信息的库存', () async {
        // Arrange - 创建店铺ID不存在的库存
        final now = DateTime.now();
        when(() => inventoryRepo.getAllInventory()).thenAnswer((_) async => [
              StockModel(id: 1, productId: 100, quantity: 50, shopId: 999, updatedAt: now), // 不存在的店铺
            ]);

        when(() => productRepo.getAllProducts()).thenAnswer((_) async => [
              ProductModel(id: 100, name: '可乐', baseUnitId: 1, categoryId: 10),
            ]);

        when(() => unitRepo.getAllUnits()).thenAnswer((_) async => [
              const Unit(id: 1, name: '瓶'),
            ]);

        when(() => productUnitRepo.getBaseUnitForProduct(any()))
            .thenAnswer((_) async => null);
        
        when(() => purchaseDao.getLatestPurchasePrice(any()))
            .thenAnswer((_) async => null);

        final service = container.read(inventoryQueryServiceProvider);

        // Act
        final result = await service.getAggregatedInventory();

        // Assert
        expect(result.length, 1);
        final item = result.first;
        expect(item.totalQuantity, 50);
        expect(item.details.first.shopName, '未知店铺'); // 应该显示默认值
      });
    });
  });
}
