import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/restore_mode.dart';
import '../controllers/restore_controller.dart';
import '../widgets/restore_file_selector.dart';
import '../widgets/restore_mode_selector.dart';
import '../widgets/restore_preview_card.dart';
import '../widgets/progress_manager.dart';
import '../widgets/password_input_dialog.dart';

/// 数据恢复界面
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  @override
  void initState() {
    super.initState();
    // 重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restoreControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restoreControllerProvider);

    return ProgressManager(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('恢复数据'),
          actions: [
            if (state.selectedFilePath != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(restoreControllerProvider.notifier).reset();
                },
                tooltip: '重新选择',
              ),
          ],
        ),
        body: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RestoreState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在处理...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 文件选择器
          RestoreFileSelector(
            selectedFilePath: state.selectedFilePath,
            onSelectFile: () {
              ref.read(restoreControllerProvider.notifier).selectBackupFile();
            },
          ),
          
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(context, state.errorMessage!),
          ],

          if (state.requiresPassword) ...[
            const SizedBox(height: 16),
            _buildPasswordPrompt(context),
          ],

          if (state.restorePreview != null) ...[
            const SizedBox(height: 16),
            RestorePreviewCard(
              preview: state.restorePreview!,
            ),
            
            const SizedBox(height: 16),
            RestoreModeSelector(
              selectedMode: state.restoreMode,
              onModeChanged: (mode) {
                ref.read(restoreControllerProvider.notifier).setRestoreMode(mode);
              },
            ),
            
            const SizedBox(height: 24),
            _buildRestoreButton(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String errorMessage) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () {
                ref.read(restoreControllerProvider.notifier).clearError();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordPrompt(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  '需要密码',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '此备份文件已加密，请输入密码以继续',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showPasswordDialog(context),
              icon: const Icon(Icons.key),
              label: const Text('输入密码'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context, RestoreState state) {
    final preview = state.restorePreview!;
    final totalRecords = preview.recordCounts.values.fold<int>(0, (sum, count) => sum + count);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!preview.isCompatible) ...[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '兼容性警告',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此备份文件与当前应用版本可能不完全兼容，恢复过程中可能出现问题。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  if (preview.compatibilityWarnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...preview.compatibilityWarnings.map((warning) => 
                      Text(
                        '• $warning',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        ElevatedButton.icon(
          onPressed: () => _showRestoreConfirmation(context, state),
          icon: const Icon(Icons.restore),
          label: Text('开始恢复 ($totalRecords 条记录)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: preview.isCompatible 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  // 移除手动状态处理，由 ProgressManager 统一管理

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordInputDialog(
        onPasswordSubmitted: (password) {
          ref.read(restoreControllerProvider.notifier).validateWithPassword(password);
        },
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context, RestoreState state) {
    final preview = state.restorePreview!;
    final totalRecords = preview.recordCounts.values.fold<int>(0, (sum, count) => sum + count);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('即将恢复 $totalRecords 条记录到数据库中。'),
            const SizedBox(height: 8),
            Text('恢复模式: ${_getRestoreModeText(state.restoreMode)}'),
            const SizedBox(height: 16),
            if (state.restoreMode == RestoreMode.replace) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '警告：完全替换模式将删除所有现有数据！',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('此操作无法撤销，请确认是否继续？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(restoreControllerProvider.notifier).startRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: state.restoreMode == RestoreMode.replace
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }

  String _getRestoreModeText(RestoreMode mode) {
    switch (mode) {
      case RestoreMode.replace:
        return '完全替换现有数据';
      case RestoreMode.merge:
        return '合并数据';
      case RestoreMode.addOnly:
        return '仅添加新数据';
    }
  }
}