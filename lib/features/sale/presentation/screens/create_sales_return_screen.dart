import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/sales_return_providers.dart';
import '../../application/service/sales_return_service.dart';
import '../../../product/data/repository/product_repository.dart' show watchProductByIdProvider;

class CreateSalesReturnScreen extends ConsumerStatefulWidget {
  final int salesTransactionId;
  final int shopId;

  const CreateSalesReturnScreen({
    super.key,
    required this.salesTransactionId,
    required this.shopId,
  });

  @override
  ConsumerState<CreateSalesReturnScreen> createState() => _CreateSalesReturnScreenState();
}

class _CreateSalesReturnScreenState extends ConsumerState<CreateSalesReturnScreen> {
  final _reasonController = TextEditingController();
  final _remarksController = TextEditingController();
  final Map<int, int> _returnQuantities = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnableItemsAsync = ref.watch(returnableItemsProvider(widget.salesTransactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建退货单'),
      ),
      body: returnableItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    '该订单已全部退货',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return _buildContent(items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildContent(List<ReturnableItem> items) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '选择退货商品',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _buildReturnItemCard(item)),
              const SizedBox(height: 24),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: '退货原因',
                  hintText: '请输入退货原因',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '可选',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildReturnItemCard(ReturnableItem item) {
    final productAsync = ref.watch(watchProductByIdProvider(item.productId));
    final returnQty = _returnQuantities[item.salesTransactionItemId] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productAsync.when(
              data: (product) => Text(
                product?.name ?? '商品ID: ${item.productId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              loading: () => const Text('加载中...'),
              error: (_, _) => Text('商品ID: ${item.productId}'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '单价: ￥${(item.priceInCents / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  '可退: ${item.returnableQuantity}',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('退货数量: '),
                IconButton(
                  onPressed: returnQty > 0
                      ? () {
                          setState(() {
                            _returnQuantities[item.salesTransactionItemId] = returnQty - 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$returnQty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: returnQty < item.returnableQuantity
                      ? () {
                          setState(() {
                            _returnQuantities[item.salesTransactionItemId] = returnQty + 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _returnQuantities[item.salesTransactionItemId] = item.returnableQuantity;
                    });
                  },
                  child: const Text('全部退货'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final returnableItemsAsync = ref.watch(returnableItemsProvider(widget.salesTransactionId));
    
    double totalRefund = 0;
    int totalItems = 0;
    
    returnableItemsAsync.whenData((items) {
      for (final item in items) {
        final qty = _returnQuantities[item.salesTransactionItemId] ?? 0;
        if (qty > 0) {
          totalRefund += qty * item.priceInCents / 100;
          totalItems += qty;
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '退货: $totalItems 件',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '退款: ￥${totalRefund.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: totalItems > 0 && !_isSubmitting ? _submitReturn : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认退货'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReturn() async {
    final returnableItemsAsync = ref.read(returnableItemsProvider(widget.salesTransactionId));
    
    final items = returnableItemsAsync.valueOrNull;
    if (items == null) return;

    final returnItems = <SalesReturnItemInput>[];
    for (final item in items) {
      final qty = _returnQuantities[item.salesTransactionItemId] ?? 0;
      if (qty > 0) {
        returnItems.add(SalesReturnItemInput(
          salesTransactionItemId: item.salesTransactionItemId,
          productId: item.productId,
          unitId: item.unitId,
          batchId: item.batchId,
          quantity: qty,
          priceInCents: item.priceInCents,
        ));
      }
    }

    if (returnItems.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(salesReturnServiceProvider);
      final receiptNumber = await service.processSalesReturn(
        salesTransactionId: widget.salesTransactionId,
        shopId: widget.shopId,
        returnItems: returnItems,
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退货成功: $receiptNumber'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退货失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
