import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../domain/models/auto_backup_settings.dart';
import '../controllers/auto_backup_controller.dart';
import '../widgets/auto_backup_settings_card.dart';
import '../widgets/backup_frequency_selector.dart';
import '../widgets/backup_options_card.dart';

/// 自动备份设置页面
class AutoBackupSettingsScreen extends ConsumerWidget {
  const AutoBackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(autoBackupControllerProvider);
    final statusText = ref.watch(autoBackupStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动备份设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsContent(context, ref, settings, statusText),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
                '加载设置失败',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(autoBackupControllerProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    AutoBackupSettings settings,
    String statusText,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自动备份开关
          AutoBackupSettingsCard(
            title: '启用自动备份',
            subtitle: settings.enabled ? '自动备份已启用' : '自动备份已禁用',
            trailing: Switch(
              value: settings.enabled,
              onChanged: (value) async {
                await ref.read(autoBackupControllerProvider.notifier).toggleAutoBackup(value);
                Fluttertoast.showToast(
                  msg: value ? '自动备份已启用' : '自动备份已禁用',
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 状态信息
          if (settings.enabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '备份状态',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      context,
                      '下次备份',
                      statusText,
                      Icons.access_time,
                    ),
                    if (settings.lastBackupTime != null) ...[
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        context,
                        '上次备份',
                        _formatDateTime(settings.lastBackupTime!),
                        Icons.backup,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 备份频率设置
          if (settings.enabled) ...[
            BackupFrequencySelector(
              currentFrequency: settings.frequency,
              onFrequencyChanged: (frequency) async {
                await ref.read(autoBackupControllerProvider.notifier).setBackupFrequency(frequency);
                Fluttertoast.showToast(msg: '备份频率已更新');
              },
            ),
            const SizedBox(height: 16),
          ],

          // 备份数量设置
          if (settings.enabled) ...[
            AutoBackupSettingsCard(
              title: '最大备份数量',
              subtitle: '保留最近 ${settings.maxBackupCount} 个自动备份文件',
              trailing: DropdownButton<int>(
                value: settings.maxBackupCount,
                items: [3, 5, 10, 15, 20].map((count) {
                  return DropdownMenuItem(
                    value: count,
                    child: Text('$count 个'),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(autoBackupControllerProvider.notifier).setMaxBackupCount(value);
                    Fluttertoast.showToast(msg: '最大备份数量已更新');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 设备条件设置
          if (settings.enabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '设备条件',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('仅在WiFi下备份'),
                      subtitle: const Text('避免使用移动数据'),
                      value: settings.wifiOnly,
                      onChanged: (value) async {
                        await ref.read(autoBackupControllerProvider.notifier).setWifiOnly(value);
                        Fluttertoast.showToast(
                          msg: value ? '已启用WiFi限制' : '已禁用WiFi限制',
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('仅在充电时备份'),
                      subtitle: const Text('避免消耗电池电量'),
                      value: settings.chargingOnly,
                      onChanged: (value) async {
                        await ref.read(autoBackupControllerProvider.notifier).setChargingOnly(value);
                        Fluttertoast.showToast(
                          msg: value ? '已启用充电限制' : '已禁用充电限制',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 备份选项设置
          if (settings.enabled) ...[
            BackupOptionsCard(
              options: settings.backupOptions ?? const AutoBackupOptions(),
              onOptionsChanged: (options) async {
                await ref.read(autoBackupControllerProvider.notifier).setBackupOptions(options);
                Fluttertoast.showToast(msg: '备份选项已更新');
              },
            ),
            const SizedBox(height: 16),
          ],

          // 手动触发备份按钮
          if (settings.enabled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await ref.read(autoBackupControllerProvider.notifier).triggerManualBackup();
                  Fluttertoast.showToast(msg: result);
                },
                icon: const Icon(Icons.backup),
                label: const Text('立即备份'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}