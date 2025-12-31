// lib/features/product/application/services/product_group_resolver_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger/product_logger.dart';
import '../../domain/model/product_group.dart';
import '../provider/product_group_providers.dart';

/// 商品组解析服务
/// 
/// 负责解析或创建商品组，返回 groupId
class ProductGroupResolverService {
  final Ref _ref;

  ProductGroupResolverService(this._ref);

  /// 解析或创建商品组
  /// 
  /// 如果 [groupId] 不为空，直接返回
  /// 如果 [groupName] 不为空，验证唯一性并创建新商品组
  /// 
  /// 返回商品组ID，如果无法解析则返回 null
  /// 如果名称已存在，抛出异常
  Future<int?> resolveOrCreate({
    int? groupId,
    String groupName = '',
  }) async {
    ProductLogger.debug(
      '开始解析商品组: groupId=$groupId, groupName="$groupName"',
      tag: 'ProductGroupResolver',
    );

    // 如果已选择商品组，直接返回
    if (groupId != null) {
      ProductLogger.debug('使用已选择的商品组ID: $groupId', tag: 'ProductGroupResolver');
      return groupId;
    }

    // 如果没有商品组名称，返回 null
    final trimmedName = groupName.trim();
    if (trimmedName.isEmpty) {
      ProductLogger.debug('无商品组信息，返回 null', tag: 'ProductGroupResolver');
      return null;
    }

    // 验证名称唯一性
    final existingGroups = await _ref.read(allProductGroupsProvider.future);
    final nameExists = existingGroups.any(
      (g) => g.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (nameExists) {
      ProductLogger.warning(
        '商品组名称已存在: "$trimmedName"',
        tag: 'ProductGroupResolver',
      );
      throw Exception('商品组名称"$trimmedName"已存在，请选择已有商品组或使用其他名称');
    }

    // 创建新商品组
    ProductLogger.debug('创建新商品组: "$trimmedName"', tag: 'ProductGroupResolver');
    final groupModel = ProductGroupModel(name: trimmedName);
    final newGroupId = await _ref
        .read(productGroupOperationsProvider.notifier)
        .createProductGroup(groupModel);

    if (newGroupId == null) {
      ProductLogger.error('创建商品组失败', tag: 'ProductGroupResolver');
      throw Exception('创建商品组失败');
    }

    ProductLogger.debug('新商品组创建成功: ID=$newGroupId', tag: 'ProductGroupResolver');
    return newGroupId;
  }
}

/// ProductGroupResolverService Provider
final productGroupResolverServiceProvider = Provider<ProductGroupResolverService>((ref) {
  return ProductGroupResolverService(ref);
});
