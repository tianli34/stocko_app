import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/data/dao/product_dao.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/core/database/database.dart';

// Mock 类定义
class MockAppDatabase extends Mock implements AppDatabase {}

class MockProductDao extends Mock implements ProductDao {}

// 为了让 Mocktail 能够识别 ProductsTableData 和 ProductsTableCompanion
class FakeProductsTableData extends Fake implements ProductsTableData {}

class FakeProductsTableCompanion extends Fake
    implements ProductsTableCompanion {}

void main() {
  group('ProductRepository Tests', () {
    late ProductRepository repository;
    late MockAppDatabase mockDatabase;
    late MockProductDao mockProductDao; // 测试用的示例数据
    late Product testProduct;
    late ProductsTableData testProductData;

    setUpAll(() {
      // 注册 Fake 类型，让 Mocktail 能够处理这些类型
      registerFallbackValue(FakeProductsTableData());
      registerFallbackValue(FakeProductsTableCompanion());
    });

    setUp(() {
      mockDatabase = MockAppDatabase();
      mockProductDao = MockProductDao();

      // 设置 mock database 返回 mock dao
      when(() => mockDatabase.productDao).thenReturn(mockProductDao);

      repository = ProductRepository(mockDatabase); // 创建测试数据
      testProduct = const Product(
        id: 'test-id-001',
        name: '测试产品',
        sku: 'TEST-SKU-001',
        image: 'test-image.jpg',
        categoryId: 'category-001',
        unitId: 'unit-001',
        specification: '500ml',
        brand: '测试品牌',
        suggestedRetailPrice: 10.0,
        retailPrice: 8.0,
        promotionalPrice: 6.0,
        stockWarningValue: 10,
        shelfLife: 365,
        shelfLifeUnit: 'days',
        ownership: '测试商家',
        status: 'active',
        remarks: '测试备注',
      );
      testProductData = ProductsTableData(
        id: 'test-id-001',
        name: '测试产品',
        sku: 'TEST-SKU-001',
        image: 'test-image.jpg',
        categoryId: 'category-001',
        unitId: 'unit-001',
        specification: '500ml',
        brand: '测试品牌',
        suggestedRetailPrice: 10.0,
        retailPrice: 8.0,
        promotionalPrice: 6.0,
        stockWarningValue: 10,
        shelfLife: 365,
        shelfLifeUnit: 'days',
        ownership: '测试商家',
        status: 'active',
        remarks: '测试备注',
        lastUpdated: DateTime.now(),
      );
    });

    group('Create 操作测试', () {
      test('addProduct - 成功添加产品', () async {
        // Arrange
        when(
          () => mockProductDao.insertProduct(any()),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await repository.addProduct(testProduct);

        // Assert
        expect(result, equals(1));
        verify(() => mockProductDao.insertProduct(any())).called(1);
      });

      test('addProduct - 添加产品失败时抛出异常', () async {
        // Arrange
        when(
          () => mockProductDao.insertProduct(any()),
        ).thenThrow(Exception('数据库错误'));

        // Act & Assert
        expect(
          () => repository.addProduct(testProduct),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('添加产品失败'),
            ),
          ),
        );
      });
    });

    group('Read 操作测试', () {
      test('getProductById - 成功获取产品', () async {
        // Arrange
        when(
          () => mockProductDao.getProductById('test-id-001'),
        ).thenAnswer((_) async => testProductData);

        // Act
        final result = await repository.getProductById('test-id-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-id-001'));
        expect(result.name, equals('测试产品'));
        verify(() => mockProductDao.getProductById('test-id-001')).called(1);
      });

      test('getProductById - 产品不存在时返回null', () async {
        // Arrange
        when(
          () => mockProductDao.getProductById('non-existent-id'),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getProductById('non-existent-id');

        // Assert
        expect(result, isNull);
        verify(
          () => mockProductDao.getProductById('non-existent-id'),
        ).called(1);
      });

      test('getProductById - 获取产品失败时抛出异常', () async {
        // Arrange
        when(
          () => mockProductDao.getProductById(any()),
        ).thenThrow(Exception('数据库错误'));

        // Act & Assert
        expect(
          () => repository.getProductById('test-id-001'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('获取产品失败'),
            ),
          ),
        );
      });

      test('getAllProducts - 成功获取所有产品', () async {
        // Arrange
        final testProductList = [testProductData];
        when(
          () => mockProductDao.getAllProducts(),
        ).thenAnswer((_) async => testProductList);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('test-id-001'));
        expect(result.first.name, equals('测试产品'));
        verify(() => mockProductDao.getAllProducts()).called(1);
      });

      test('getAllProducts - 获取空列表', () async {
        // Arrange
        when(() => mockProductDao.getAllProducts()).thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result, isEmpty);
        verify(() => mockProductDao.getAllProducts()).called(1);
      });

      test('watchAllProducts - 成功监听产品流', () async {
        // Arrange
        final testProductList = [testProductData];
        when(
          () => mockProductDao.watchAllProducts(),
        ).thenAnswer((_) => Stream.value(testProductList));

        // Act
        final stream = repository.watchAllProducts();
        final result = await stream.first;

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('test-id-001'));
        verify(() => mockProductDao.watchAllProducts()).called(1);
      });
    });

    group('Update 操作测试', () {
      test('updateProduct - 成功更新产品', () async {
        // Arrange
        when(
          () => mockProductDao.updateProduct(any()),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateProduct(testProduct);

        // Assert
        expect(result, isTrue);
        verify(() => mockProductDao.updateProduct(any())).called(1);
      });
      test('updateProduct - 产品ID为空时抛出异常', () async {
        // Arrange
        final productWithEmptyId = testProduct.copyWith(id: '');

        // Act & Assert
        expect(
          () => repository.updateProduct(productWithEmptyId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('产品ID不能为空'),
            ),
          ),
        );
      });

      test('updateProduct - 更新失败时返回false', () async {
        // Arrange
        when(
          () => mockProductDao.updateProduct(any()),
        ).thenAnswer((_) async => false);

        // Act
        final result = await repository.updateProduct(testProduct);

        // Assert
        expect(result, isFalse);
        verify(() => mockProductDao.updateProduct(any())).called(1);
      });

      test('updateProduct - 数据库错误时抛出异常', () async {
        // Arrange
        when(
          () => mockProductDao.updateProduct(any()),
        ).thenThrow(Exception('数据库错误'));

        // Act & Assert
        expect(
          () => repository.updateProduct(testProduct),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('更新产品失败'),
            ),
          ),
        );
      });
    });

    group('Delete 操作测试', () {
      test('deleteProduct - 成功删除产品', () async {
        // Arrange
        when(
          () => mockProductDao.deleteProduct('test-id-001'),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteProduct('test-id-001');

        // Assert
        expect(result, equals(1));
        verify(() => mockProductDao.deleteProduct('test-id-001')).called(1);
      });

      test('deleteProduct - 删除不存在的产品返回0', () async {
        // Arrange
        when(
          () => mockProductDao.deleteProduct('non-existent-id'),
        ).thenAnswer((_) async => 0);

        // Act
        final result = await repository.deleteProduct('non-existent-id');

        // Assert
        expect(result, equals(0));
        verify(() => mockProductDao.deleteProduct('non-existent-id')).called(1);
      });

      test('deleteProduct - 删除失败时抛出异常', () async {
        // Arrange
        when(
          () => mockProductDao.deleteProduct(any()),
        ).thenThrow(Exception('数据库错误'));

        // Act & Assert
        expect(
          () => repository.deleteProduct('test-id-001'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('删除产品失败'),
            ),
          ),
        );
      });
    });

    group('扩展功能测试', () {
      test('getProductsByCondition - 根据条件查询产品', () async {
        // Arrange
        final testProductList = [testProductData];
        when(
          () => mockProductDao.getProductsByCondition(
            categoryId: any(named: 'categoryId'),
            status: any(named: 'status'),
            keyword: any(named: 'keyword'),
          ),
        ).thenAnswer((_) async => testProductList);

        // Act
        final result = await repository.getProductsByCondition(
          categoryId: 'category-001',
          status: 'active',
          keyword: '测试',
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.categoryId, equals('category-001'));
        verify(
          () => mockProductDao.getProductsByCondition(
            categoryId: 'category-001',
            status: 'active',
            keyword: '测试',
          ),
        ).called(1);
      });

      test('productExists - 检查产品是否存在', () async {
        // Arrange
        when(
          () => mockProductDao.productExists('test-id-001'),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.productExists('test-id-001');

        // Assert
        expect(result, isTrue);
        verify(() => mockProductDao.productExists('test-id-001')).called(1);
      });

      test('getProductCount - 获取产品数量', () async {
        // Arrange
        when(() => mockProductDao.getProductCount()).thenAnswer((_) async => 5);

        // Act
        final result = await repository.getProductCount();

        // Assert
        expect(result, equals(5));
        verify(() => mockProductDao.getProductCount()).called(1);
      });

      test('addMultipleProducts - 批量添加产品', () async {
        // Arrange
        final products = [testProduct, testProduct.copyWith(id: 'test-id-002')];
        when(
          () => mockProductDao.insertMultipleProducts(any()),
        ).thenAnswer((_) async {});

        // Act
        await repository.addMultipleProducts(products);

        // Assert
        verify(() => mockProductDao.insertMultipleProducts(any())).called(1);
      });

      test('updateMultipleProducts - 批量更新产品', () async {
        // Arrange
        final products = [testProduct, testProduct.copyWith(id: 'test-id-002')];
        when(
          () => mockProductDao.updateMultipleProducts(any()),
        ).thenAnswer((_) async {});

        // Act
        await repository.updateMultipleProducts(products);

        // Assert
        verify(() => mockProductDao.updateMultipleProducts(any())).called(1);
      });
    });

    group('Stream 监听测试', () {
      test('watchProductsByCategory - 监听指定类别的产品', () async {
        // Arrange
        final testProductList = [testProductData];
        when(
          () => mockProductDao.watchProductsByCategory('category-001'),
        ).thenAnswer((_) => Stream.value(testProductList));

        // Act
        final stream = repository.watchProductsByCategory('category-001');
        final result = await stream.first;

        // Assert
        expect(result, hasLength(1));
        expect(result.first.categoryId, equals('category-001'));
        verify(
          () => mockProductDao.watchProductsByCategory('category-001'),
        ).called(1);
      });

      test('watchAllProducts - 处理空数据流', () async {
        // Arrange
        when(
          () => mockProductDao.watchAllProducts(),
        ).thenAnswer((_) => Stream.value([]));

        // Act
        final stream = repository.watchAllProducts();
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
        verify(() => mockProductDao.watchAllProducts()).called(1);
      });
      test('watchAllProducts - 处理流错误', () async {
        // Arrange
        when(
          () => mockProductDao.watchAllProducts(),
        ).thenAnswer((_) => Stream.error(Exception('流错误')));

        // Act
        final stream = repository.watchAllProducts();

        // Assert
        expect(
          stream,
          emitsError(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('监听产品列表失败'),
            ),
          ),
        );
      });
    });

    group('数据转换测试', () {
      test('_productToCompanion - Product转换为Companion', () async {
        // 通过调用 addProduct 来间接测试 _productToCompanion 方法
        when(
          () => mockProductDao.insertProduct(any()),
        ).thenAnswer((_) async => 1);

        await repository.addProduct(testProduct);

        // 验证调用了 insertProduct，说明转换成功
        verify(() => mockProductDao.insertProduct(any())).called(1);
      });

      test('_dataToProduct - ProductsTableData转换为Product', () async {
        // 通过调用 getProductById 来间接测试 _dataToProduct 方法
        when(
          () => mockProductDao.getProductById('test-id-001'),
        ).thenAnswer((_) async => testProductData);

        final result = await repository.getProductById('test-id-001');
        expect(result, isNotNull);
        expect(result!.id, equals(testProductData.id));
        expect(result.name, equals(testProductData.name));
        expect(result.sku, equals(testProductData.sku));
      });
    });

    group('边界情况测试', () {
      test('处理 null 值的产品字段', () async {
        // Arrange
        final productWithNulls = const Product(
          id: 'test-minimal-id',
          name: '仅名称产品',
        );
        when(
          () => mockProductDao.insertProduct(any()),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await repository.addProduct(productWithNulls);

        // Assert
        expect(result, equals(1));
        verify(() => mockProductDao.insertProduct(any())).called(1);
      });

      test('处理空字符串ID', () async {
        // Arrange
        when(
          () => mockProductDao.getProductById(''),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getProductById('');

        // Assert
        expect(result, isNull);
        verify(() => mockProductDao.getProductById('')).called(1);
      });

      test('处理大量数据的批量操作', () async {
        // Arrange
        final largeProductList = List.generate(
          1000,
          (index) => testProduct.copyWith(id: 'test-id-$index'),
        );
        when(
          () => mockProductDao.insertMultipleProducts(any()),
        ).thenAnswer((_) async {});

        // Act
        await repository.addMultipleProducts(largeProductList);

        // Assert
        verify(() => mockProductDao.insertMultipleProducts(any())).called(1);
      });
    });
  });
}
