import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/constants/app_routes.dart';
import '../../inventory/application/service/weighted_average_price_service.dart';

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

            // 数据修复
            Text('数据修复', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () => _recalculateAveragePrices(ref, context),
              icon: const Icon(Icons.calculate),
              label: const Text('重新计算库存均价'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showSalesTransactionsData(context, ref),
                child: const Text('查看销售交易'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCustomersData(context, ref),
                child: const Text('查看客户'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showSalesTransactionItemsData(context, ref),
                child: const Text('查看销售交易项'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showStockData(context, ref),
                child: const Text('查看库存'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showOutboundReceiptsData(context, ref),
                child: const Text('查看出库单'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showProductUnitsData(context, ref),
                child: const Text('查看产品单位'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showOutboundReceiptsData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final database = ref.read(appDatabaseProvider);
      final outboundReceipts = await database
          .select(database.outboundReceipt)
          .get();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('出库单数据 (${outboundReceipts.length} 条)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500, // 设置固定高度以便滚动
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: outboundReceipts.length,
                itemBuilder: (context, index) {
                  final outboundReceipt = outboundReceipts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('出库单号: ${outboundReceipt.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('店铺ID: ${outboundReceipt.shopId}'),
                          Text('原因: ${outboundReceipt.reason}'),
                          if (outboundReceipt.salesTransactionId != null)
                            Text(
                              '销售单ID: ${outboundReceipt.salesTransactionId}',
                            ),
                          Text(
                            '创建时间: ${outboundReceipt.createdAt.toString().substring(0, 16)}',
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
    } catch (e) {
      print('查询出库单数据时出错: $e');
      if (context.mounted) {
        showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
      }
    }
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

  Future<void> _recalculateAveragePrices(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重新计算'),
        content: const Text(
          '此操作将基于历史采购记录重新计算所有库存的移动加权平均价格。\n\n'
          '注意：仅支持通过采购入库的记录，其他入库方式（如调拨、盘点）无法修复。\n\n'
          '确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 显示加载提示
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在重新计算库存均价...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final service = ref.read(weightedAveragePriceServiceProvider);
        await service.recalculateAllWeightedAveragePrices();

        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          showAppSnackBar(context, message: '✅ 库存均价重新计算完成');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          showAppSnackBar(
            context,
            message: '❌ 计算失败: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _showShopsData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final shops = await database.select(database.shop).get();

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
                  // trailing: Text(shop.id),
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
    final categories = await database.select(database.category).get();

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
                  trailing: Text(category.id.toString()),
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
    final units = await database.select(database.unit).get();

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
                  trailing: Text(unit.id.toString()),
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
    final products = await database.select(database.product).get();

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
                  trailing: Text(product.id.toString()),
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
    final suppliers = await database.select(database.supplier).get();

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
                  trailing: Text(supplier.id.toString()),
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
    final purchases = await database.select(database.purchaseOrder).get();

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
                    title: Text('采购单号: ${purchase.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('供应商ID: ${purchase.supplierId}'),
                        Text('店铺ID: ${purchase.shopId}'),
                        Text(
                          '采购日期: ${purchase.createdAt.toString().substring(0, 16)}',
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
    final barcodes = await database.select(database.barcode).get();

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
                    title: Text('条码: ${barcode.barcodeValue}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('条码ID: ${barcode.id}'),
                        Text('产品单位ID: ${barcode.id}'),
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
    final batches = await database.select(database.productBatch).get();

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
                    title: Text('批次号: ${batch.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('产品ID: ${batch.productId}'),
                        Text(
                          'totalInboundQuantity: ${batch.totalInboundQuantity}',
                        ),
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

  Future<void> _showSalesTransactionsData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final database = ref.read(appDatabaseProvider);
    final salesTransactions = await database
        .select(database.salesTransaction)
        .get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('销售交易数据 (${salesTransactions.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500, // 设置固定高度以便滚动
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: salesTransactions.length,
              itemBuilder: (context, index) {
                final salesTransaction = salesTransactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('销售订单号: ${salesTransaction.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('客户ID: ${salesTransaction.customerId}'),
                        Text('店铺ID: ${salesTransaction.shopId}'),
                        Text(
                          '总金额: ¥${salesTransaction.totalAmount.toStringAsFixed(2)}',
                        ),
                        Text(
                          '实际金额: ¥${salesTransaction.actualAmount.toStringAsFixed(2)}',
                        ),
                        Text('状态: ${salesTransaction.status}'),
                        if (salesTransaction.remarks != null &&
                            salesTransaction.remarks!.isNotEmpty)
                          Text('备注: ${salesTransaction.remarks}'),
                        Text(
                          '创建时间: ${salesTransaction.createdAt.toString().substring(0, 16)}',
                        ),
                        Text(
                          '更新时间: ${salesTransaction.updatedAt.toString().substring(0, 16)}',
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

  Future<void> _showCustomersData(BuildContext context, WidgetRef ref) async {
    final database = ref.read(appDatabaseProvider);
    final customers = await database.select(database.customers).get();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('客户数据 (${customers.length} 条)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // 设置固定高度以便滚动
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(customer.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${customer.id}'),
                        Text('客户名称: ${customer.name}'),
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

  Future<void> _showSalesTransactionItemsData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final database = ref.read(appDatabaseProvider);
      final salesTransactionItems = await database
          .select(database.salesTransactionItem)
          .get();

      // 添加调试日志
      print('销售交易项数据查询结果: ${salesTransactionItems.length} 条记录');

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('销售交易项数据 (${salesTransactionItems.length} 条)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500, // 设置固定高度以便滚动
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: salesTransactionItems.length,
                itemBuilder: (context, index) {
                  final salesTransactionItem = salesTransactionItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        '销售交易ID: ${salesTransactionItem.salesTransactionId}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('产品ID: ${salesTransactionItem.productId}'),
                          Text('数量: ${salesTransactionItem.quantity}'),
                          Text('价格(分): ${salesTransactionItem.priceInCents}'),
                          Text('批次ID: ${salesTransactionItem.batchId ?? '无'}'),
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
    } catch (e) {
      print('查询销售交易项数据时出错: $e');
      if (context.mounted) {
        showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
      }
    }
  }

  Future<void> _showStockData(BuildContext context, WidgetRef ref) async {
    try {
      final database = ref.read(appDatabaseProvider);
      final stockItems = await database.select(database.stock).get();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('库存数据 (${stockItems.length} 条)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500, // 设置固定高度以便滚动
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: stockItems.length,
                itemBuilder: (context, index) {
                  final stock = stockItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('产品ID: ${stock.productId}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('批次ID: ${stock.batchId ?? '无'}'),
                          Text('数量: ${stock.quantity}'),
                          Text('店铺ID: ${stock.shopId}'),
                          Text(
                            '均价(元): ${(stock.averageUnitPriceInSis! / 100000).toStringAsFixed(2)}',
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _clearStockData(context, ref);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清空'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('查询库存数据时出错: $e');
      if (context.mounted) {
        showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
      }
    }
  }

  Future<void> _clearStockData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('此操作将清空所有库存数据，确定继续吗？'),
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
        final database = ref.read(appDatabaseProvider);
        await database.delete(database.stock).go();
        
        if (context.mounted) {
          showAppSnackBar(context, message: '✅ 库存数据已清空');
        }
      } catch (e) {
        print('清空库存数据时出错: $e');
        if (context.mounted) {
          showAppSnackBar(context, message: '❌ 清空失败: $e', isError: true);
        }
      }
    }
  }

  Future<void> _showProductUnitsData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final database = ref.read(appDatabaseProvider);
      final productUnits = await database.select(database.unitProduct).get();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('产品单位数据 (${productUnits.length} 条)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: productUnits.length,
                itemBuilder: (context, index) {
                  final productUnit = productUnits[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('ID: ${productUnit.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('产品ID: ${productUnit.productId}'),
                          Text('单位ID: ${productUnit.unitId}'),
                          Text('换算率: ${productUnit.conversionRate}'),
                          if (productUnit.sellingPriceInCents != null)
                            Text(
                              '售价: ¥${(productUnit.sellingPriceInCents! / 100).toStringAsFixed(2)}',
                            ),
                          if (productUnit.wholesalePriceInCents != null)
                            Text(
                              '批发价: ¥${(productUnit.wholesalePriceInCents! / 100).toStringAsFixed(2)}',
                            ),
                          Text(
                            '更新时间: ${productUnit.lastUpdated.toString().substring(0, 16)}',
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
    } catch (e) {
      print('查询产品单位数据时出错: $e');
      if (context.mounted) {
        showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
      }
    }
  }
}
