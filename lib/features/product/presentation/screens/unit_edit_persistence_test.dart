// 单位编辑页表单数据持久化功能测试示例
// 使用方法：在单位编辑界面进行以下操作来验证功能

/*
测试步骤：

1. 打开单位编辑页面
2. 输入基本单位：
   - 在基本单位输入框中输入 "件"

3. 添加第一个辅单位：
   - 点击 "添加辅单位" 按钮
   - 单位名称：箱
   - 换算率：12
   - 条码：1234567890123
   - 建议零售价：120.00

4. 添加第二个辅单位：
   - 再次点击 "添加辅单位" 按钮
   - 单位名称：盒
   - 换算率：6
   - 条码：9876543210987
   - 建议零售价：60.00

5. 导航离开页面（点击返回按钮）

6. 重新进入单位编辑页面

7. 验证结果：
   ✓ 基本单位显示 "件"
   ✓ 第一个辅单位：箱, 12, 1234567890123, 120.00
   ✓ 第二个辅单位：盒, 6, 9876543210987, 60.00
   ✓ 页面顶部显示草稿指示器

8. 清除数据测试：
   - 点击草稿指示器中的 "清除" 按钮
   - 验证页面重置为初始状态
   - 验证草稿指示器消失

预期行为：
- 所有输入的数据在页面切换后应该完整保持
- 实时输入时数据应该立即保存到持久化状态
- 清除功能应该完全清空表单并重置页面
- 用户体验应该流畅无感知
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/provider/unit_edit_form_providers.dart';

/// 测试工具类 - 用于验证持久化功能
class UnitEditPersistenceTestUtil {
  /// 检查当前持久化状态
  static void checkPersistenceState(WidgetRef ref) {
    final formState = ref.read(unitEditFormProvider);

    print('=== 单位编辑页持久化状态检查 ===');
    print('辅单位数量: ${formState.auxiliaryUnits.length}');
    print('辅单位计数器: ${formState.auxiliaryCounter}');

    for (int i = 0; i < formState.auxiliaryUnits.length; i++) {
      final aux = formState.auxiliaryUnits[i];
      print('辅单位 ${i + 1}:');
      print('  ID: ${aux.id}');
      print('  单位名称: ${aux.unitName}');
      print('  换算率: ${aux.conversionRate}');
      print('  条码: ${aux.barcode}');
      print('  建议零售价: ${aux.retailPrice}');
    }
    print('===============================');
  }

  /// 模拟添加测试数据
  static void addTestData(WidgetRef ref) {
    final notifier = ref.read(unitEditFormProvider.notifier);

    // 添加第一个辅单位
    notifier.addAuxiliaryUnit();
    notifier.updateAuxiliaryUnitName(1, '箱');
    notifier.updateAuxiliaryUnitConversionRate(1, 12.0);
    notifier.updateAuxiliaryUnitBarcode(1, '1234567890123');
    notifier.updateAuxiliaryUnitRetailPrice(1, '120.00');

    // 添加第二个辅单位
    notifier.addAuxiliaryUnit();
    notifier.updateAuxiliaryUnitName(2, '盒');
    notifier.updateAuxiliaryUnitConversionRate(2, 6.0);
    notifier.updateAuxiliaryUnitBarcode(2, '9876543210987');
    notifier.updateAuxiliaryUnitRetailPrice(2, '60.00');

    print('✅ 测试数据已添加到持久化状态');
  }

  /// 清除所有测试数据
  static void clearTestData(WidgetRef ref) {
    ref.read(unitEditFormProvider.notifier).resetUnitEditForm();
    print('🗑️ 所有测试数据已清除');
  }

  /// 验证数据完整性
  static bool validateTestData(WidgetRef ref) {
    final formState = ref.read(unitEditFormProvider);

    if (formState.auxiliaryUnits.length != 2) return false;

    final aux1 = formState.auxiliaryUnits.firstWhere((aux) => aux.id == 1);
    if (aux1.unitName != '箱' || aux1.conversionRate != 12.0) return false;

    final aux2 = formState.auxiliaryUnits.firstWhere((aux) => aux.id == 2);
    if (aux2.unitName != '盒' || aux2.conversionRate != 6.0) return false;

    print('✅ 数据验证通过');
    return true;
  }
}

/// 测试页面 Widget - 可以用于单独测试持久化功能
class UnitEditPersistenceTestPage extends ConsumerWidget {
  const UnitEditPersistenceTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(unitEditFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('持久化功能测试')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前持久化状态', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // 基本单位信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('辅单位数量: ${formState.auxiliaryUnits.length}')],
                ),
              ),
            ),

            // 辅单位列表
            if (formState.auxiliaryUnits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('辅单位列表', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: formState.auxiliaryUnits.length,
                  itemBuilder: (context, index) {
                    final aux = formState.auxiliaryUnits[index];
                    return Card(
                      child: ListTile(
                        title: Text('${aux.unitName} (ID: ${aux.id})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('换算率: ${aux.conversionRate}'),
                            Text('条码: ${aux.barcode}'),
                            Text('建议零售价: ¥${aux.retailPrice}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // 操作按钮
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => UnitEditPersistenceTestUtil.addTestData(ref),
                  child: const Text('添加测试数据'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      UnitEditPersistenceTestUtil.clearTestData(ref),
                  child: const Text('清除数据'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      UnitEditPersistenceTestUtil.checkPersistenceState(ref),
                  child: const Text('打印状态'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      UnitEditPersistenceTestUtil.validateTestData(ref),
                  child: const Text('验证数据'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
