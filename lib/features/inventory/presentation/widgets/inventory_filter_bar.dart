import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_query_providers.dart';
import '../../application/provider/shop_providers.dart';
import '../../../product/application/category_service.dart';
import '../../../../config/flavor_config.dart';

/// 分类流提供者
final categoriesStreamProvider = StreamProvider((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
});

/// 库存筛选栏
/// 提供仓库、分类、库存状态等筛选选项
class InventoryFilterBar extends ConsumerWidget {
  const InventoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(inventoryFilterProvider);
    final shopsAsync = ref.watch(allShopsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final flavor = ref.watch(flavorConfigProvider).flavor;
    final isGeneric = flavor == AppFlavor.generic;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 所有仓库筛选 - 使用店铺表数据
          if (!isGeneric)
            Expanded(
              child: shopsAsync.when(
                data: (shops) {
                  // 构建店铺下拉选项
                  final shopItems = ['所有仓库', ...shops.map((shop) => shop.name)];
                  return _buildFilterDropdown(
                    context: context,
                    value: filterState.selectedShop,
                    items: shopItems,
                    onChanged: (value) {
                      ref
                          .read(inventoryFilterProvider.notifier)
                          .updateShop(value);
                    },
                  );
                },
                loading: () => _buildFilterDropdown(
                  context: context,
                  value: '所有仓库',
                  items: const ['所有仓库'],
                  onChanged: (_) {}, // 加载时禁用
                ),
                error: (error, stackTrace) => _buildFilterDropdown(
                  context: context,
                  value: '所有仓库',
                  items: const ['所有仓库'],
                  onChanged: (_) {}, // 错误时禁用
                ),
              ),
            ),
          if (!isGeneric) const SizedBox(width: 12),

          // 所有分类筛选
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final categoryItems = ['所有分类', ...categories.map((cat) => cat.name)];
                return _buildFilterDropdown(
                  context: context,
                  value: filterState.selectedCategory,
                  items: categoryItems,
                  onChanged: (value) {
                    ref
                        .read(inventoryFilterProvider.notifier)
                        .updateCategory(value);
                  },
                );
              },
              loading: () => _buildFilterDropdown(
                context: context,
                value: '所有分类',
                items: const ['所有分类'],
                onChanged: (_) {},
              ),
              error: (error, stackTrace) => _buildFilterDropdown(
                context: context,
                value: '所有分类',
                items: const ['所有分类'],
                onChanged: (_) {},
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 库存状态筛选
          Expanded(
            child: _buildFilterDropdown(
              context: context,
              value: filterState.selectedStatus,
              items: const ['库存状态', '正常', '低库存', '缺货'],
              onChanged: (value) {
                ref.read(inventoryFilterProvider.notifier).updateStatus(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : items.first,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
          ),
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
