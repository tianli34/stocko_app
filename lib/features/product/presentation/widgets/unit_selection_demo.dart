import 'package:flutter/material.dart';
import '../screens/unit_selection_screen.dart';
import '../../domain/model/unit.dart';

/// 单位选择演示页面
/// 展示如何在表单中集成单位选择功能
class UnitSelectionDemo extends StatefulWidget {
  const UnitSelectionDemo({super.key});

  @override
  State<UnitSelectionDemo> createState() => _UnitSelectionDemoState();
}

class _UnitSelectionDemoState extends State<UnitSelectionDemo> {
  Unit? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单位选择演示')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              '产品信息表单',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 产品名称输入框
            const TextField(
              decoration: InputDecoration(
                labelText: '产品名称',
                hintText: '请输入产品名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 16),

            // 单位选择
            Card(
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('单位'),
                subtitle: _selectedUnit != null
                    ? Text('已选择：${_selectedUnit!.name}')
                    : const Text('请选择产品单位'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectUnit,
              ),
            ),
            const SizedBox(height: 16),

            // 价格输入框
            const TextField(
              decoration: InputDecoration(
                labelText: '价格',
                hintText: '请输入产品价格',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '¥ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedUnit != null ? _saveProduct : null,
                    child: const Text('保存产品'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _manageUnits,
                    child: const Text('管理单位'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 选择结果显示
            if (_selectedUnit != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '当前选择的单位信息：',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '单位名称：${_selectedUnit!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '单位ID：${_selectedUnit!.id}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // 使用说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 点击"单位"卡片可以选择产品单位\n'
                    '• 点击"管理单位"可以添加、编辑或删除单位\n'
                    '• 选择单位后才能保存产品信息',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择单位
  Future<void> _selectUnit() async {
    final result = await Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          selectedUnitId: _selectedUnit?.id,
          isSelectionMode: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedUnit = result;
      });

      // 显示选择成功的提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已选择单位：${result.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 管理单位
  void _manageUnits() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UnitSelectionScreen(isSelectionMode: false),
      ),
    );
  }

  /// 保存产品
  void _saveProduct() {
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择产品单位'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 模拟保存操作
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('产品保存成功！单位：${_selectedUnit!.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
