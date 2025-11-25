import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../data/dao/product_group_dao.dart';
import '../../domain/model/product_group.dart';

/// 商品组 DAO Provider
final productGroupDaoProvider = Provider<ProductGroupDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.productGroupDao;
});

/// 所有商品组列表 Provider
final allProductGroupsProvider = StreamProvider<List<ProductGroupData>>((ref) {
  final dao = ref.watch(productGroupDaoProvider);
  return dao.watchAllProductGroups();
});

/// 商品组操作状态
class ProductGroupOperationsState {
  final bool isLoading;
  final String? error;

  const ProductGroupOperationsState({
    this.isLoading = false,
    this.error,
  });

  ProductGroupOperationsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ProductGroupOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 商品组操作 Notifier
class ProductGroupOperationsNotifier extends StateNotifier<ProductGroupOperationsState> {
  final ProductGroupDao _dao;

  ProductGroupOperationsNotifier(this._dao) : super(const ProductGroupOperationsState());

  /// 创建商品组
  Future<int?> createProductGroup(ProductGroupModel model) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _dao.insertProductGroup(
        ProductGroupCompanion.insert(
          name: model.name,
          image: Value(model.image),
          description: Value(model.description),
        ),
      );
      state = state.copyWith(isLoading: false);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// 更新商品组
  Future<bool> updateProductGroup(ProductGroupModel model) async {
    if (model.id == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dao.updateProductGroup(
        ProductGroupCompanion(
          id: Value(model.id!),
          name: Value(model.name),
          image: Value(model.image),
          description: Value(model.description),
        ),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 删除商品组
  Future<bool> deleteProductGroup(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dao.deleteProductGroup(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final productGroupOperationsProvider =
    StateNotifierProvider<ProductGroupOperationsNotifier, ProductGroupOperationsState>((ref) {
  final dao = ref.watch(productGroupDaoProvider);
  return ProductGroupOperationsNotifier(dao);
});
