import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/services/backup_diagnostic_service.dart';
import '../../data/services/backup_repair_service.dart';

/// 备份诊断对话框
class BackupDiagnosticDialog extends ConsumerStatefulWidget {
  const BackupDiagnosticDialog({super.key});

  @override
  ConsumerState<BackupDiagnosticDialog> createState() =>
      _BackupDiagnosticDialogState();
}

class _BackupDiagnosticDialogState
    extends ConsumerState<BackupDiagnosticDialog> {
  BackupDiagnosticResult? _diagnosticResult;
  BackupRepairResult? _repairResult;
  bool _isRunningDiagnostic = false;
  bool _isRunningRepair = false;

  late final BackupDiagnosticService _diagnosticService;
  late final BackupRepairService _repairService;

  @override
  void initState() {
    super.initState();
    final database = ref.read(appDatabaseProvider);
    _diagnosticService = BackupDiagnosticService(database);
    _repairService = BackupRepairService(database);

    // 自动运行快速诊断
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runQuickDiagnostic();
    });
  }

  Future<void> _runQuickDiagnostic() async {
    if (_isRunningDiagnostic) return;

    setState(() {
      _isRunningDiagnostic = true;
      _diagnosticResult = null;
    });

    try {
      final result = await _diagnosticService.runQuickDiagnostic();
      if (mounted) {
        setState(() {
          _diagnosticResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('诊断失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDiagnostic = false;
        });
      }
    }
  }

  Future<void> _runFullDiagnostic() async {
    if (_isRunningDiagnostic) return;

    setState(() {
      _isRunningDiagnostic = true;
      _diagnosticResult = null;
    });

    try {
      final result = await _diagnosticService.runFullDiagnostic();
      if (mounted) {
        setState(() {
          _diagnosticResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('完整诊断失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDiagnostic = false;
        });
      }
    }
  }

  Future<void> _runAutoRepair() async {
    if (_isRunningRepair) return;

    setState(() {
      _isRunningRepair = true;
      _repairResult = null;
    });

    try {
      final result = await _repairService.autoRepair();
      if (mounted) {
        setState(() {
          _repairResult = result;
        });

        // 修复后重新运行诊断
        if (result.success) {
          await _runQuickDiagnostic();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('自动修复失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningRepair = false;
        });
      }
    }
  }

  Future<void> _resetBackupSystem() async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('这将删除所有现有备份文件并重置备份系统。此操作不可撤销，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRunningRepair = true;
      _repairResult = null;
    });

    try {
      final result = await _repairService.resetBackupSystem();
      if (mounted) {
        setState(() {
          _repairResult = result;
        });

        // 重置后重新运行诊断
        await _runQuickDiagnostic();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('重置失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningRepair = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.healing, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '备份系统诊断',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // 操作按钮
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunningDiagnostic ? null : _runQuickDiagnostic,
                  icon: _isRunningDiagnostic
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.speed),
                  label: const Text('快速诊断'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunningDiagnostic ? null : _runFullDiagnostic,
                  icon: _isRunningDiagnostic
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('完整诊断'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunningRepair ? null : _runAutoRepair,
                  icon: _isRunningRepair
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build),
                  label: const Text('自动修复'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunningRepair ? null : _resetBackupSystem,
                  icon: _isRunningRepair
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('重置系统'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 结果显示
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 诊断结果
                    if (_diagnosticResult != null) ...[
                      _buildDiagnosticResultCard(_diagnosticResult!),
                      const SizedBox(height: 16),
                    ],

                    // 修复结果
                    if (_repairResult != null) ...[
                      _buildRepairResultCard(_repairResult!),
                      const SizedBox(height: 16),
                    ],

                    // 加载状态
                    if (_isRunningDiagnostic || _isRunningRepair) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('正在处理中...'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticResultCard(BackupDiagnosticResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isHealthy ? Icons.check_circle : Icons.error,
                  color: result.isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '诊断结果: ${result.isHealthy ? "系统正常" : "发现问题"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 问题列表
            if (result.issues.isNotEmpty) ...[
              const Text(
                '发现的问题:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              ...result.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(issue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 警告列表
            if (result.warnings.isNotEmpty) ...[
              const Text(
                '警告信息:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              ...result.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 系统信息
            if (result.systemInfo.isNotEmpty) ...[
              ExpansionTile(
                title: const Text('系统信息'),
                children: [
                  ...result.systemInfo.entries.map(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRepairResultCard(BackupRepairResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.warning,
                  color: result.success ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '修复结果: ${result.message}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 已修复的问题
            if (result.fixedIssues.isNotEmpty) ...[
              const Text(
                '已修复的问题:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              ...result.fixedIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(child: Text(issue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 剩余问题
            if (result.remainingIssues.isNotEmpty) ...[
              const Text(
                '剩余问题:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              ...result.remainingIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(issue)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
