import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/utils/backup_file_manager.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/models/backup_options.dart';
import '../controllers/backup_controller.dart';
import '../controllers/backup_management_controller.dart';
import '../widgets/progress_manager.dart';
import '../widgets/create_backup_dialog.dart';
import '../widgets/backup_details_dialog.dart';
import '../widgets/backup_troubleshooting_guide.dart';
import '../widgets/backup_diagnostic_dialog.dart';
import 'restore_screen.dart';
import '../../../../core/services/toast_service.dart';

/// 备份管理界面
class BackupManagementScreen extends ConsumerStatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  ConsumerState<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends ConsumerState<BackupManagementScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载时刷新备份列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupManagementControllerProvider.notifier).refreshBackups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupManagementControllerProvider);

    return ProgressManager(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('备份管理'),
          actions: [
            IconButton(
              icon: const Icon(Icons.healing),
              onPressed: () => _showDiagnosticDialog(context),
              tooltip: '系统诊断',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => BackupTroubleshootingGuide.show(context),
              tooltip: '故障排除',
            ),
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RestoreScreen(),
                  ),
                );
              },
              tooltip: '恢复数据',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(backupManagementControllerProvider.notifier).refreshBackups();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(backupManagementControllerProvider.notifier).refreshBackups();
          },
          child: _buildBody(context, backupState),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateBackupDialog(context),
          icon: const Icon(Icons.backup),
          label: const Text('创建备份'),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BackupManagementState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(backupManagementControllerProvider.notifier).refreshBackups();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.backups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.backup_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无备份文件',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮创建您的第一个备份',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.backups.length,
      itemBuilder: (context, index) {
        final backup = state.backups[index];
        return _buildBackupCard(context, backup);
      },
    );
  }

  Widget _buildBackupCard(BuildContext context, BackupMetadata backup) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final fileSizeText = _formatFileSize(backup.fileSize);
    final totalRecords = backup.tableCounts.values.fold(0, (sum, count) => sum + count);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBackupDetails(context, backup),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    backup.isEncrypted ? Icons.lock : Icons.backup,
                    color: backup.isEncrypted 
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          backup.fileName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(backup.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value, backup),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('查看详情'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('重命名'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('分享'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('删除', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.storage,
                    fileSizeText,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Icons.dataset,
                    '$totalRecords 条记录',
                  ),
                  if (backup.isEncrypted) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      Icons.security,
                      '已加密',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ],
              ),
              if (backup.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  backup.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showCreateBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateBackupDialog(
        onCreateBackup: (options) => _createBackup(options),
      ),
    );
  }

  void _showBackupDetails(BuildContext context, BackupMetadata backup) {
    showDialog(
      context: context,
      builder: (context) => BackupDetailsDialog(backup: backup),
    );
  }

  Future<void> _createBackup(BackupOptions options) async {
    try {
      // 开始备份 - 进度对话框将由 ProgressManager 自动显示
      await ref.read(backupControllerProvider.notifier).startBackup(options: options);
      
      // 刷新备份列表
      await ref.read(backupManagementControllerProvider.notifier).refreshBackups();
    } catch (e) {
      // 错误处理由 ProgressManager 处理
      ToastService.error('备份创建失败: $e');
    }
  }

  void _handleMenuAction(BuildContext context, String action, BackupMetadata backup) {
    switch (action) {
      case 'details':
        _showBackupDetails(context, backup);
        break;
      case 'rename':
        _showRenameDialog(context, backup);
        break;
      case 'share':
        _shareBackup(context, backup);
        break;
      case 'delete':
        _showDeleteConfirmation(context, backup);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, BackupMetadata backup) {
    final controller = TextEditingController(text: backup.fileName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名备份'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新文件名',
            hintText: '请输入新的文件名',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ToastService.error('文件名不能为空');
                return;
              }
              
              Navigator.of(context).pop();
              
              try {
                await ref.read(backupManagementControllerProvider.notifier)
                    .renameBackup(backup.id, newName);
                ToastService.success('重命名成功');
              } catch (e) {
                ToastService.error('重命名失败: $e');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _shareBackup(BuildContext context, BackupMetadata backup) async {
    try {
      await BackupFileManager.shareBackupFile(backup);
      ToastService.success('分享成功');
    } catch (e) {
      ToastService.error('分享失败: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, BackupMetadata backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定要删除备份文件 "${backup.fileName}" 吗？\n\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(backupManagementControllerProvider.notifier)
                    .deleteBackup(backup.id);
                ToastService.success('备份已删除');
              } catch (e) {
                ToastService.error('删除失败: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BackupDiagnosticDialog(),
    );
  }
}