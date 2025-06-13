import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/domain/model/product_unit.dart';
import '../../features/product/presentation/screens/unit_edit_screen.dart';

/// 单位编辑功能测试页面
/// 用于验证单位编辑屏幕的数据库保存功能
class UnitEditTestScreen extends ConsumerWidget {
  const UnitEditTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单位编辑测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '单位编辑功能测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '这个测试页面用于验证单位编辑屏幕是否正确保存数据到数据库中。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // 测试1：新产品的单位配置
            _buildTestCard(
              title: '测试1：新产品单位配置',
              description: '创建新产品的单位配置，数据会通过Navigator返回但不会保存到数据库',
              buttonText: '开始测试',
              onPressed: () => _testNewProductUnits(context),
            ),

            const SizedBox(height: 16),

            // 测试2：现有产品的单位配置
            _buildTestCard(
              title: '测试2：现有产品单位配置',
              description: '编辑现有产品的单位配置，数据会保存到数据库',
              buttonText: '开始测试',
              onPressed: () => _testExistingProductUnits(context),
            ),

            const SizedBox(height: 16),

            // 测试3：带初始数据的单位配置
            _buildTestCard(
              title: '测试3：加载现有单位配置',
              description: '加载现有的单位配置进行编辑',
              buttonText: '开始测试',
              onPressed: () => _testWithInitialData(context),
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

  /// 测试新产品的单位配置
  void _testNewProductUnits(BuildContext context) {
    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: null, // 新产品
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '新产品单位配置', result);
          }
        });
  }

  /// 测试现有产品的单位配置
  void _testExistingProductUnits(BuildContext context) {
    const testProductId = 'test_product_001';

    Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => const UnitEditScreen(
              productId: testProductId, // 现有产品ID
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            _showResultDialog(context, '现有产品单位配置', result);
          }
        });
  }

  /// 测试带初始数据的单位配置
  void _testWithInitialData(BuildContext context) {
    const testProductId = 'test_product_002';

    // 模拟现有的单位配置
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
        conversionRate: 12.0, // 1箱 = 12个
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
            _showResultDialog(context, '带初始数据的单位配置', result);
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '💾 如果productId不为空且不是"new"，数据已保存到数据库',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
