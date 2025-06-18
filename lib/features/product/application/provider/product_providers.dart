import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product.dart';
import '../../domain/repository/i_product_repository.dart';
import '../../data/repository/product_repository.dart';

/// 产品操作状态
enum ProductOperationStatus { initial, loading, success, error }

/// 产品控制器状态
class ProductControllerState {
  final ProductOperationStatus status;
  final String? errorMessage;
  final Product? lastOperatedProduct;

  const ProductControllerState({
    this.status = ProductOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedProduct,
  });

  ProductControllerState copyWith({
    ProductOperationStatus? status,
    String? errorMessage,
    Product? lastOperatedProduct,
  }) {
    return ProductControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedProduct: lastOperatedProduct ?? this.lastOperatedProduct,
    );
  }

  bool get isLoading => status == ProductOperationStatus.loading;
  bool get isError => status == ProductOperationStatus.error;
  bool get isSuccess => status == ProductOperationStatus.success;
}

/// 产品控制器 - 管理产品的增删改操作
class ProductController extends StateNotifier<ProductControllerState> {
  final IProductRepository _repository;
  final Ref _ref;

  ProductController(this._repository, this._ref)
    : super(const ProductControllerState());

  /// 添加产品
  Future<void> addProduct(Product product) async {
    state = state.copyWith(status: ProductOperationStatus.loading);

    try {
      await _repository.addProduct(product);
      state = state.copyWith(
        status: ProductOperationStatus.success,
        lastOperatedProduct: product,
        errorMessage: null,
      );

      // 刷新产品列表 - Stream会自动更新，但我们也可以主动刷新
      _ref.invalidate(allProductsProvider);
    } catch (e) {
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '添加产品失败: ${e.toString()}',
      );
    }
  }

  /// 更新产品
  Future<void> updateProduct(Product product) async {
    // 检查产品ID是否为空
    if (product.id.isEmpty) {
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '产品ID不能为空',
      );
      return;
    }

    state = state.copyWith(status: ProductOperationStatus.loading);

    try {
      final success = await _repository.updateProduct(product);
      if (success) {
        state = state.copyWith(
          status: ProductOperationStatus.success,
          lastOperatedProduct: product,
          errorMessage: null,
        );

        // 刷新产品列表
        _ref.invalidate(allProductsProvider);
      } else {
        state = state.copyWith(
          status: ProductOperationStatus.error,
          errorMessage: '更新产品失败：未找到对应的产品记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '更新产品失败: ${e.toString()}',
      );
    }
  }

  /// 删除产品
  Future<void> deleteProduct(String productId) async {
    print('🔥 开始删除产品，ID: $productId');
    state = state.copyWith(status: ProductOperationStatus.loading);

    try {
      print('🔥 调用仓储删除方法...');
      final deletedCount = await _repository.deleteProduct(productId);
      print('🔥 删除操作返回的影响行数: $deletedCount');

      if (deletedCount > 0) {
        print('🔥 删除成功，更新状态并刷新列表');
        state = state.copyWith(
          status: ProductOperationStatus.success,
          errorMessage: null,
        );

        // 强制刷新产品列表 - 确保UI更新
        print('🔥 第一次刷新产品列表...');
        _ref.invalidate(allProductsProvider);

        // 添加短暂延迟后再次刷新，确保数据库变更完全反映
        Future.delayed(const Duration(milliseconds: 100), () {
          print('🔥 延迟后第二次刷新产品列表...');
          _ref.invalidate(allProductsProvider);
        });
      } else {
        print('🔥 删除失败：没有找到对应的产品记录');
        state = state.copyWith(
          status: ProductOperationStatus.error,
          errorMessage: '删除产品失败：未找到对应的产品记录',
        );
      }
    } catch (e) {
      print('🔥 删除时发生异常: $e');
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '删除产品失败: ${e.toString()}',
      );
    }
  }

  /// 根据ID获取产品
  Future<Product?> getProductById(String productId) async {
    try {
      return await _repository.getProductById(productId);
    } catch (e) {
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '获取产品失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 根据条码获取产品
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _repository.getProductByBarcode(barcode);
    } catch (e) {
      state = state.copyWith(
        status: ProductOperationStatus.error,
        errorMessage: '根据条码查询产品失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 重置状态
  void resetState() {
    state = const ProductControllerState();
  }

  /// 清除错误状态
  void clearError() {
    if (state.isError) {
      state = state.copyWith(
        status: ProductOperationStatus.initial,
        errorMessage: null,
      );
    }
  }
}

/// 所有产品列表的StreamProvider
/// 监听产品数据的实时变化，当数据库中的产品发生变化时会自动更新UI
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);

  // 创建一个更可靠的Stream，结合定时刷新和数据库监听
  return repository.watchAllProducts().asBroadcastStream();
});

/// 产品控制器Provider
/// 管理产品的增删改操作状态
final productControllerProvider =
    StateNotifierProvider<ProductController, ProductControllerState>((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return ProductController(repository, ref);
    });
