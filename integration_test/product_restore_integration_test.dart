import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/main.dart' as app;
import 'package:stocko_app/features/backup/data/providers/restore_service_provider.dart';
import 'package:stocko_app/features/backup/domain/models/restore_mode.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('产品恢复功能集成测试', () {
    testWidgets('完整的产品恢复流程测试', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 等待应用完全加载
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 创建测试容器
      final container = ProviderContainer();
      
      try {
        // 1. 验证备份文件存在
        await _validateBackupFileExists();

        // 2. 测试恢复服务初始化
        final restoreService = container.read(restoreServiceProvider);
        expect(restoreService, isNotNull);

        // 3. 测试备份文件验证
        final metadata = await restoreService.validateBackupFile('product_test_backup.json');
        expect(metadata.id, isNotEmpty);
        expect(metadata.version, isNotEmpty);
        expect(metadata.tableCounts['product'], equals(2));

        // 4. 测试兼容性检查
        final isCompatible = await restoreService.checkCompatibility('product_test_backup.json');
        expect(isCompatible, isTrue);

        // 5. 测试不同恢复模式的预览
        for (final mode in RestoreMode.values) {
          final preview = await restoreService.previewRestore(
            'product_test_backup.json',
            mode: mode,
          );
          
          expect(preview, isNotNull);
          expect(preview.recordCounts, isNotEmpty);
          
          // 验证预览结果的合理性
          switch (mode) {
            case RestoreMode.addOnly:
              // 仅添加模式应该有明确的新增记录数
              expect(preview.recordCounts['product'], greaterThanOrEqualTo(0));
              break;
            case RestoreMode.merge:
              // 合并模式可能有冲突
              expect(preview.estimatedConflicts, greaterThanOrEqualTo(0));
              break;
            case RestoreMode.replace:
              // 替换模式应该替换所有记录
              expect(preview.recordCounts['product'], equals(2));
              break;
          }
        }

        // 6. 测试时间估算
        final estimatedTime = await restoreService.estimateRestoreTime(
          'product_test_backup.json',
          RestoreMode.merge,
        );
        expect(estimatedTime, greaterThan(0));

        print('✅ 所有集成测试通过');

      } finally {
        container.dispose();
      }
    });

    testWidgets('错误处理测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final container = ProviderContainer();
      
      try {
        final restoreService = container.read(restoreServiceProvider);

        // 测试不存在的备份文件
        expect(
          () => restoreService.validateBackupFile('nonexistent_backup.json'),
          throwsException,
        );

        // 测试无效的备份文件格式
        // 这里可以创建一个格式错误的测试文件进行测试

        print('✅ 错误处理测试通过');

      } finally {
        container.dispose();
      }
    });

    testWidgets('UI交互测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 如果应用中有恢复功能的UI，可以测试用户交互
      // 例如：
      // 1. 找到恢复按钮
      // 2. 点击按钮
      // 3. 验证UI状态变化
      // 4. 验证恢复结果

      // 示例：查找并点击恢复相关的按钮
      final restoreButton = find.text('恢复数据');
      if (await tester.binding.defaultBinaryMessenger.checkMockMessageHandler('flutter/platform', null) == null) {
        // 只在真实环境中执行UI测试
        if (restoreButton.evaluate().isNotEmpty) {
          await tester.tap(restoreButton);
          await tester.pumpAndSettle();
          
          // 验证恢复过程的UI反馈
          expect(find.text('恢复中...'), findsOneWidget);
        }
      }

      print('✅ UI交互测试完成');
    });
  });
}

/// 验证备份文件是否存在
Future<void> _validateBackupFileExists() async {
  final backupFile = File('product_test_backup.json');
  
  if (!await backupFile.exists()) {
    throw Exception('测试备份文件不存在: product_test_backup.json');
  }

  // 验证文件内容格式
  final content = await backupFile.readAsString();
  final data = jsonDecode(content) as Map<String, dynamic>;
  
  // 验证必要的字段
  expect(data['metadata'], isNotNull);
  expect(data['tables'], isNotNull);
  expect(data['tables']['product'], isNotNull);
  expect((data['tables']['product'] as List).length, equals(2));
}