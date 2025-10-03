import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:stocko_app/features/backup/data/providers/restore_service_provider.dart';
import 'package:stocko_app/features/backup/domain/models/restore_mode.dart';

class ProductRestoreDebugPage extends ConsumerStatefulWidget {
  const ProductRestoreDebugPage({super.key});

  @override
  ConsumerState<ProductRestoreDebugPage> createState() =>
      _ProductRestoreDebugPageState();
}

class _ProductRestoreDebugPageState
    extends ConsumerState<ProductRestoreDebugPage> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  Future<void> _copyLogsToClipboard() async {
    if (_logs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有测试日志可复制')));
      }
      return;
    }

    final logsText = _logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('测试结果已复制到剪贴板'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () => _showLogsDialog(),
          ),
        ),
      );
    }
  }

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_copy),
            SizedBox(width: 8),
            Text('测试结果'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              _logs.join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _copyLogsToClipboard();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('测试日志已清空')));
    }
  }

  Future<void> _runProductRestoreTest() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🧪 开始产品恢复功能测试...');

    try {
      // 1. 验证备份文件
      await _validateBackupFile();

      // 2. 测试恢复服务
      await _testRestoreService();

      // 3. 测试不同恢复模式
      await _testRestoreModes();

      _addLog('✅ 产品恢复功能测试完成！');
    } catch (e) {
      _addLog('❌ 测试失败: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _validateBackupFile() async {
    _addLog('📋 步骤1: 验证备份文件');

    try {
      // 首先尝试从应用目录查找备份文件
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/product_test_backup.json');

      // 清理可能存在的旧测试文件，确保使用最新的assets文件
      if (await backupFile.exists()) {
        await backupFile.delete();
        _addLog('🧹 清理旧的测试备份文件');
      }

      String content;

      // 尝试从assets加载备份文件
      try {
        content = await rootBundle.loadString(
          'assets/data/product_test_backup.json',
        );
        _addLog('✓ 从assets成功加载备份文件');

        // 将assets文件复制到应用目录以供后续使用
        await backupFile.writeAsString(content);
        _addLog('✓ 备份文件已复制到应用目录');
        _addLog('✓ 文件大小: ${await backupFile.length()} 字节');
      } catch (e) {
        // 如果assets也没有，创建一个测试用的备份文件
        _addLog('⚠️ assets中也未找到备份文件，创建测试备份文件...');
        content = await _createTestBackupFile(backupFile);
      }

      final data = jsonDecode(content) as Map<String, dynamic>;

      final metadata = data['metadata'] as Map<String, dynamic>;
      _addLog('✓ 备份ID: ${metadata['id']}');
      _addLog('✓ 版本: ${metadata['version']}');

      // 验证产品数据
      final tables = data['tables'] as Map<String, dynamic>;
      final products = tables['product'] as List<dynamic>;
      _addLog('✓ 产品记录数: ${products.length}');
    } catch (e) {
      _addLog('❌ 备份文件验证失败: $e');
      rethrow;
    }
  }

  Future<String> _createTestBackupFile(File backupFile) async {
    final tablesData = {
      "category": [
        {
          "id": 1,
          "name": "测试分类1",
          "description": "测试用分类",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
        {
          "id": 2,
          "name": "测试分类2",
          "description": "测试用分类",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
      ],
      "unit": [
        {
          "id": 1,
          "name": "个",
          "symbol": "个",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
        {
          "id": 2,
          "name": "盒",
          "symbol": "盒",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
      ],
      "product": [
        {
          "id": 1,
          "name": "测试产品A",
          "sku": "TEST001",
          "specification": "500ml",
          "brand": "测试品牌",
          "category_id": 1,
          "base_unit_id": 1,
          "retail_price": 1500,
          "status": "active",
          "remarks": "这是一个测试产品",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
        {
          "id": 2,
          "name": "测试产品B",
          "sku": "TEST002",
          "specification": "1L",
          "brand": "测试品牌",
          "category_id": 2,
          "base_unit_id": 2,
          "retail_price": 2500,
          "status": "active",
          "remarks": "这是另一个测试产品",
          "created_at": DateTime.now().toIso8601String(),
          "updated_at": DateTime.now().toIso8601String(),
        },
      ],
    };

    // 生成正确的校验和
    final tablesJson = jsonEncode(tablesData);
    final bytes = utf8.encode(tablesJson);
    final digest = sha256.convert(bytes);
    final correctChecksum = digest.toString();

    final testBackupData = {
      "metadata": {
        "id": "product_test_backup_${DateTime.now().millisecondsSinceEpoch}",
        "fileName": "product_test_backup.json",
        "createdAt": DateTime.now().toIso8601String(),
        "fileSize": 1856,
        "version": "2.0.0",
        "tableCounts": {"category": 2, "unit": 2, "product": 2},
        "checksum": correctChecksum,
        "isEncrypted": false,
        "description": "产品恢复功能测试备份文件（自动生成）",
        "appVersion": "1.0.0+1",
        "schemaVersion": 22,
      },
      "tables": tablesData,
    };

    final content = jsonEncode(testBackupData);
    await backupFile.writeAsString(content);
    _addLog('✓ 测试备份文件创建成功');
    return content;
  }

  Future<void> _testRestoreService() async {
    _addLog('🔧 步骤2: 测试恢复服务');

    try {
      final restoreService = ref.read(restoreServiceProvider);
      _addLog('✓ 恢复服务初始化成功');

      // 获取备份文件路径
      final appDir = await getApplicationDocumentsDirectory();
      final backupFilePath = '${appDir.path}/product_test_backup.json';

      final metadata = await restoreService.validateBackupFile(backupFilePath);
      _addLog('✅ 备份文件验证成功');
      _addLog('- 备份ID: ${metadata.id}');
      _addLog('- 版本: ${metadata.version}');
      _addLog('- 产品记录数: ${metadata.tableCounts['product'] ?? 0}');

      final isCompatible = await restoreService.checkCompatibility(
        backupFilePath,
      );
      _addLog('✓ 兼容性检查: ${isCompatible ? '✅ 兼容' : '❌ 不兼容'}');
    } catch (e) {
      _addLog('⚠️ 恢复服务测试遇到问题: $e');
      _addLog('📝 这可能是由于恢复服务需要完整的数据库环境');
    }
  }

  Future<void> _testRestoreModes() async {
    _addLog('🎯 步骤3: 测试不同恢复模式');

    try {
      final restoreService = ref.read(restoreServiceProvider);
      final appDir = await getApplicationDocumentsDirectory();
      final backupFilePath = '${appDir.path}/product_test_backup.json';

      final modes = [
        RestoreMode.addOnly,
        RestoreMode.merge,
        RestoreMode.replace,
      ];

      for (final mode in modes) {
        _addLog('🔧 测试恢复模式: ${_getRestoreModeDescription(mode)}');

        try {
          final preview = await restoreService.previewRestore(
            backupFilePath,
            mode: mode,
          );

          _addLog('✅ 预览生成成功');
          _addLog('- 兼容性: ${preview.isCompatible ? '✅ 兼容' : '❌ 不兼容'}');
          _addLog('- 记录统计: ${preview.recordCounts}');
          _addLog('- 预估冲突: ${preview.estimatedConflicts}');
        } catch (e) {
          _addLog('⚠️ 模式测试遇到问题: $e');
          _addLog('📝 这可能是由于缺少完整的数据库环境');
        }
      }
    } catch (e) {
      _addLog('❌ 恢复模式测试失败: $e');
    }
  }

  String _getRestoreModeDescription(RestoreMode mode) {
    switch (mode) {
      case RestoreMode.replace:
        return '完全替换模式';
      case RestoreMode.merge:
        return '合并模式';
      case RestoreMode.addOnly:
        return '仅添加模式';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('产品恢复测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_logs.isNotEmpty) ...[
            IconButton(
              onPressed: _showLogsDialog,
              icon: const Icon(Icons.visibility),
              tooltip: '查看完整日志',
            ),
            IconButton(
              onPressed: _copyLogsToClipboard,
              icon: const Icon(Icons.copy),
              tooltip: '复制测试结果',
            ),
            IconButton(
              onPressed: _clearLogs,
              icon: const Icon(Icons.clear),
              tooltip: '清空日志',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 控制按钮区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runProductRestoreTest,
                    child: _isRunning
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('测试运行中...'),
                            ],
                          )
                        : const Text('开始产品恢复测试'),
                  ),
                ),
                if (_logs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyLogsToClipboard,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('复制结果'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showLogsDialog,
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('查看详情'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('清空日志'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 日志显示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '点击上方按钮开始测试\n测试结果将在这里显示',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.green;

                        // 根据日志内容设置不同颜色
                        if (log.contains('❌') || log.contains('失败')) {
                          textColor = Colors.red;
                        } else if (log.contains('⚠️') || log.contains('警告')) {
                          textColor = Colors.orange;
                        } else if (log.contains('✅') || log.contains('成功')) {
                          textColor = Colors.lightGreen;
                        } else if (log.contains('🧪') ||
                            log.contains('📋') ||
                            log.contains('🔧') ||
                            log.contains('🎯')) {
                          textColor = Colors.cyan;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          // 状态栏
          if (_logs.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Text(
                '共 ${_logs.length} 条日志 • ${_isRunning ? '测试进行中...' : '测试完成'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
