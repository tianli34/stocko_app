import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/supplier_providers.dart';
import '../../data/dao/purchase_dao.dart';
import '../../../../core/database/database.dart';

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.purchaseDao;
});

final purchaseRecordsProvider = StreamProvider<List<PurchasesTableData>>((ref) {
  final dao = ref.watch(purchaseDaoProvider);
  return dao.watchAllPurchases();
});

class PurchaseRecordsScreen extends ConsumerWidget {
  const PurchaseRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(purchaseRecordsProvider);
    final suppliersAsync = ref.watch(allSuppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('采购记录'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.purchaseCreate),
            icon: const Icon(Icons.add),
            tooltip: '新建采购单',
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无采购记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          // 按采购单号分组
          final groupedRecords = <String, List<PurchasesTableData>>{};
          for (final record in records) {
            groupedRecords.putIfAbsent(record.purchaseNumber, () => []).add(record);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedRecords.length,
            itemBuilder: (context, index) {
              final purchaseNumber = groupedRecords.keys.elementAt(index);
              final purchaseItems = groupedRecords[purchaseNumber]!;
              final totalAmount = purchaseItems.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity));
              final totalQuantity = purchaseItems.fold<double>(0, (sum, item) => sum + item.quantity);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.purchaseDetailPath(purchaseNumber)),
                  child: ExpansionTile(
                    title: Text('采购单: $purchaseNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('日期: ${purchaseItems.first.purchaseDate.toString().substring(0, 10)}'),
                      suppliersAsync.when(
                        data: (suppliers) {
                          final supplier = suppliers.where((s) => s.id == purchaseItems.first.supplierId).firstOrNull;
                          return Text('供应商: ${supplier?.name ?? '未知'}');
                        },
                        loading: () => const Text('供应商: 加载中...'),
                        error: (_, __) => const Text('供应商: 加载失败'),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('￥${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text('${totalQuantity.toInt()}件', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  children: purchaseItems.map((item) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                    title: Text(item.productId),
                    subtitle: Text('生产日期: ${item.productionDate.toString().substring(0, 10)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('￥${item.unitPrice.toStringAsFixed(2)} × ${item.quantity.toInt()}'),
                        Text('￥${(item.unitPrice * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList(),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(purchaseRecordsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}