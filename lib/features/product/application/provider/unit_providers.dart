import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/unit.dart';
import '../../domain/repository/i_unit_repository.dart';
import '../../data/repository/unit_repository.dart';

/// 单位操作状态
enum UnitOperationStatus { initial, loading, success, error }

/// 单位控制器状态
class UnitControllerState {
  final UnitOperationStatus status;
  final String? errorMessage;
  final Unit? lastOperatedUnit;

  const UnitControllerState({
    this.status = UnitOperationStatus.initial,
    this.errorMessage,
    this.lastOperatedUnit,
  });

  UnitControllerState copyWith({
    UnitOperationStatus? status,
    String? errorMessage,
    Unit? lastOperatedUnit,
  }) {
    return UnitControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastOperatedUnit: lastOperatedUnit ?? this.lastOperatedUnit,
    );
  }

  bool get isLoading => status == UnitOperationStatus.loading;
  bool get isError => status == UnitOperationStatus.error;
  bool get isSuccess => status == UnitOperationStatus.success;
}

/// 单位控制器 - 管理单位的增删改操作
class UnitController extends StateNotifier<UnitControllerState> {
  final IUnitRepository _repository;
  final Ref _ref;

  UnitController(this._repository, this._ref)
    : super(const UnitControllerState());

  /// 添加单位
  Future<void> addUnit(Unit unit) async {
    print('🎯 UnitController.addUnit - 开始添加单位: ID=${unit.id}, 名称="${unit.name}"');
    state = state.copyWith(status: UnitOperationStatus.loading);

    try {
      // 检查单位名称是否为空
      if (unit.name.trim().isEmpty) {
        print('❌ 单位名称为空');
        throw Exception('单位名称不能为空');
      }

      // 检查单位名称是否已存在
      print('🔍 检查单位名称是否已存在: "${unit.name.trim()}"');
      final existingUnit = await _repository.getUnitByName(unit.name.trim());
      if (existingUnit != null) {
        print('❌ 单位名称已存在: ${existingUnit.id}');
        throw Exception('单位名称已存在');
      }
      print('✅ 单位名称检查通过');

      print('💾 调用仓储层添加单位...');
      await _repository.addUnit(unit);
      print('✅ 仓储层添加单位成功');
      
      state = state.copyWith(
        status: UnitOperationStatus.success,
        lastOperatedUnit: unit,
        errorMessage: null,
      );

      // 刷新单位列表 - Stream会自动更新，但我们也可以主动刷新
      print('🔄 刷新单位列表...');
      _ref.invalidate(allUnitsProvider);
      print('✅ UnitController.addUnit - 添加单位完成');
    } catch (e) {
      print('❌ UnitController.addUnit - 添加单位失败: $e');
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '添加单位失败: ${e.toString()}',
      );
      rethrow; // 重新抛出异常，让调用方可以处理
    }
  }

  /// 更新单位
  Future<void> updateUnit(Unit unit) async {
    // 检查单位ID是否为空
    if (unit.id.isEmpty) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '单位ID不能为空',
      );
      return;
    }

    state = state.copyWith(status: UnitOperationStatus.loading);

    try {
      final success = await _repository.updateUnit(unit);
      if (success) {
        state = state.copyWith(
          status: UnitOperationStatus.success,
          lastOperatedUnit: unit,
          errorMessage: null,
        );

        // 刷新单位列表
        _ref.invalidate(allUnitsProvider);
      } else {
        state = state.copyWith(
          status: UnitOperationStatus.error,
          errorMessage: '更新单位失败：未找到对应的单位记录',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '更新单位失败: ${e.toString()}',
      );
    }
  }

  /// 删除单位
  Future<void> deleteUnit(String unitId) async {
    print('🔥 开始删除单位，ID: $unitId');
    state = state.copyWith(status: UnitOperationStatus.loading);

    try {
      print('🔥 调用仓储删除方法...');
      final deletedCount = await _repository.deleteUnit(unitId);
      print('🔥 删除操作返回的影响行数: $deletedCount');

      if (deletedCount > 0) {
        print('🔥 删除成功，更新状态并刷新列表');
        state = state.copyWith(
          status: UnitOperationStatus.success,
          errorMessage: null,
        );

        // 强制刷新单位列表 - 确保UI更新
        print('🔥 第一次刷新单位列表...');
        _ref.invalidate(allUnitsProvider);

        // 添加短暂延迟后再次刷新，确保数据库变更完全反映
        Future.delayed(const Duration(milliseconds: 100), () {
          print('🔥 延迟后第二次刷新单位列表...');
          _ref.invalidate(allUnitsProvider);
        });
      } else {
        print('🔥 删除失败：没有找到对应的单位记录');
        state = state.copyWith(
          status: UnitOperationStatus.error,
          errorMessage: '删除单位失败：未找到对应的单位记录',
        );
      }
    } catch (e) {
      print('🔥 删除时发生异常: $e');
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '删除单位失败: ${e.toString()}',
      );
    }
  }

  /// 根据ID获取单位
  Future<Unit?> getUnitById(String unitId) async {
    try {
      return await _repository.getUnitById(unitId);
    } catch (e) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '获取单位失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 根据名称获取单位
  Future<Unit?> getUnitByName(String name) async {
    try {
      return await _repository.getUnitByName(name);
    } catch (e) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '根据名称获取单位失败: ${e.toString()}',
      );
      return null;
    }
  }

  /// 检查单位名称是否已存在
  Future<bool> isUnitNameExists(String name, [String? excludeId]) async {
    try {
      return await _repository.isUnitNameExists(name, excludeId);
    } catch (e) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '检查单位名称失败: ${e.toString()}',
      );
      return false;
    }
  }

  /// 插入默认单位
  Future<void> insertDefaultUnits() async {
    state = state.copyWith(status: UnitOperationStatus.loading);

    try {
      await _repository.insertDefaultUnits();
      state = state.copyWith(
        status: UnitOperationStatus.success,
        errorMessage: null,
      );

      // 刷新单位列表
      _ref.invalidate(allUnitsProvider);
    } catch (e) {
      state = state.copyWith(
        status: UnitOperationStatus.error,
        errorMessage: '插入默认单位失败: ${e.toString()}',
      );
    }
  }

  /// 重置状态
  void resetState() {
    state = const UnitControllerState();
  }

  /// 清除错误状态
  void clearError() {
    if (state.isError) {
      state = state.copyWith(
        status: UnitOperationStatus.initial,
        errorMessage: null,
      );
    }
  }
}

/// 所有单位列表的StreamProvider
/// 监听单位数据的实时变化，当数据库中的单位发生变化时会自动更新UI
final allUnitsProvider = StreamProvider<List<Unit>>((ref) {
  final repository = ref.watch(unitRepositoryProvider);
  return repository.watchAllUnits().asBroadcastStream();
});

/// 单位控制器Provider
/// 管理单位的增删改操作状态
final unitControllerProvider =
    StateNotifierProvider<UnitController, UnitControllerState>((ref) {
      final repository = ref.watch(unitRepositoryProvider);
      return UnitController(repository, ref);
    });
