import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyDebugHelper {
  /// 检查隐私政策同意状态
  static Future<Map<String, dynamic>> checkPrivacyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    final oldKeyAgreed = prefs.getBool('privacy_policy_agreed');
    final newKeyAgreed = prefs.getBool('isPrivacyPolicyAgreed');
    
    return {
      'oldKey': oldKeyAgreed,
      'newKey': newKeyAgreed,
      'shouldShowDialog': !(newKeyAgreed == true || oldKeyAgreed == true),
      'allKeys': prefs.getKeys().toList(),
    };
  }
  
  /// 重置隐私政策状态（用于测试）
  static Future<void> resetPrivacyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('privacy_policy_agreed');
    await prefs.remove('isPrivacyPolicyAgreed');
  }
  
  /// 显示调试信息
  static void showDebugInfo(BuildContext context) async {
    final status = await checkPrivacyStatus();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('隐私政策调试信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('旧Key状态: ${status['oldKey']}'),
              Text('新Key状态: ${status['newKey']}'),
              Text('应显示弹窗: ${status['shouldShowDialog']}'),
              const SizedBox(height: 16),
              const Text('所有存储的Keys:'),
              ...((status['allKeys'] as List).map((key) => Text('- $key'))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                await resetPrivacyStatus();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('隐私政策状态已重置')),
                );
              },
              child: const Text('重置状态'),
            ),
          ],
        ),
      );
    }
  }
}