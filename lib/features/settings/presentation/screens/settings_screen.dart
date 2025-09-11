import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../core/database/database.dart';
import '../../../../core/services/toast_service.dart';
import '../../../product/application/product_import_service.dart';
import 'image_cache_management_screen.dart';
import 'privacy_policy_screen.dart';

/// 通用设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
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
          const Divider(),
          const _DataManagementSection(),
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
