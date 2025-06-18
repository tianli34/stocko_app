import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product_unit.dart';

/// 单位编辑草稿状态
class UnitEditDraftState {
  final Map<String, List<ProductUnit>> drafts;

  const UnitEditDraftState({this.drafts = const {}});

  UnitEditDraftState copyWith({Map<String, List<ProductUnit>>? drafts}) {
    return UnitEditDraftState(drafts: drafts ?? this.drafts);
  }
}

/// 单位编辑草稿状态管理器
class UnitEditDraftNotifier extends StateNotifier<UnitEditDraftState> {
  UnitEditDraftNotifier() : super(const UnitEditDraftState());

  /// 保存草稿
  void saveDraft(String productId, List<ProductUnit> units) {
    final newDrafts = Map<String, List<ProductUnit>>.from(state.drafts);
    newDrafts[productId] = units;
    state = state.copyWith(drafts: newDrafts);
  }

  /// 获取草稿
  List<ProductUnit>? getDraft(String productId) {
    return state.drafts[productId];
  }

  /// 清除草稿
  void clearDraft(String productId) {
    final newDrafts = Map<String, List<ProductUnit>>.from(state.drafts);
    newDrafts.remove(productId);
    state = state.copyWith(drafts: newDrafts);
  }

  /// 清除所有草稿
  void clearAllDrafts() {
    state = const UnitEditDraftState();
  }
}

/// 单位编辑草稿状态提供者
final unitEditDraftProvider =
    StateNotifierProvider<UnitEditDraftNotifier, UnitEditDraftState>((ref) {
      return UnitEditDraftNotifier();
    });
