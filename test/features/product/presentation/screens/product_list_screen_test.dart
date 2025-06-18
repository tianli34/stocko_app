import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';
import 'package:stocko_app/features/product/application/provider/product_providers.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/presentation/screens/product_list_screen.dart';

// Mock repository for testing
class FakeProductRepository implements IProductRepository {
  final List<Product> _products;
  final bool _shouldThrow;

  FakeProductRepository({List<Product>? products, bool shouldThrow = false})
    : _products = products ?? [],
      _shouldThrow = shouldThrow;

  @override
  Stream<List<Product>> watchAllProducts() {
    if (_shouldThrow) {
      return Stream.error(Exception('Network error'));
    }
    return Stream.value(_products);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    if (_shouldThrow) throw Exception('Network error');
    return _products;
  }

  @override
  Future<int> addProduct(Product product) async {
    if (_shouldThrow) throw Exception('Network error');
    final newProduct = product.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _products.add(newProduct);
    return 1;
  }

  @override
  Future<bool> updateProduct(Product product) async {
    if (_shouldThrow) throw Exception('Network error');
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      return true;
    }
    return false;
  }

  @override
  Future<int> deleteProduct(String id) async {
    if (_shouldThrow) throw Exception('Network error');
    final oldLength = _products.length;
    _products.removeWhere((p) => p.id == id);
    return oldLength - _products.length;
  }

  @override
  Future<Product?> getProductById(String id) async {
    if (_shouldThrow) throw Exception('Network error');
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Product>> getProductsByCondition({
    String? categoryId,
    String? status,
    String? keyword,
  }) async {
    if (_shouldThrow) throw Exception('Network error');

    var filteredProducts = _products.where((product) {
      bool matches = true;

      if (categoryId != null) {
        matches = matches && product.categoryId == categoryId;
      }

      if (status != null) {
        matches = matches && product.status == status;
      }
      if (keyword != null && keyword.isNotEmpty) {
        matches =
            matches &&
            (product.name.toLowerCase().contains(keyword.toLowerCase()) ||
                (product.barcode?.toLowerCase().contains(
                      keyword.toLowerCase(),
                    ) ??
                    false) ||
                (product.sku?.toLowerCase().contains(keyword.toLowerCase()) ??
                    false));
      }

      return matches;
    });

    return filteredProducts.toList();
  }

  @override
  Stream<List<Product>> watchProductsByCategory(String categoryId) {
    if (_shouldThrow) {
      return Stream.error(Exception('Network error'));
    }

    final filteredProducts = _products
        .where((product) => product.categoryId == categoryId)
        .toList();

    return Stream.value(filteredProducts);
  }
}

void main() {
  const testProducts = [
    Product(
      id: '1',
      name: 'Product A',
      barcode: '111',
      sku: 'SKU-A',
      retailPrice: 10.0,
      enableBatchManagement: false,
      status: 'active',
    ),
    Product(
      id: '2',
      name: 'Product B',
      barcode: '222',
      sku: 'SKU-B',
      retailPrice: 20.0,
      enableBatchManagement: true,
      status: 'inactive',
    ),
  ];

  group('ProductListScreen Tests', () {
    testWidgets('shows loading widget when products are loading', (
      tester,
    ) async {
      // 创建一个永远不会完成的流来模拟加载状态
      final loadingController = StreamController<List<Product>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: const []),
            ),
            allProductsProvider.overrideWith((ref) => loadingController.stream),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );

      await tester.pump();
      // Check for CircularProgressIndicator in LoadingWidget
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载产品列表中...'), findsOneWidget);
    });
    testWidgets('shows empty state when no products are available', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: const []),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream.value(<Product>[]),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('暂无产品数据'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
    testWidgets('shows list of products when data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: testProducts),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream.value(testProducts),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify products are displayed
      expect(find.text('Product A'), findsOneWidget);
      expect(find.text('Product B'), findsOneWidget);

      // Verify product cards/tiles are displayed
      expect(find.byType(Card), findsAtLeastNWidgets(testProducts.length));
    });
    testWidgets('shows error widget when loading products fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(shouldThrow: true),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream<List<Product>>.error(Exception('Network error')),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('加载产品列表失败'), findsOneWidget);
      // Look for retry button with specific text
      expect(find.text('重试'), findsOneWidget);
    });
    testWidgets(
      'shows loading progress indicator when controller is in loading state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWith(
                (ref) => FakeProductRepository(products: testProducts),
              ),
              allProductsProvider.overrideWith(
                (ref) => Stream.value(testProducts),
              ),
              productControllerProvider.overrideWith((ref) {
                final controller = ProductController(
                  FakeProductRepository(),
                  ref,
                );
                // Force the state to loading after creation
                controller.state = const ProductControllerState(
                  status: ProductOperationStatus.loading,
                );
                return controller;
              }),
            ],
            child: const MaterialApp(home: ProductListScreen()),
          ),
        );

        await tester.pump();
        // Check for LinearProgressIndicator at the top of the screen
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );
    testWidgets(
      'navigates to add product screen when AppBar action is tapped',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWith(
                (ref) => FakeProductRepository(products: testProducts),
              ),
              allProductsProvider.overrideWith(
                (ref) => Stream.value(testProducts),
              ),
            ],
            child: const MaterialApp(home: ProductListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Find and tap the add button in AppBar
        final addButton = find.byIcon(Icons.add);
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
      },
    );
    testWidgets('can refresh the product list using RefreshIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: testProducts),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream.value(testProducts),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the RefreshIndicator and trigger a refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });
    testWidgets('shows retry button on error and allows retry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(shouldThrow: true),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream<List<Product>>.error(Exception('Network error')),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle(); // Verify error state
      expect(find.text('加载产品列表失败'), findsOneWidget);

      // Look for the retry button text
      final retryButton = find.text('重试');
      expect(retryButton, findsOneWidget);

      // Tap retry button
      await tester.tap(retryButton);
      await tester.pump();
    });
    testWidgets('displays correct product information in list tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: testProducts),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream.value(testProducts),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check for product names
      expect(find.text('Product A'), findsOneWidget);
      expect(find.text('Product B'), findsOneWidget);

      // Check for SKU information
      expect(find.text('SKU-A'), findsOneWidget);
      expect(find.text('SKU-B'), findsOneWidget);
    });
    testWidgets('handles product tile tap actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWith(
              (ref) => FakeProductRepository(products: testProducts),
            ),
            allProductsProvider.overrideWith(
              (ref) => Stream.value(testProducts),
            ),
          ],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap on a product card
      final productCard = find.byType(Card).first;
      expect(productCard, findsOneWidget);
      await tester.tap(productCard);
      await tester.pumpAndSettle();
    });
  });
}
