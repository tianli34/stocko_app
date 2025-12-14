import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/sales_return_providers.dart';
import '../../application/provider/customer_providers.dart';

class SalesReturnListScreen extends ConsumerWidget {
  const SalesReturnListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(salesReturnsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('退货记录'),
      ),
      body: returnsAsync.when(
        data: (returns) {
          if (returns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_return, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无退货记录',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '在销售记录中选择订单进行退货',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final returnData = returns[index];
              return SalesReturnCard(returnData: returnData);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

class SalesReturnCard extends ConsumerWidget {
  final SalesReturnData returnData;

  const SalesReturnCard({super.key, required this.returnData});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'pending':
        return '待处理';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '退货单号: ${returnData.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(returnData.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(returnData.status),
                    style: TextStyle(
                      color: _getStatusColor(returnData.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '原销售单: ${returnData.salesTransactionId}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            customersAsync.when(
              data: (customers) {
                final customer = customers
                    .where((c) => c.id == returnData.customerId)
                    .firstOrNull;
                return Text(
                  '客户: ${customer?.name ?? '未知'}',
                  style: const TextStyle(color: Colors.grey),
                );
              },
              loading: () => const Text('客户: 加载中...'),
              error: (_, _) => const Text('客户: 加载失败'),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(returnData.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (returnData.reason != null && returnData.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '退货原因: ${returnData.reason}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '退款金额: ',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '￥${returnData.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
