import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/utils/file_access_helper.dart';

/// 文件访问帮助对话框
class FileAccessHelpDialog extends StatelessWidget {
  const FileAccessHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('无法访问备份文件？'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '如果您的备份文件位于 /data/user/0/... 路径下，系统文件选择器无法直接访问。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            _buildSectionTitle(context, '解决方法：'),
            const SizedBox(height: 8),
            
            _buildStep(context, '1', '使用文件管理器', [
              '打开手机的文件管理器应用',
              '导航到备份文件所在位置',
              '长按备份文件，选择"复制"',
              '导航到"下载"或"文档"文件夹',
              '粘贴文件',
            ]),
            
            const SizedBox(height: 12),
            
            _buildStep(context, '2', '推荐的存放位置', [
              '下载文件夹 (Downloads)',
              '文档文件夹 (Documents)', 
              'SD卡根目录',
              '桌面文件夹',
            ]),
            
            const SizedBox(height: 12),
            
            _buildStep(context, '3', '重新选择文件', [
              '返回应用',
              '点击"选择文件"按钮',
              '从新位置选择备份文件',
            ]),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提示：应用会自动处理文件数据，即使无法访问原始路径也能正常恢复。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我知道了'),
        ),
        FilledButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: FileAccessHelper.getAccessGuide()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('帮助信息已复制到剪贴板')),
            );
            Navigator.of(context).pop();
          },
          child: const Text('复制指南'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  /// 显示帮助对话框
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const FileAccessHelpDialog(),
    );
  }
}