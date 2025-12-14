import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../application/provider/stocktake_providers.dart';
import '../../application/stocktake_service.dart';
import '../../domain/model/stocktake_status.dart';
import '../widgets/stocktake_item_card.dart';
import '../widgets/stocktake_summary_bar.dart';
import '../widgets/add_stocktake_item_dialog.dart';

/// 盘点录入页面
class StocktakeEntryScreen extends ConsumerStatefulWidget {
  final int stocktakeId;

  const StocktakeEntryScreen({super.key, required this.stocktakeId});

  @override
  ConsumerState<StocktakeEntryScreen> createState() =>
      _StocktakeEntryScreenState();
}

class _StocktakeEntryScreenState extends ConsumerState<StocktakeEntryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(currentStocktakeProvider(widget.stocktakeId));
    final itemsAsync = ref.watch(stocktakeItemsProvider(widget.stocktakeId));
    final summaryAsync = ref.watch(stocktakeSummaryProvider(widget.stocktakeId));

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('盘点录入')),
            body: const Center(child: Text('盘点单不存在')),
          );
        }

        // 如果是草稿状态，自动开始盘点
        if (order.status == StocktakeStatus.draft) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(stocktakeServiceProvider).startStocktake(widget.stocktakeId);
            ref.invalidate(currentStocktakeProvider(widget.stocktakeId));
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('盘点 ${order.orderNumber}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _showScanner(context, order.shopId),
                tooltip: '扫码录入',
              ),
            ],
          ),
          body: Column(
            children: [
              // 汇总栏
              summaryAsync.when(
                data: (summary) => StocktakeSummaryBar(summary: summary),
                loading: () => const SizedBox(height: 60),
                error: (_, __) => const SizedBox(height: 60),
              ),

              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索商品名称或条码',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddDialog(context, order.shopId),
                      tooltip: '手动添加',
                    ),
                  ),
                  onSubmitted: (value) => _searchAndAdd(value, order.shopId),
                ),
              ),

              // 盘点项列表
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无盘点项',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '扫码或搜索添加商品',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return StocktakeItemCard(
                          item: item,
                          onQuantityChanged: (quantity) {
                            ref
                                .read(stocktakeEntryNotifierProvider(
                                        (stocktakeId: widget.stocktakeId, shopId: order.shopId))
                                    .notifier)
                                .updateQuantity(item.id!, quantity);
                          },
                          onDelete: () {
                            ref
                                .read(stocktakeEntryNotifierProvider(
                                        (stocktakeId: widget.stocktakeId, shopId: order.shopId))
                                    .notifier)
                                .deleteItem(item.id!);
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('加载失败: $error')),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _completeStocktake(context, order.shopId),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('完成盘点'),
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('盘点录入')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('盘点录入')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  void _showScanner(BuildContext context, int shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: UniversalBarcodeScanner(
          config: const BarcodeScannerConfig(
            title: '扫描商品条码',
            subtitle: '将条码对准扫描框进行盘点',
          ),
          onBarcodeScanned: (barcode) async {
            Navigator.pop(context);
            await _handleBarcode(barcode, shopId);
          },
        ),
      ),
    );
  }

  Future<void> _handleBarcode(String barcode, int shopId) async {
    // 根据条码查找商品
    final products = await ref.read(allProductsProvider.future);
    final product = products.firstWhere(
      (p) => p.sku == barcode,
      orElse: () => products.first,
    );

    if (mounted) {
      _showQuantityDialog(context, product.id!, product.name, shopId);
    }
  }

  void _showAddDialog(BuildContext context, int shopId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddStocktakeItemDialog(
        stocktakeId: widget.stocktakeId,
        shopId: shopId,
      ),
    );
  }

  Future<void> _searchAndAdd(String query, int shopId) async {
    if (query.isEmpty) return;

    final products = await ref.read(allProductsProvider.future);
    final matches = products.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        (p.sku?.contains(query) ?? false));

    if (matches.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到匹配的商品')),
        );
      }
      return;
    }

    if (matches.length == 1) {
      final product = matches.first;
      if (mounted) {
        _showQuantityDialog(context, product.id!, product.name, shopId);
      }
    } else {
      if (mounted) {
        _showAddDialog(context, shopId);
      }
    }

    _searchController.clear();
  }

  void _showQuantityDialog(
      BuildContext context, int productId, String productName, int shopId) {
    final controller = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(productName),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '实盘数量',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 0;
              ref
                  .read(stocktakeEntryNotifierProvider(
                          (stocktakeId: widget.stocktakeId, shopId: shopId))
                      .notifier)
                  .addItem(productId: productId, actualQuantity: quantity);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeStocktake(BuildContext context, int shopId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完成盘点'),
        content: const Text('确定要完成盘点吗？完成后将无法继续添加商品。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final summary = await ref
          .read(stocktakeEntryNotifierProvider(
                  (stocktakeId: widget.stocktakeId, shopId: shopId))
              .notifier)
          .completeStocktake();

      if (summary != null && mounted) {
        context.pushReplacement('/stocktake/${widget.stocktakeId}/diff');
      }
    }
  }
}
