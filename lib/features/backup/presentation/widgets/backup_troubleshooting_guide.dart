import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 备份故障排除指南
class BackupTroubleshootingGuide extends StatelessWidget {
  const BackupTroubleshootingGuide({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BackupTroubleshootingGuide(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline),
          SizedBox(width: 12),
          Text('备份故障排除'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              '常见问题及解决方案',
              [
                _TroubleshootingItem(
                  problem: '备份失败 - 存储空间不足',
                  solutions: [
                    '清理设备存储空间，删除不需要的文件',
                    '卸载不常用的应用程序',
                    '清理应用缓存和临时文件',
                    '使用外部存储设备（如SD卡）',
                  ],
                ),
                _TroubleshootingItem(
                  problem: '备份失败 - 权限被拒绝',
                  solutions: [
                    '在系统设置中检查应用权限',
                    '授予应用存储权限',
                    '重启应用后重试',
                    '检查是否启用了应用权限管理',
                  ],
                ),
                _TroubleshootingItem(
                  problem: '备份过程中应用崩溃',
                  solutions: [
                    '关闭其他正在运行的应用',
                    '重启设备释放内存',
                    '确保设备有足够的可用内存',
                    '尝试在设备空闲时进行备份',
                  ],
                ),
                _TroubleshootingItem(
                  problem: '数据库连接失败',
                  solutions: [
                    '完全关闭应用后重新打开',
                    '重启设备',
                    '检查是否有其他应用占用数据库',
                    '清理应用缓存（注意：可能丢失未保存数据）',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '预防措施',
              [
                _TroubleshootingItem(
                  problem: '如何避免备份失败',
                  solutions: [
                    '定期清理设备存储空间',
                    '保持应用为最新版本',
                    '在设备电量充足时进行备份',
                    '避免在备份过程中使用其他功能',
                    '定期重启设备保持系统稳定',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '联系技术支持',
              [
                _TroubleshootingItem(
                  problem: '如果问题仍然存在',
                  solutions: [
                    '记录错误发生的具体时间和操作',
                    '截图保存错误信息',
                    '提供设备型号和系统版本信息',
                    '联系技术支持团队获取帮助',
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed: () => _copyTroubleshootingInfo(context),
          child: const Text('复制故障排除信息'),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_TroubleshootingItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildTroubleshootingItem(context, item)),
      ],
    );
  }

  Widget _buildTroubleshootingItem(
    BuildContext context,
    _TroubleshootingItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.problem,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...item.solutions.asMap().entries.map((entry) {
            final index = entry.key;
            final solution = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      solution,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _copyTroubleshootingInfo(BuildContext context) {
    const troubleshootingText = '''
备份故障排除指南

常见问题及解决方案：

1. 备份失败 - 存储空间不足
   • 清理设备存储空间，删除不需要的文件
   • 卸载不常用的应用程序
   • 清理应用缓存和临时文件
   • 使用外部存储设备（如SD卡）

2. 备份失败 - 权限被拒绝
   • 在系统设置中检查应用权限
   • 授予应用存储权限
   • 重启应用后重试
   • 检查是否启用了应用权限管理

3. 备份过程中应用崩溃
   • 关闭其他正在运行的应用
   • 重启设备释放内存
   • 确保设备有足够的可用内存
   • 尝试在设备空闲时进行备份

4. 数据库连接失败
   • 完全关闭应用后重新打开
   • 重启设备
   • 检查是否有其他应用占用数据库
   • 清理应用缓存（注意：可能丢失未保存数据）

预防措施：
• 定期清理设备存储空间
• 保持应用为最新版本
• 在设备电量充足时进行备份
• 避免在备份过程中使用其他功能
• 定期重启设备保持系统稳定

如需更多帮助，请联系技术支持团队。
''';

    Clipboard.setData(const ClipboardData(text: troubleshootingText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('故障排除信息已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _TroubleshootingItem {
  final String problem;
  final List<String> solutions;

  const _TroubleshootingItem({
    required this.problem,
    required this.solutions,
  });
}