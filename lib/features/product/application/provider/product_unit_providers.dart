import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/repository/i_product_unit_repository.dart';
import '../../data/repository/product_unit_repository.dart';

/// 产品单位操作状态
enum ProductUnitOperationStatus { initial, loading, success, error }

/// 产品单位控制器状态
class ProductUnitControllerState {
  final ProductUnitOperationStatus status;
  final String? errorMessage;
  final List<UnitProduct>? lastOperatedProductUnits;

  const ProductUnitControllerState({
    this.status = ProductUnitOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedProductUnits,
  });

  ProductUnitControllerState copyWith({
    ProductUnitOperationStatus? status,
    String? errorMessage,
    List<UnitProduct>? lastOperatedProductUnits,
  }) {
    return ProductUnitControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedProductUnits:
          lastOperatedProductUnits ?? this.lastOperatedProductUnits,
    );
  }

  bool get isLoading => status == ProductUnitOperationStatus.loading;
  bool get isError => status == ProductUnitOperationStatus.error;
  bool get isSuccess => status == ProductUnitOperationStatus.success;
}

/// 产品单位控制器 - 管理产品单位的增删改操作
class ProductUnitController extends StateNotifier<ProductUnitControllerState> {
  final IProductUnitRepository _repository;
  final Ref _ref;

  ProductUnitController(this._repository, this._ref)
    : super(const ProductUnitControllerState());

  /// 添加产品单位
  Future<void> addProductUnit(UnitProduct unitProduct) async {
    state = state.copyWith(status: ProductUnitOperationStatus.loading);

    try {
      await _repository.addProductUnit(unitProduct);
      state = state.copyWith(
        status: ProductUnitOperationStatus.success,
        lastOperatedProductUnits: [unitProduct],
        errorMessage: null,
      );

      // 刷新相关的Provider
      _ref.invalidate(productUnitsProvider(unitProduct.productId));
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '添加产品单位失败: ${e.toString()}',
      );
    }
  }

  /// 批量添加产品单位
  Future<void> addMultipleProductUnits(List<UnitProduct> productUnits) async {
    if (productUnits.isEmpty) return;

    state = state.copyWith(status: ProductUnitOperationStatus.loading);

    try {
      await _repository.addMultipleProductUnits(productUnits);
      state = state.copyWith(
        status: ProductUnitOperationStatus.success,
        lastOperatedProductUnits: productUnits,
        errorMessage: null,
      );

      // 刷新相关的Provider
      final productIds = productUnits.map((pu) => pu.productId).toSet();
      for (final productId in productIds) {
        _ref.invalidate(productUnitsProvider(productId));
      }
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '批量添加产品单位失败: ${e.toString()}',
      );
    }
  }

  /// 更新产品单位
  Future<void> updateProductUnit(UnitProduct unitProduct) async {
    state = state.copyWith(status: ProductUnitOperationStatus.loading);

    try {
      final success = await _repository.updateProductUnit(unitProduct);
      if (success) {
        state = state.copyWith(
          status: ProductUnitOperationStatus.success,
          lastOperatedProductUnits: [unitProduct],
          errorMessage: null,
        );

        // 刷新相关的Provider
        _ref.invalidate(productUnitsProvider(unitProduct.productId));
      } else {
        state = state.copyWith(
          status: ProductUnitOperationStatus.error,
          errorMessage: '更新产品单位失败：未找到对应的记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '更新产品单位失败: ${e.toString()}',
      );
    }
  }

  /// 删除产品单位
  Future<void> deleteProductUnit(int id, int productId) async {
    state = state.copyWith(status: ProductUnitOperationStatus.loading);

    try {
      final deletedCount = await _repository.deleteProductUnit(id);
      if (deletedCount > 0) {
        state = state.copyWith(
          status: ProductUnitOperationStatus.success,
          errorMessage: null,
        );

        // 刷新相关的Provider
        _ref.invalidate(productUnitsProvider(productId));
      } else {
        state = state.copyWith(
          status: ProductUnitOperationStatus.error,
          errorMessage: '删除产品单位失败：未找到对应的记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '删除产品单位失败: ${e.toString()}',
      );
    }
  }

  /// 替换产品的所有单位配置
  Future<void> replaceProductUnits(
    int productId,
    List<UnitProduct> productUnits,
  ) async {
    print('🎯 ProductUnitController.replaceProductUnits - 开始替换产品单位配置');
    print('🎯 产品ID: $productId');
    print('🎯 单位数量: ${productUnits.length}');
    for (int i = 0; i < productUnits.length; i++) {
      final unit = productUnits[i];
      print('🎯   [$i] 单位ID: ${unit.unitId}, 换算率: ${unit.conversionRate}');
    }
    
    state = state.copyWith(status: ProductUnitOperationStatus.loading);

    try {
      print('💾 调用仓储层替换方法...');
      await _repository.replaceProductUnits(productId, productUnits);
      print('✅ 仓储层替换成功');
      
      state = state.copyWith(
        status: ProductUnitOperationStatus.success,
        lastOperatedProductUnits: productUnits,
        errorMessage: null,
      );

      // 刷新相关的Provider
      print('🔄 刷新产品单位列表...');
      _ref.invalidate(productUnitsProvider(productId));
      print('✅ ProductUnitController.replaceProductUnits - 替换产品单位配置完成');
    } catch (e) {
      print('❌ ProductUnitController.replaceProductUnits - 替换失败: $e');
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '替换产品单位配置失败: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 根据产品ID获取产品单位
  Future<List<UnitProduct>> getProductUnitsByProductId(int productId) async {
    try {
      return await _repository.getProductUnitsByProductId(productId);
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '获取产品单位失败: ${e.toString()}',
      );
      return [];
    }
  }

  /// 获取产品的基础单位
  Future<UnitProduct?> getBaseUnitForProduct(int productId) async {
    try {
      return await _repository.getBaseUnitForProduct(productId);
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '获取产品基础单位失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 检查产品是否已配置某个单位
  Future<bool> isUnitConfiguredForProduct(
    int productId,
    int unitId,
  ) async {
    try {
      return await _repository.isUnitConfiguredForProduct(productId, unitId);
    } catch (e) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.error,
        errorMessage: '检查产品单位配置失败: ${e.toString()}',
      );
      return false;
    }
  }

  /// 重置状态
  void resetState() {
    state = const ProductUnitControllerState();
  }

  /// 清除错误状态
  void clearError() {
    if (state.isError) {
      state = state.copyWith(
        status: ProductUnitOperationStatus.initial,
        errorMessage: null,
      );
    }
  }
}

/// 根据产品ID获取产品单位列表的StreamProvider
final productUnitsProvider = StreamProvider.family<List<UnitProduct>, int>((
  ref,
  productId,
) {
  final repository = ref.watch(productUnitRepositoryProvider);
  return repository.watchProductUnitsByProductId(productId);
});

/// 产品单位控制器Provider
final productUnitControllerProvider =
    StateNotifierProvider<ProductUnitController, ProductUnitControllerState>((
      ref,
    ) {
      final repository = ref.watch(productUnitRepositoryProvider);
      return ProductUnitController(repository, ref);
    });

/// 根据产品ID获取基础单位的FutureProvider
final baseUnitProvider = FutureProvider.family<UnitProduct?, int>((
  ref,
  productId,
) {
  final repository = ref.watch(productUnitRepositoryProvider);
  return repository.getBaseUnitForProduct(productId);
});

/// 根据产品单位ID获取产品单位的FutureProvider
final productUnitByIdProvider = FutureProvider.family<UnitProduct?, int>((
  ref,
  unitProductId,
) {
  final repository = ref.watch(productUnitRepositoryProvider);
  return repository.getProductUnitById(unitProductId);
});
