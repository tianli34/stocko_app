import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';
import 'package:stocko_app/features/product/application/provider/product_providers.dart';

// Mock 类定义
class MockProductRepository extends Mock implements IProductRepository {}

class MockRef extends Mock implements Ref {}

// 为了让 Mocktail 能够识别 Product 类型
class FakeProduct extends Fake implements Product {}

void main() {
  group('ProductController Tests', () {
    late ProductController controller;
    late MockProductRepository mockRepository;
    late MockRef mockRef;
    late Product testProduct;

    setUpAll(() {
      // 注册 Fake 类型，让 Mocktail 能够处理这些类型
      registerFallbackValue(FakeProduct());
    });

    setUp(() {
      mockRepository = MockProductRepository();
      mockRef = MockRef();
      controller = ProductController(mockRepository, mockRef);

      // 创建测试数据
      testProduct = const Product(
        id: 'test-id-001',
        name: '测试产品',
        barcode: '123456789',
        sku: 'TEST-SKU-001',
        retailPrice: 10.0,
        status: 'active',
      );
    });

    group('初始状态测试', () {
      test('应该具有正确的初始状态', () {
        expect(controller.state.status, ProductOperationStatus.initial);
        expect(controller.state.errorMessage, isNull);
        expect(controller.state.lastOperatedProduct, isNull);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.isError, isFalse);
        expect(controller.state.isSuccess, isFalse);
      });
    });

    group('addProduct 测试', () {
      test('成功添加产品 - 应该更新状态为 success', () async {
        // Arrange
        when(() => mockRepository.addProduct(any())).thenAnswer((_) async => 1);

        // Act
        await controller.addProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.success);
        expect(controller.state.lastOperatedProduct, testProduct);
        expect(controller.state.errorMessage, isNull);

        // 验证方法调用
        verify(() => mockRepository.addProduct(testProduct)).called(1);
        verify(() => mockRef.invalidate(allProductsProvider)).called(1);
      });

      test('添加产品失败 - 应该更新状态为 error', () async {
        // Arrange
        const errorMessage = '数据库连接失败';
        when(
          () => mockRepository.addProduct(any()),
        ).thenThrow(Exception(errorMessage));

        // Act
        await controller.addProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains(errorMessage));
        expect(controller.state.lastOperatedProduct, isNull);

        // 验证方法调用
        verify(() => mockRepository.addProduct(testProduct)).called(1);
        verifyNever(() => mockRef.invalidate(allProductsProvider));
      });

      test('添加产品过程中应该显示 loading 状态', () async {
        // Arrange
        when(() => mockRepository.addProduct(any())).thenAnswer((_) async {
          // 在这个时候检查状态
          expect(controller.state.status, ProductOperationStatus.loading);
          return 1;
        });

        // Act & Assert
        await controller.addProduct(testProduct);
      });
    });

    group('updateProduct 测试', () {
      test('成功更新产品 - 应该更新状态为 success', () async {
        // Arrange
        when(
          () => mockRepository.updateProduct(any()),
        ).thenAnswer((_) async => true);

        // Act
        await controller.updateProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.success);
        expect(controller.state.lastOperatedProduct, testProduct);
        expect(controller.state.errorMessage, isNull);

        // 验证方法调用
        verify(() => mockRepository.updateProduct(testProduct)).called(1);
        verify(() => mockRef.invalidate(allProductsProvider)).called(1);
      });

      test('更新产品失败（返回 false）- 应该更新状态为 error', () async {
        // Arrange
        when(
          () => mockRepository.updateProduct(any()),
        ).thenAnswer((_) async => false);

        // Act
        await controller.updateProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains('未找到对应的产品记录'));
        expect(controller.state.lastOperatedProduct, isNull);

        // 验证方法调用
        verify(() => mockRepository.updateProduct(testProduct)).called(1);
        verifyNever(() => mockRef.invalidate(allProductsProvider));
      });

      test('更新产品异常 - 应该更新状态为 error', () async {
        // Arrange
        const errorMessage = '网络连接错误';
        when(
          () => mockRepository.updateProduct(any()),
        ).thenThrow(Exception(errorMessage));

        // Act
        await controller.updateProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains(errorMessage));
        expect(controller.state.lastOperatedProduct, isNull);
      });
      test('产品ID为空 - 应该立即返回错误状态', () async {
        // Arrange
        final productWithEmptyId = testProduct.copyWith(id: '');

        // Act
        await controller.updateProduct(productWithEmptyId);

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, '产品ID不能为空');

        // 验证不应该调用 repository
        verifyNever(() => mockRepository.updateProduct(any()));
        verifyNever(() => mockRef.invalidate(allProductsProvider));
      });
    });

    group('deleteProduct 测试', () {
      test('成功删除产品 - 应该更新状态为 success', () async {
        // Arrange
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 1);

        // Act
        await controller.deleteProduct('test-id-001');

        // Assert
        expect(controller.state.status, ProductOperationStatus.success);
        expect(controller.state.errorMessage, isNull);

        // 验证方法调用
        verify(() => mockRepository.deleteProduct('test-id-001')).called(1);
        verify(() => mockRef.invalidate(allProductsProvider)).called(1);
      });

      test('删除产品失败（返回 0）- 应该更新状态为 error', () async {
        // Arrange
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 0);

        // Act
        await controller.deleteProduct('non-existent-id');

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains('未找到对应的产品记录'));

        // 验证方法调用
        verify(() => mockRepository.deleteProduct('non-existent-id')).called(1);
        verifyNever(() => mockRef.invalidate(allProductsProvider));
      });

      test('删除产品异常 - 应该更新状态为 error', () async {
        // Arrange
        const errorMessage = '数据库锁定';
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenThrow(Exception(errorMessage));

        // Act
        await controller.deleteProduct('test-id-001');

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains(errorMessage));
      });
    });

    group('getProductById 测试', () {
      test('成功获取产品 - 应该返回产品对象', () async {
        // Arrange
        when(
          () => mockRepository.getProductById(any()),
        ).thenAnswer((_) async => testProduct);

        // Act
        final result = await controller.getProductById('test-id-001');

        // Assert
        expect(result, equals(testProduct));

        // 验证方法调用
        verify(() => mockRepository.getProductById('test-id-001')).called(1);

        // 状态不应该改变（除非出错）
        expect(controller.state.status, ProductOperationStatus.initial);
      });

      test('获取不存在的产品 - 应该返回 null', () async {
        // Arrange
        when(
          () => mockRepository.getProductById(any()),
        ).thenAnswer((_) async => null);

        // Act
        final result = await controller.getProductById('non-existent-id');

        // Assert
        expect(result, isNull);

        // 验证方法调用
        verify(
          () => mockRepository.getProductById('non-existent-id'),
        ).called(1);
      });

      test('获取产品异常 - 应该返回 null 并更新错误状态', () async {
        // Arrange
        const errorMessage = '数据库连接失败';
        when(
          () => mockRepository.getProductById(any()),
        ).thenThrow(Exception(errorMessage));

        // Act
        final result = await controller.getProductById('test-id-001');

        // Assert
        expect(result, isNull);
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains(errorMessage));
      });
    });

    group('状态管理测试', () {
      test('resetState - 应该重置状态为初始状态', () async {
        // Arrange - 先设置一个错误状态
        when(
          () => mockRepository.addProduct(any()),
        ).thenThrow(Exception('测试错误'));
        await controller.addProduct(testProduct);
        expect(controller.state.status, ProductOperationStatus.error);

        // Act
        controller.resetState();

        // Assert
        expect(controller.state.status, ProductOperationStatus.initial);
        expect(controller.state.errorMessage, isNull);
        expect(controller.state.lastOperatedProduct, isNull);
      });

      test('clearError - 应该清除错误状态', () async {
        // Arrange - 先设置一个错误状态
        when(
          () => mockRepository.addProduct(any()),
        ).thenThrow(Exception('测试错误'));
        await controller.addProduct(testProduct);
        expect(controller.state.status, ProductOperationStatus.error);

        // Act
        controller.clearError();

        // Assert
        expect(controller.state.status, ProductOperationStatus.initial);
        expect(controller.state.errorMessage, isNull);
      });

      test('clearError - 在非错误状态下不应该改变状态', () {
        // Arrange - 确保是初始状态
        expect(controller.state.status, ProductOperationStatus.initial);

        // Act
        controller.clearError();

        // Assert
        expect(controller.state.status, ProductOperationStatus.initial);
      });
    });

    group('状态变化测试', () {
      test('多个连续操作应该正确管理状态', () async {
        // 1. 添加产品成功
        when(() => mockRepository.addProduct(any())).thenAnswer((_) async => 1);

        await controller.addProduct(testProduct);
        expect(controller.state.status, ProductOperationStatus.success);

        // 2. 更新产品失败
        when(
          () => mockRepository.updateProduct(any()),
        ).thenAnswer((_) async => false);

        await controller.updateProduct(testProduct);
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains('未找到对应的产品记录'));

        // 3. 清除错误
        controller.clearError();
        expect(controller.state.status, ProductOperationStatus.initial);
        expect(controller.state.errorMessage, isNull);

        // 4. 删除产品成功
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 1);

        await controller.deleteProduct('test-id-001');
        expect(controller.state.status, ProductOperationStatus.success);
        expect(controller.state.errorMessage, isNull);
      });
    });

    group('边界情况测试', () {
      test('空字符串ID删除 - 应该处理正常', () async {
        // Arrange
        when(() => mockRepository.deleteProduct('')).thenAnswer((_) async => 0);

        // Act
        await controller.deleteProduct('');

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        verify(() => mockRepository.deleteProduct('')).called(1);
      });

      test('处理非常长的错误消息', () async {
        // Arrange
        final longErrorMessage = 'A' * 1000;
        when(
          () => mockRepository.addProduct(any()),
        ).thenThrow(Exception(longErrorMessage));

        // Act
        await controller.addProduct(testProduct);

        // Assert
        expect(controller.state.status, ProductOperationStatus.error);
        expect(controller.state.errorMessage, contains(longErrorMessage));
      });

      test('同时调用多个异步操作', () async {
        // Arrange
        when(() => mockRepository.addProduct(any())).thenAnswer((_) async => 1);
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 1);

        // Act - 同时触发多个操作
        final futures = [
          controller.addProduct(testProduct),
          controller.deleteProduct('test-id'),
        ];

        await Future.wait(futures);

        // Assert - 最后的状态应该是成功的
        expect(controller.state.status, ProductOperationStatus.success);
      });
    });

    group('Provider 集成测试', () {
      test('allProductsProvider 刷新应该被正确调用', () async {
        // Arrange
        when(() => mockRepository.addProduct(any())).thenAnswer((_) async => 1);
        when(
          () => mockRepository.updateProduct(any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 1);

        // Act - 执行会刷新 provider 的操作
        await controller.addProduct(testProduct);
        await controller.updateProduct(testProduct);
        await controller.deleteProduct('test-id-001');

        // Assert - 验证 invalidate 被调用了 3 次
        verify(() => mockRef.invalidate(allProductsProvider)).called(3);
      });

      test('失败操作不应该刷新 allProductsProvider', () async {
        // Arrange
        when(() => mockRepository.addProduct(any())).thenThrow(Exception('失败'));
        when(
          () => mockRepository.updateProduct(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockRepository.deleteProduct(any()),
        ).thenAnswer((_) async => 0);

        // Act - 执行失败的操作
        await controller.addProduct(testProduct);
        await controller.updateProduct(testProduct);
        await controller.deleteProduct('test-id-001');

        // Assert - 验证 invalidate 从未被调用
        verifyNever(() => mockRef.invalidate(allProductsProvider));
      });
    });
  });
}
