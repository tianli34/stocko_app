import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/product/domain/model/barcode.dart';
import '../features/product/application/provider/barcode_providers.dart';

/// 条码管理使用示例
///
/// 此文档展示了如何使用新创建的条码表和相关功能
class BarcodeUsageExample extends ConsumerWidget {
  const BarcodeUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('条码管理示例')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '条码表功能演示',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 示例1：添加条码
            ElevatedButton(
              onPressed: () => _addSampleBarcode(ref),
              child: const Text('添加示例条码'),
            ),
            const SizedBox(height: 8),

            // 示例2：查询条码
            ElevatedButton(
              onPressed: () => _queryBarcode(ref),
              child: const Text('查询条码'),
            ),
            const SizedBox(height: 8),

            // 示例3：显示产品单位的条码
            ElevatedButton(
              onPressed: () => _showProductUnitBarcodes(context, ref),
              child: const Text('显示产品单位条码'),
            ),
            const SizedBox(height: 16),

            // 显示条码控制器状态
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(barcodeControllerProvider);

                if (state.isLoading) {
                  return const CircularProgressIndicator();
                }

                if (state.isError) {
                  return Text(
                    '错误: ${state.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                if (state.isSuccess && state.lastOperatedBarcodes != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('最后操作的条码:'),
                      ...state.lastOperatedBarcodes!.map(
                        (barcode) => Text('- ${barcode.barcode}'),
                      ),
                    ],
                  );
                }

                return const Text('准备就绪');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 添加示例条码
  void _addSampleBarcode(WidgetRef ref) async {
    final controller = ref.read(barcodeControllerProvider.notifier);

    final sampleBarcode = Barcode(
      id: 'barcode_${DateTime.now().millisecondsSinceEpoch}',
      productUnitId: 'sample_product_unit_id',
      barcode: '1234567890123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await controller.addBarcode(sampleBarcode);
  }

  /// 查询条码
  void _queryBarcode(WidgetRef ref) async {
    final controller = ref.read(barcodeControllerProvider.notifier);

    final barcode = await controller.getBarcodeByValue('1234567890123');
    if (barcode != null) {
      print('找到条码: ${barcode.barcode}, 产品单位ID: ${barcode.productUnitId}');
    } else {
      print('未找到条码');
    }
  }

  /// 显示产品单位的条码
  void _showProductUnitBarcodes(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('产品单位条码'),
        content: Consumer(
          builder: (context, ref, child) {
            final barcodesAsync = ref.watch(
              barcodesByProductUnitIdProvider('sample_product_unit_id'),
            );

            return barcodesAsync.when(
              data: (barcodes) {
                if (barcodes.isEmpty) {
                  return const Text('该产品单位暂无条码');
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: barcodes
                      .map(
                        (barcode) => ListTile(
                          title: Text(barcode.barcode),
                          subtitle: Text('创建时间: ${barcode.formattedCreatedAt}'),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('错误: $error'),
            );
          },
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
}

/// 条码功能使用说明
/// 
/// ## 数据库结构
/// 
/// ```sql
/// CREATE TABLE barcodes (
///   id TEXT PRIMARY KEY,
///   product_unit_id TEXT NOT NULL,
///   barcode TEXT NOT NULL,
///   created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
///   updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
///   UNIQUE(barcode),
///   UNIQUE(product_unit_id, barcode)
/// );
/// ```
/// 
/// ## 主要功能
/// 
/// 1. **添加条码**
///    ```dart
///    final barcode = Barcode(
///      id: 'unique_id',
///      productUnitId: 'product_unit_id',
///      barcode: '1234567890123',
///    );
///    await controller.addBarcode(barcode);
///    ```
/// 
/// 2. **查询条码**
///    ```dart
///    final barcode = await controller.getBarcodeByValue('1234567890123');
///    ```
/// 
/// 3. **监听产品单位的条码变化**
///    ```dart
///    ref.watch(barcodesByProductUnitIdProvider(productUnitId));
///    ```
/// 
/// 4. **删除条码**
///    ```dart
///    await controller.deleteBarcode(barcodeId);
///    ```
/// 
/// ## 业务场景
/// 
/// - 一个产品单位可以有多个条码
/// - 每个条码必须唯一
/// - 可以通过条码快速查找对应的产品单位
/// - 支持批量操作
/// 
/// ## 索引优化
/// 
/// 系统已自动创建以下索引以提高查询性能：
/// - `idx_barcodes_barcode`: 条码值索引
/// - `idx_barcodes_product_unit_id`: 产品单位ID索引
