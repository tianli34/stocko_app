import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../product/application/category_notifier.dart';
import '../../application/provider/stocktake_providers.dart';
import '../../domain/model/stocktake_status.dart';

/// 创建盘点单页面
class CreateStocktakeScreen extends ConsumerWidget {
  const CreateStocktakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStocktakeNotifierProvider);
    final notifier = ref.read(createStocktakeNotifierProvider.notifier);
    final shopsAsync = ref.watch(allShopsProvider);
    final categoriesState = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建盘点'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店铺选择
            const Text(
              '选择店铺',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            shopsAsync.when(
              data: (shops) => DropdownButtonFormField<int>(
                value: state.shopId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请选择店铺',
                ),
                items: shops
                    .map((shop) => DropdownMenuItem(
                          value: shop.id,
                          child: Text(shop.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) notifier.setShopId(value);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('加载店铺失败'),
            ),
            const SizedBox(height: 24),

            // 盘点类型
            const Text(
              '盘点类型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    title: '全盘',
                    subtitle: '盘点所有商品',
                    icon: Icons.select_all,
                    isSelected: state.type == StocktakeType.full,
                    onTap: () => notifier.setType(StocktakeType.full),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    title: '部分盘点',
                    subtitle: '按分类盘点',
                    icon: Icons.category,
                    isSelected: state.type == StocktakeType.partial,
                    onTap: () => notifier.setType(StocktakeType.partial),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 分类选择（部分盘点时显示）
            if (state.type == StocktakeType.partial) ...[
              const Text(
                '选择分类',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              categoriesState.isLoading
                  ? const LinearProgressIndicator()
                  : categoriesState.error != null
                      ? const Text('加载分类失败')
                      : DropdownButtonFormField<int>(
                          value: state.categoryId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '请选择分类',
                          ),
                          items: categoriesState.categories
                              .map((cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ))
                              .toList(),
                          onChanged: (value) => notifier.setCategoryId(value),
                        ),
              const SizedBox(height: 24),
            ],

            // 备注
            const Text(
              '备注（可选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入备注信息',
              ),
              maxLines: 3,
              onChanged: notifier.setRemarks,
            ),
            const SizedBox(height: 32),

            // 错误提示
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // 创建按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final order = await notifier.createStocktake();
                        if (order != null && context.mounted) {
                          notifier.reset();
                          context.pushReplacement('/stocktake/${order.id}/entry');
                        }
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('开始盘点'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
