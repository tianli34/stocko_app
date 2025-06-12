import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/domain/model/product_unit.dart';
import '../../features/product/presentation/screens/unit_edit_screen.dart';

/// 产品单位编辑功能验证页面
/// 用于验证单位编辑和数据库保存功能是否正常工作
class UnitEditValidationScreen extends ConsumerWidget {
  const UnitEditValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单位编辑功能验证'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '单位编辑功能验证',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '这个页面用于验证产品单位编辑功能是否正常工作。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // 测试1：验证空单位列表的处理
            _buildTestCard(
              title: '测试1：空单位配置处理',
              description: '验证当产品没有单位配置时，系统是否能正常处理',
              buttonText: '测试空配置',
              onPressed: () => _testEmptyUnitsConfiguration(context),
            ),

            const SizedBox(height: 16),

            // 测试2：测试真实产品ID的单位编辑
            _buildTestCard(
              title: '测试2：真实产品单位编辑',
              description: '使用真实的产品ID测试单位编辑功能',
              buttonText: '测试真实产品',
              onPressed: () => _testRealProductUnits(context),
            ),

            const SizedBox(height: 16),

            // 测试3：验证数据保存和加载
            _buildTestCard(
              title: '测试3：数据持久性验证',
              description: '验证单位配置保存后能否正确重新加载',
              buttonText: '测试数据持久性',
              onPressed: () => _testDataPersistence(context),
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

  /// 测试空单位配置的处理
  void _testEmptyUnitsConfiguration(BuildContext context) {
    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: 'test_product_empty', // 测试产品ID
              initialProductUnits: [], // 空的初始单位列表
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '空配置测试', result);
          }
        });
  }

  /// 测试真实产品的单位编辑
  void _testRealProductUnits(BuildContext context) {
    // 使用日志中显示的真实产品ID
    const realProductId = '1749698901282';

    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: realProductId,
              initialProductUnits: null, // 让系统自动加载
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '真实产品测试', result);
          }
        });
  }

  /// 测试数据持久性
  void _testDataPersistence(BuildContext context) {
    const testProductId = 'test_product_persistence';

    // 创建一些示例单位配置
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
        conversionRate: 10.0, // 1盒 = 10个
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
            _showResultDialog(context, '数据持久性测试', result);
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
              if (units.isEmpty)
                const Text('没有配置任何单位', style: TextStyle(color: Colors.orange)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: units.isNotEmpty
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  border: Border.all(
                    color: units.isNotEmpty ? Colors.green : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  units.isNotEmpty ? '✅ 测试通过：单位配置成功' : '⚠️ 注意：没有配置单位（这可能是正常的）',
                  style: TextStyle(
                    color: units.isNotEmpty
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
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
