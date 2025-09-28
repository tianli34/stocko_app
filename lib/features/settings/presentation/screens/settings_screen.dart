import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
 
 import '../../../../core/database/database.dart';
import '../../../../core/services/toast_service.dart';
import '../../../product/application/product_import_service.dart';
import 'image_cache_management_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../../../backup/presentation/screens/backup_management_screen.dart';
import '../../../backup/presentation/screens/auto_backup_settings_screen.dart';

/// 通用设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// 构建分区标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 显示备份功能帮助对话框
  void _showBackupHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('备份功能使用指南'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                context,
                '什么是数据备份？',
                '数据备份是将您的库存数据（产品、库存、销售记录等）导出到文件中，以防数据丢失或设备更换时使用。',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                '如何创建备份？',
                '1. 点击"备份管理"进入备份界面\n2. 点击"创建备份"按钮\n3. 设置备份选项（名称、加密等）\n4. 等待备份完成',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                '如何恢复数据？',
                '1. 在备份管理界面点击"恢复"按钮\n2. 选择备份文件\n3. 选择恢复模式（替换或合并）\n4. 确认恢复操作',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                '自动备份功能',
                '启用自动备份后，系统会定期自动创建备份文件，无需手动操作。建议开启此功能以确保数据安全。',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                        '建议定期创建备份，并将重要备份文件保存到云存储或其他安全位置。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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
            child: const Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupManagementScreen(),
                ),
              );
            },
            child: const Text('立即体验'),
          ),
        ],
      ),
    );
  }

  /// 构建帮助内容区块
  Widget _buildHelpSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 数据备份和恢复部分
          _buildSectionHeader(context, '数据备份和恢复'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份管理'),
            subtitle: const Text('创建和管理数据备份'),
            trailing: IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showBackupHelpDialog(context),
              tooltip: '备份功能帮助',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('自动备份'),
            subtitle: const Text('配置自动备份设置'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AutoBackupSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, '系统管理'),
          ListTile(
            leading: const Icon(Icons.cached),
            title: const Text('图片缓存管理'),
            subtitle: const Text('查看和清理应用缓存'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageCacheManagementScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, '法律信息'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('用户协议'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const _DataManagementSection(),
          if (kDebugMode) ...[
           const Divider(),
           ListTile(
             leading: const Icon(Icons.restore),
             title: const Text('重置隐私政策状态'),
             subtitle: const Text('仅在开发模式下可见'),
             onTap: () async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.setBool('isPrivacyPolicyAgreed', false);
               ToastService.show(
                 '隐私政策状态已重置，请重启应用',
                 length: Toast.LENGTH_LONG,
               );
             },
           ),
         ],
        ],
      ),
    );
  }
}

/// 数据管理部分
class _DataManagementSection extends ConsumerWidget {
  const _DataManagementSection();

  Future<void> _importProductsFromFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // 1. 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        ToastService.info('未选择文件');
        return;
      }

      // 2. 读取并解析文件
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(content);
      final List<Map<String, dynamic>> productsData = jsonData
          .cast<Map<String, dynamic>>();

      // 3. 调用服务执行导入
      final db = ref.read(appDatabaseProvider); // 使用正确的 provider
      final importService = ProductImportService(db);

      ToastService.info('正在导入...');

      final importResult = await importService.bulkInsertProducts(productsData);

      if (importResult != null) {
        // 使用 ToastService 显示结果
        ToastService.show(
          importResult,
          length: Toast.LENGTH_LONG,
          backgroundColor: importResult.contains('失败')
              ? Colors.red
              : Colors.green,
        );
      }
    } catch (e) {
      ToastService.error('导入失败: $e');
    }
  }

  Future<void> _importProductsFromAsset(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      ToastService.info('正在从应用内加载示例数据...');

      // 1. 定义要加载的文件列表
      final List<String> assetFiles = [
        'assets/data/jy_products1.json',
        'assets/data/jy_products2.json',
        'assets/data/jy_products3.json',
        'assets/data/jy_products4.json',
        'assets/data/jy_products5.json',
        'assets/data/jy_products6.json',
        'assets/data/jy_products7.json',
        'assets/data/jy_products8.json',
        'assets/data/jy_products9.json',
        'assets/data/jy_products10.json',
        'assets/data/jy_products11.json',
      ];

      // 2. 读取并解析所有文件
      final List<Map<String, dynamic>> productsData = [];
      for (final assetFile in assetFiles) {
        try {
          final String content = await rootBundle.loadString(assetFile);
          final List<dynamic> jsonData = jsonDecode(content);
          productsData.addAll(jsonData.cast<Map<String, dynamic>>());
        } catch (e) {
          // 如果某个文件加载失败，可以选择记录日志或通知用户
          ToastService.error('加载文件 $assetFile 失败: $e');
        }
      }

      if (productsData.isEmpty) {
        ToastService.info('没有可导入的货品数据。');
        return;
      }

      // 2. 调用服务执行导入
      final db = ref.read(appDatabaseProvider);
      final importService = ProductImportService(db);
      final importResult = await importService.bulkInsertProducts(productsData);

      if (importResult != null) {
        ToastService.show(
          importResult,
          length: Toast.LENGTH_LONG,
          backgroundColor: importResult.contains('失败')
              ? Colors.red
              : Colors.green,
        );
      }
    } catch (e) {
      ToastService.error('导入失败: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      leading: const Icon(Icons.storage),
      title: const Text('数据管理'),
      subtitle: const Text('导入和导出数据'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _importProductsFromFile(context, ref),
            icon: const Icon(Icons.file_upload),
            label: const Text('从文件导入货品'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40), // 按钮宽度填充
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _importProductsFromAsset(context, ref),
            icon: const Icon(Icons.data_usage),
            label: const Text('加载示例货品'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40), // 按钮宽度填充
            ),
          ),
        ),
      ],
    );
  }
}
