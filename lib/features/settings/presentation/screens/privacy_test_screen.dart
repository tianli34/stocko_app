import 'package:flutter/material.dart';
import '../../../../core/widgets/privacy_debug_helper.dart';
import '../widgets/privacy_policy_dialog.dart';

class PrivacyTestScreen extends StatelessWidget {
  const PrivacyTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '隐私政策弹窗测试工具',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () => PrivacyDebugHelper.showDebugInfo(context),
              child: const Text('查看隐私政策状态'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                await PrivacyDebugHelper.resetPrivacyStatus();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('隐私政策状态已重置，请重启应用查看弹窗')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('重置隐私政策状态'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => PrivacyPolicyDialog(
                    onAgreed: () async {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('测试：用户已同意隐私政策')),
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('手动显示隐私政策弹窗'),
            ),
            
            const SizedBox(height: 30),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. 点击"查看隐私政策状态"检查当前状态'),
                    Text('2. 点击"重置隐私政策状态"清除同意记录'),
                    Text('3. 重启应用查看弹窗是否正常显示'),
                    Text('4. 点击"手动显示"测试弹窗功能'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}