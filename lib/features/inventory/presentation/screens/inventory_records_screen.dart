import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/inbound_record_card.dart';
import '../providers/inbound_records_provider.dart';
import '../providers/outbound_receipts_provider.dart';
import '../widgets/outbound_record_card.dart';

/// 库存记录页面
/// 展示所有入库和出库记录，支持查看详情
class InventoryRecordsScreen extends ConsumerStatefulWidget {
  const InventoryRecordsScreen({super.key});

  @override
  ConsumerState<InventoryRecordsScreen> createState() =>
      _InventoryRecordsScreenState();
}

class _InventoryRecordsScreenState extends ConsumerState<InventoryRecordsScreen> {
  bool _isOutboundView = false; // false: 入库记录, true: 出库记录

  @override
  Widget build(BuildContext context) {
    final inboundRecordsAsync = ref.watch(inboundRecordsProvider);
  final outboundRecordsAsync = ref.watch(outboundReceiptsProvider);

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
          title: Text(_isOutboundView ? '出库记录' : '入库记录'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isOutboundView = !_isOutboundView;
                });
              },
              child: Text(_isOutboundView ? '看入库' : '看出库'),
            ),
          ],
        ),
        body: _isOutboundView
            ? outboundRecordsAsync.when(
                data: (records) => records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.outbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无出库记录',
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
                            child: OutboundRecordCard(record: record),
                          );
                        },
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
                        style:
                            const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
            onPressed: () =>
              ref.refresh(outboundReceiptsProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // 记录列表
                  Expanded(
                    child: inboundRecordsAsync.when(
                      data: (records) => records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inventory_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '暂无入库记录',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                    onPressed: () => context.go(AppRoutes.purchaseRecords),
                                    icon: const Icon(Icons.shopping_cart),
                                    label: const Text('查看采购记录'),
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
                                    record: record,
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  ref.refresh(inboundRecordsProvider),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        // 悬浮操作按钮
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'purchase',
              onPressed: () => context.go(AppRoutes.purchaseRecords),
              tooltip: '采购记录',
              child: const Icon(Icons.shopping_cart),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'query',
              onPressed: () => context.push(AppRoutes.inventoryQuery),
              icon: const Icon(Icons.search),
              label: const Text('查询库存'),
            ),
          ],
        ),
      ),
    );
  }
}
