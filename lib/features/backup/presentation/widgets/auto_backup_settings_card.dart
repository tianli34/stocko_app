import 'package:flutter/material.dart';

/// 自动备份设置卡片组件
class AutoBackupSettingsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? leadingIcon;

  const AutoBackupSettingsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: leadingIcon != null
            ? Icon(
                leadingIcon,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}