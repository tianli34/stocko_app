import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/backup_error_service_provider.dart';
import '../../data/services/backup_error_handler.dart';
import '../widgets/backup_error_widget.dart';

/// 错误处理集成示例
class ErrorHandlingIntegrationExample extends ConsumerStatefulWidget {
  const ErrorHandlingIntegrationExample({super.key});

  @override
  ConsumerState<ErrorHandlingIntegrationExample> createState() =>
      _ErrorHandlingIntegrationExampleState();
}

class _ErrorHandlingIntegrationExampleState
    extends ConsumerState<ErrorHandlingIntegrationExample> {
  UserFriendlyError? _currentError;

  @override
  void initState() {
    super.initState();
    
    // 监听错误流
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToErrors();
    });
  }

  void _listenToErrors() {
    ref.listen(backupErrorStreamProvider, (previous, next) {
      next.when(
        data: (error) {
          setState(() {
            _currentError = error;
          });
          
          // 根据错误严重程度选择显示方式
          if (_shouldShowAsDialog(error)) {
            _showErrorDialog(error);
          } else {
            _showErrorSnackBar(error);
          }
        },
        loading: () {},
        error: (error, stackTrace) {
          // 处理监听错误流时的错误
          debugPrint('Error listening to error stream: $error');
        },
      );
    });
  }

  bool _shouldShowAsDialog(UserFriendlyError error) {
    // 根据错误类型决定是否显示对话框
    return error.suggestion != null || 
           error.technicalDetails != null ||
           error.title.contains('严重') ||
           error.title.contains('失败');
  }

  void _showErrorDialog(UserFriendlyError error) {
    BackupErrorDialog.show(
      context,
      error: error,
      onRetry: error.canRetry ? () => _retryLastOperation() : null,
      showTechnicalDetails: true,
    );
  }

  void _showErrorSnackBar(UserFriendlyError error) {
    BackupErrorSnackBar.show(
      context,
      error: error,
      onRetry: error.canRetry ? () => _retryLastOperation() : null,
    );
  }

  void _retryLastOperation() {
    // 这里应该重试最后失败的操作
    // 具体实现取决于应用的状态管理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在重试操作...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorStatsAsync = ref.watch(backupErrorStatsProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('错误处理集成示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showErrorStats,
            tooltip: '查看错误统计',
          ),
        ],
      ),
      body: Column(
        children: [
          // 当前错误显示
          if (_currentError != null) ...[
            BackupErrorWidget(
              error: _currentError!,
              onRetry: _currentError!.canRetry ? _retryLastOperation : null,
              onDismiss: () => setState(() => _currentError = null),
              showTechnicalDetails: true,
            ),
            const Divider(),
          ],

          // 错误统计信息
          Expanded(
            child: errorStatsAsync.when(
              data: (stats) => _buildErrorStats(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('加载错误统计失败: $error'),
              ),
            ),
          ),

          // 测试按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _simulateFileSystemError,
                  child: const Text('模拟文件系统错误'),
                ),
                ElevatedButton(
                  onPressed: _simulateDatabaseError,
                  child: const Text('模拟数据库错误'),
                ),
                ElevatedButton(
                  onPressed: _simulateValidationError,
                  child: const Text('模拟验证错误'),
                ),
                ElevatedButton(
                  onPressed: _exportErrorReport,
                  child: const Text('导出错误报告'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStats(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '错误统计 (最近 ${stats['period']} 天)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('总错误数: ${stats['totalErrors']}'),
                const SizedBox(height: 16),
                
                if (stats['errorsByType'] != null) ...[
                  Text(
                    '按类型分类:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...(stats['errorsByType'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text('${entry.key}: ${entry.value}'),
                          )),
                ],
                
                const SizedBox(height: 16),
                
                if (stats['errorsByOperation'] != null) ...[
                  Text(
                    '按操作分类:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...(stats['errorsByOperation'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text('${entry.key}: ${entry.value}'),
                          )),
                ],
              ],
            ),
          ),
        ),
        
        if (stats['resourceStats'] != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '资源统计',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('总资源数: ${stats['resourceStats']['totalResources']}'),
                  Text('活跃操作数: ${stats['resourceStats']['activeOperations']}'),
                  
                  if (stats['resourceStats']['resourcesByType'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '按类型分类:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...(stats['resourceStats']['resourcesByType'] as Map<String, dynamic>)
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 4),
                              child: Text('${entry.key}: ${entry.value}'),
                            )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showErrorStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误统计'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer(
            builder: (context, ref, child) {
              final statsAsync = ref.watch(backupErrorStatsProvider());
              return statsAsync.when(
                data: (stats) => _buildErrorStats(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('加载失败: $error'),
                ),
              );
            },
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

  void _simulateFileSystemError() async {
    final errorService = ref.read(backupErrorServiceProvider);
    
    try {
      await errorService.executeWithRetry(
        () => throw Exception('模拟的文件系统错误'),
        operationName: 'SimulateFileSystemError',
        context: {'test': true},
      );
    } catch (e) {
      // 错误已经被处理和记录
    }
  }

  void _simulateDatabaseError() async {
    final errorService = ref.read(backupErrorServiceProvider);
    
    try {
      await errorService.executeWithRetry(
        () => throw Exception('模拟的数据库错误'),
        operationName: 'SimulateDatabaseError',
        context: {'test': true},
      );
    } catch (e) {
      // 错误已经被处理和记录
    }
  }

  void _simulateValidationError() async {
    final errorService = ref.read(backupErrorServiceProvider);
    
    try {
      await errorService.executeWithRetry(
        () => throw FormatException('模拟的验证错误'),
        operationName: 'SimulateValidationError',
        context: {'test': true},
      );
    } catch (e) {
      // 错误已经被处理和记录
    }
  }

  void _exportErrorReport() async {
    final errorService = ref.read(backupErrorServiceProvider);
    
    try {
      final filePath = await errorService.exportErrorReport(
        period: const Duration(days: 7),
      );
      
      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('错误报告已导出到: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导出错误报告失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}