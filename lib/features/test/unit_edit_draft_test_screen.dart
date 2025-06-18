import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product/domain/model/product_unit.dart';
import '../product/presentation/screens/unit_edit_screen.dart';

/// 单位编辑草稿功能测试页面
class UnitEditDraftTestScreen extends ConsumerWidget {
  const UnitEditDraftTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单位编辑草稿测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '单位编辑草稿功能测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '这个测试页面用于验证单位编辑屏幕的草稿保存功能：\n'
              '• 编辑单位后保存草稿\n'
              '• 再次进入页面时显示草稿内容\n'
              '• 正式提交后清除草稿',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // 测试1：测试草稿保存和恢复
            _buildTestCard(
              title: '测试1：草稿保存和恢复',
              description: '测试编辑单位数据后保存草稿，再次进入时是否能恢复',
              buttonText: '开始测试',
              onPressed: () => _testDraftSaveAndRestore(context),
            ),

            const SizedBox(height: 16),

            // 测试2：测试草稿清除
            _buildTestCard(
              title: '测试2：草稿清除功能',
              description: '测试正式提交后草稿是否被正确清除',
              buttonText: '开始测试',
              onPressed: () => _testDraftClear(context),
            ),

            const SizedBox(height: 16),

            // 测试3：测试带初始数据的草稿
            _buildTestCard(
              title: '测试3：带初始数据的草稿',
              description: '测试在已有单位配置基础上的草稿功能',
              buttonText: '开始测试',
              onPressed: () => _testDraftWithInitialData(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }

  /// 测试草稿保存和恢复
  void _testDraftSaveAndRestore(BuildContext context) {
    const testProductId = 'test_product_draft_001';

    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: testProductId,
              initialProductUnits: null,
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '草稿保存和恢复测试', result);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('测试提示：请在单位编辑页面进行一些修改并保存草稿，然后返回重新进入测试'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
  }

  /// 测试草稿清除功能
  void _testDraftClear(BuildContext context) {
    const testProductId = 'test_product_draft_clear';

    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: testProductId,
              initialProductUnits: null,
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '草稿清除测试', result);

            // 提示用户再次进入页面验证草稿是否被清除
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('测试提示：现在再次进入相同产品的编辑页面，应该不再显示草稿提示'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
  }

  /// 测试带初始数据的草稿
  void _testDraftWithInitialData(BuildContext context) {
    const testProductId = 'test_product_draft_with_data';

    // 创建一些示例初始数据
    final initialUnits = [
      ProductUnit(
        productUnitId: '${testProductId}_unit_piece',
        productId: testProductId,
        unitId: 'unit_piece',
        conversionRate: 1.0, // 基础单位
      ),
      ProductUnit(
        productUnitId: '${testProductId}_unit_box',
        productId: testProductId,
        unitId: 'unit_box',
        conversionRate: 12.0, // 1盒 = 12个
      ),
    ];

    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => UnitEditScreen(
              productId: testProductId,
              initialProductUnits: initialUnits,
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '带初始数据的草稿测试', result);
          }
        });
  }

  /// 显示测试结果对话框
  void _showResultDialog(
    BuildContext context,
    String testName,
    List<ProductUnit> units,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$testName 结果'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('配置的单位数量: ${units.length}'),
              const SizedBox(height: 10),
              const Text(
                '详细配置:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              ...units.map(
                (unit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• 单位ID: ${unit.unitId}, 换算率: ${unit.conversionRate}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '✓ 草稿功能测试完成',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
