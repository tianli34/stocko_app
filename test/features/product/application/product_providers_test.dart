import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/application/provider/product_providers.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/inventory/domain/model/batch.dart';

class _FakeRepo implements IProductRepository {
  final BehaviorSubject<List<ProductModel>> _controller = BehaviorSubject.seeded(const []);
  final List<ProductModel> _store = [];

  @override
  Future<int> addProduct(ProductModel product) async {
    final nextId = (_store.isEmpty ? 1 : (_store.last.id ?? 0) + 1);
    _store.add(product.copyWith(id: nextId));
  _controller.add(List.of(_store));
    return nextId;
  }

  @override
  Future<bool> updateProduct(ProductModel product) async {
    final idx = _store.indexWhere((p) => p.id == product.id);
    if (idx < 0) return false;
    _store[idx] = product;
  _controller.add(List.of(_store));
    return true;
  }

  @override
  Future<int> deleteProduct(int id) async {
    _store.removeWhere((p) => p.id == id);
  _controller.add(List.of(_store));
    return 1;
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    try {
      return _store.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<ProductModel>> watchAllProducts() => _controller.stream;

  @override
  Stream<List<({ProductModel product, int unitId, String unitName, int? wholesalePriceInCents})>>
      watchAllProductsWithUnit() =>
          _controller.stream.map((items) => items.map((p) => (
                product: p,
                unitId: p.baseUnitId,
                unitName: 'unit',
                wholesalePriceInCents: null,
              )).toList());

  @override
  Future<List<ProductModel>> getAllProducts() async => List.of(_store);

  @override
  Future<List<ProductModel>> getProductsByCondition({int? categoryId, String? status, String? keyword}) async =>
      _store.where((p) => keyword == null || p.name.contains(keyword)).toList();

  @override
  Stream<List<ProductModel>> watchProductsByCategory(int categoryId) =>
      _controller.stream.map((list) => list.where((p) => p.categoryId == categoryId).toList());

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async => null;

  @override
  Future<({ProductModel product, int unitId, String unitName, int? wholesalePriceInCents})?>
      getProductWithUnitByBarcode(String barcode) async => null;

  @override
  Future<bool> isUnitUsed(int unitId) async => false;

  @override
  Future<List<BatchModel>> getBatchesByProductAndShop(int productId, int shopId) async => [];

  // extras not in interface
  Future<void> addMultipleProducts(List<ProductModel> products) async {
    for (final p in products) {
      await addProduct(p);
    }
  }
}

void main() {
  group('product providers', () {
    late ProviderContainer container;
    late _FakeRepo repo;

    setUp(() {
      repo = _FakeRepo();
      container = ProviderContainer(overrides: [
        productRepositoryProvider.overrideWithValue(repo),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    ProductModel _p(String name, {int? id, int baseUnitId = 1, DateTime? lastUpdated}) =>
        ProductModel(
          id: id,
          name: name,
          baseUnitId: baseUnitId,
          lastUpdated: lastUpdated,
        );

    test('ProductOperationsNotifier addProduct updates list stream', () async {
      final notifier = container.read(productOperationsProvider.notifier);
      final state = container.read(allProductsProvider);
      expect(state.isLoading, true);

      await notifier.addProduct(_p('A'));

      final list = await container.read(allProductsProvider.future);
      expect(list.map((e) => e.name), contains('A'));
    });

    test('ProductListNotifier sorts by lastUpdated desc and moves latest to index 3 when length>3', () async {
      // start listening first to avoid missing initial events
      // ignore: unused_local_variable
      final sub = container.listen(allProductsProvider, (_, __) {});

      // seed 4 products with timestamps
      final now = DateTime.now();
      await repo.addMultipleProducts([
        _p('P1', lastUpdated: now.subtract(const Duration(days: 3))),
        _p('P2', lastUpdated: now.subtract(const Duration(days: 2))),
        _p('P3', lastUpdated: now.subtract(const Duration(days: 1))),
        _p('P4', lastUpdated: now), // latest
      ]);

      final list = await container.read(allProductsProvider.future);
      // after logic, latest product should be moved to index 3 (0-based)
      expect(list[3].name, 'P4');
    });
  });
}
