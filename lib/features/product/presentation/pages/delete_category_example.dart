import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../application/category_sample_data_service.dart';
import '../screens/category_selection_screen.dart';

/// 删除类别功能演示页面
class DeleteCategoryExamplePage extends ConsumerWidget {
  const DeleteCategoryExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('删除类别功能演示'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final sampleDataService = ref.read(
                categorySampleDataServiceProvider,
              );

              if (value == 'create_sample') {
                try {
                  await sampleDataService.createSampleCategories();
                  ToastService.success('✅ 示例数据创建成功');
                } catch (e) {
                  ToastService.error('❌ 创建示例数据失败: $e');
                }
              } else if (value == 'clear_all') {
                try {
                  await sampleDataService.clearAllCategories();
                  ToastService.success('✅ 所有数据已清除');
                } catch (e) {
                  ToastService.error('❌ 清除数据失败: $e');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_sample',
                child: Text('创建示例数据'),
              ),
              const PopupMenuItem(value: 'clear_all', child: Text('清除所有数据')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '删除类别功能说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('该功能提供两种删除模式：'),
                    SizedBox(height: 8),
                    Text('1. 仅删除当前类别：保留子类别和关联产品'),
                    Text('   • 子类别将转移到上级类别或成为根类别'),
                    Text('   • 产品将转移到上级类别或取消类别关联'),
                    SizedBox(height: 8),
                    Text('2. 级联删除：删除类别及所有关联内容'),
                    Text('   • 递归删除所有子类别'),
                    Text('   • 删除所有关联产品'),
                    Text('   • 此操作不可恢复'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategorySelectionScreen(
                            isSelectionMode: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.category),
                    label: const Text('打开类别管理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '使用说明：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. 点击"创建示例数据"按钮创建测试类别'),
            const Text('2. 点击"打开类别管理"进入类别管理界面'),
            const Text('3. 在类别右侧的菜单中选择"删除"'),
            const Text('4. 在弹出的对话框中选择删除模式'),
            const Text('5. 确认删除操作'),
            const Spacer(),
            const Text(
              '注意：请先创建示例数据以便测试删除功能',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
