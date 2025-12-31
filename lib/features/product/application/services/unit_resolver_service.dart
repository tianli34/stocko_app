// lib/features/product/application/services/unit_resolver_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger/product_logger.dart';
import '../../domain/model/unit.dart';
import '../provider/unit_providers.dart';

/// 单位解析服务
/// 
/// 负责解析或创建单位，返回 unitId
class UnitResolverService {
  final Ref _ref;

  UnitResolverService(this._ref);

  /// 解析单位ID
  /// 
  /// 如果 [selectedUnitId] 不为空，直接返回
  /// 如果 [newUnitName] 不为空，查找或创建单位
  /// 
  /// 返回单位ID，如果无法解析则返回 null
  Future<int?> resolve({
    int? selectedUnitId,
    String newUnitName = '',
  }) async {
    ProductLogger.debug(
      '开始解析单位: selectedId=$selectedUnitId, newName="$newUnitName"',
      tag: 'UnitResolver',
    );

    // 如果已选择单位，直接返回
    if (selectedUnitId != null) {
      ProductLogger.debug('使用已选择的单位ID: $selectedUnitId', tag: 'UnitResolver');
      return selectedUnitId;
    }

    // 如果没有新单位名称，返回 null
    final trimmedName = newUnitName.trim();
    if (trimmedName.isEmpty) {
      ProductLogger.debug('无单位信息，返回 null', tag: 'UnitResolver');
      return null;
    }

    // 查找或创建单位
    return _findOrCreateUnit(trimmedName);
  }

  /// 查找或创建单位
  Future<int?> _findOrCreateUnit(String unitName) async {
    ProductLogger.debug('查找或创建单位: "$unitName"', tag: 'UnitResolver');

    // 获取现有单位列表
    final units = _ref
        .read(allUnitsProvider)
        .maybeWhen(data: (u) => u, orElse: () => <Unit>[]);

    // 查找是否已存在
    Unit? existingUnit;
    existingUnit = units
        .where((u) => u.name.toLowerCase() == unitName.toLowerCase())
        .firstOrNull;

    if (existingUnit != null) {
      ProductLogger.debug(
        '找到已存在的单位: ID=${existingUnit.id}',
        tag: 'UnitResolver',
      );
      return existingUnit.id;
    }

    // 创建新单位
    ProductLogger.debug('创建新单位: "$unitName"', tag: 'UnitResolver');
    final unitCtrl = _ref.read(unitControllerProvider.notifier);
    final newUnit = await unitCtrl.addUnit(Unit(name: unitName));

    ProductLogger.debug('新单位创建成功: ID=${newUnit.id}', tag: 'UnitResolver');

    return newUnit.id;
  }
}

/// UnitResolverService Provider
final unitResolverServiceProvider = Provider<UnitResolverService>((ref) {
  return UnitResolverService(ref);
});
