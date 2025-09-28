import 'package:flutter/material.dart';

import '../../domain/models/auto_backup_settings.dart';

/// 备份频率选择器
class BackupFrequencySelector extends StatelessWidget {
  final BackupFrequency currentFrequency;
  final ValueChanged<BackupFrequency> onFrequencyChanged;

  const BackupFrequencySelector({
    super.key,
    required this.currentFrequency,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  '备份频率',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: BackupFrequency.values.map((frequency) {
                return RadioListTile<BackupFrequency>(
                  title: Text(_getFrequencyTitle(frequency)),
                  subtitle: Text(_getFrequencyDescription(frequency)),
                  value: frequency,
                  groupValue: currentFrequency,
                  onChanged: (value) {
                    if (value != null) {
                      onFrequencyChanged(value);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyTitle(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return '每日备份';
      case BackupFrequency.weekly:
        return '每周备份';
      case BackupFrequency.monthly:
        return '每月备份';
    }
  }

  String _getFrequencyDescription(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return '每天凌晨2点自动备份';
      case BackupFrequency.weekly:
        return '每周日凌晨2点自动备份';
      case BackupFrequency.monthly:
        return '每月1号凌晨2点自动备份';
    }
  }
}