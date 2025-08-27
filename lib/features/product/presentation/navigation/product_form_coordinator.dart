import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/category_notifier.dart';
import '../screens/category_selection_screen.dart';
import '../screens/unit_selection_screen.dart';
import '../screens/auxiliaryunit_edit_screen.dart';

/// 负责与路由相关的表单协调逻辑，避免在 Widget 中堆积导航与数据准备代码
class ProductFormCoordinator {
  const ProductFormCoordinator._();

  /// 选择类别
  static Future<CategoryModel?> chooseCategory(
    BuildContext context,
    WidgetRef ref, {
    int? selectedCategoryId,
  }) async {
    await ref.read(categoryListProvider.notifier).loadCategories();
    return Navigator.of(context).push<CategoryModel>(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          selectedCategoryId: selectedCategoryId,
          isSelectionMode: true,
        ),
      ),
    );
  }

  /// 选择单位
  static Future<Unit?> chooseUnit(
    BuildContext context,
    List<Unit> allUnits, {
    int? selectedUnitId,
  }) async {
    final initialUnit = selectedUnitId != null
        ? allUnits.firstWhere(
            (u) => u.id == selectedUnitId,
            orElse: () => Unit.empty(),
          )
        : Unit.empty();

    return Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(initialUnit: initialUnit),
      ),
    );
  }

  /// 编辑辅单位与条码配置，返回页面回传的数据（兼容 Map 或 List<UnitProduct>）
  static Future<dynamic> editAuxiliaryUnits(
    BuildContext context,
    WidgetRef ref, {
    int? productId,
    int? currentUnitId,
    required String currentUnitName,
  }) async {
    int? baseUnitId = currentUnitId;
    String baseUnitName = currentUnitName.trim();

    // 若未选单位但填了名称，尝试匹配已存在单位
    if (baseUnitId == null && baseUnitName.isNotEmpty) {
      try {
        final allUnits = await ref.read(allUnitsProvider.future);
        final existing = allUnits.where((u) =>
            u.name.toLowerCase() == baseUnitName.toLowerCase());
        if (existing.isNotEmpty) {
          baseUnitId = existing.first.id;
        }
      } catch (_) {
        // 忽略读取失败，继续以输入名称进入编辑页
      }
    }

    // 若名称为空，允许进入页面创建
    if (baseUnitName.isEmpty) {
      baseUnitName = '';
      baseUnitId = null;
    }

    return Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => AuxiliaryUnitEditScreen(
          productId: productId,
          baseUnitId: baseUnitId?.toString() ?? '0',
          baseUnitName: baseUnitName,
        ),
      ),
    );
  }
}
