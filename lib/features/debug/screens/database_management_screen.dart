import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/constants/app_routes.dart';

/// 数据库管理开发工具
/// 仅在开发模式下使用
class DatabaseManagementScreen extends ConsumerWidget {
  const DatabaseManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库管理'),
        backgroundColor: Colors.orange.shade400,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回首页',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 数据库信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据库信息',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('版本: 14'),
                    Text('位置: app_database.db'),
                    Text('状态: 正常运行'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 初始化操作
            Text('初始化操作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () => _initializeDatabase(ref, context),
              icon: const Icon(Icons.refresh),
              label: const Text('重新初始化所有默认数据'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () => _resetDatabase(ref, context),
              icon: const Icon(Icons.delete_forever),
              label: const Text('清空并重置数据库'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // 数据查看
            Text('数据查看', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            _buildDataViewButtons(context, ref),

            const Spacer(),

            // 警告文本
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ 此页面仅供开发使用，生产环境请勿使用',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataViewButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showShopsData(context, ref),
                child: const Text('查看店铺'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCategoriesData(context, ref),
                child: const Text('查看类别'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showUnitsData(context, ref),
                child: const Text('查看单位'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showProductsData(context, ref),
                child: const Text('查看产品'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showSuppliersData(context, ref),
                child: const Text('查看供应商'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showPurchasesData(context, ref),
                child: const Text('查看采购'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showBarcodesData(context, ref),
                child: const Text('查看条码'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showBatchesData(context, ref),
                child: const Text('查看批次'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _initializeDatabase(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(databaseInitializationProvider.future);
      if (context.mounted) {
        showAppSnackBar(context, message: '✅ 数据库初始化完成');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: '❌ 初始化失败: $e', isError: true);
      }
    }
  }

  Future<void> _resetDatabase(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('此操作将清空所有数据并重新初始化，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(resetDatabaseProvider(true).future);
        if (context.mounted) {
          showAppSnackBar(context, message: '✅ 数据库重置完成');
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, message: '❌ 重置失败: $e', isError: true);
        }
      }
    }
  }

  Future<void> _showShopsData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final shops = await database.select(database.shopsTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('店铺数据 (${shops.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return ListTile(
                  title: Text(shop.name),
                  subtitle: Text('经理: ${shop.manager}'),
                  trailing: Text(shop.id),
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
  }

  Future<void> _showCategoriesData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final categories = await database.select(database.categoriesTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('类别数据 (${categories.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  trailing: Text(category.id),
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
  }

  Future<void> _showUnitsData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final units = await database.select(database.unitsTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('单位数据 (${units.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return ListTile(
                  title: Text(unit.name),
                  trailing: Text(unit.id),
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
  }

  Future<void> _showProductsData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final products = await database.select(database.productsTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('产品数据 (${products.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('状态: ${product.status}'),
                  trailing: Text(product.id),
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
  }

  Future<void> _showSuppliersData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final suppliers = await database.select(database.suppliersTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('供应商数据 (${suppliers.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return ListTile(
                  title: Text(supplier.name),
                  subtitle: Text(
                    '创建时间: ${supplier.createdAt.toString().substring(0, 16)}',
                  ),
                  trailing: Text(supplier.id),
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
  }

  Future<void> _showPurchasesData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final purchases = await database.select(database.purchaseOrdersTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('采购数据 (${purchases.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // 设置固定高度以便滚动
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('采购单号: ${purchase.purchaseOrderNumber}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('供应商ID: ${purchase.supplierId}'),
                        Text('店铺ID: ${purchase.shopId}'),
                        Text(
                          '采购日期: ${purchase.purchaseDate.toString().substring(0, 16)}',
                        ),
                        Text('状态: ${purchase.status}'),
                      ],
                    ),
                    isThreeLine: true,
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
  }

  Future<void> _showBarcodesData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final barcodes = await database.select(database.barcodesTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('条码数据 (${barcodes.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // 设置固定高度以便滚动
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: barcodes.length,
              itemBuilder: (context, index) {
                final barcode = barcodes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('条码: ${barcode.barcode}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('条码ID: ${barcode.id}'),
                        Text('产品单位ID: ${barcode.productUnitId}'),
                        Text(
                          '创建时间: ${barcode.createdAt.toString().substring(0, 16)}',
                        ),
                        Text(
                          '更新时间: ${barcode.updatedAt.toString().substring(0, 16)}',
                        ),
                      ],
                    ),
                    isThreeLine: true,
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
  }

  Future<void> _showBatchesData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final batches = await database.select(database.batchesTable).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('批次数据 (${batches.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('批次号: ${batch.batchNumber}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('产品ID: ${batch.productId}'),
                        Text('初始数量: ${batch.initialQuantity}'),
                        Text(
                          '生产日期: ${batch.productionDate.toString().substring(0, 10)}',
                        ),
                        Text('店铺ID: ${batch.shopId}'),
                      ],
                    ),
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
  }
}
