import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/inbound_record_card.dart';
import '../providers/inbound_records_provider.dart';

/// 入库记录页面
/// 展示所有入库记录，支持查看详情
class InboundRecordsScreen extends ConsumerWidget {
  const InboundRecordsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboundRecordsAsync = ref.watch(inboundRecordsProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'), // 导航到应用首页
            tooltip: '返回首页',
          ),
          title: const Text('入库记录'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
        ),
        body: Column(
          children: [
            // 记录列表
            Expanded(
              child: inboundRecordsAsync.when(
                data: (records) => records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无入库记录',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InboundRecordCard(
                              record: _convertToMapFormat(record),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败：$error',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(inboundRecordsProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // 悬浮操作按钮 - 查询库存
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.inventoryQuery),
          icon: const Icon(Icons.search),
          label: const Text('查询库存'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// 将InboundRecordData转换为Map格式，兼容现有的InboundRecordCard
  Map<String, dynamic> _convertToMapFormat(InboundRecordData record) {
    return {
      'id': record.id,
      'shopName': record.shopName,
      'date': record.date,
      'productCount': record.productCount,
      'totalQuantity': record.totalQuantity,
      'status': record.status,
    };
  }
}
