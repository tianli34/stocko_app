import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart'; // 导入 collection 包
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/purchase_list_provider.dart';
import '../../application/provider/supplier_providers.dart';
import '../../application/service/purchase_service.dart';
import '../../domain/model/purchase_item.dart';
import '../../domain/model/supplier.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../widgets/purchase_item_card.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../../core/widgets/custom_date_picker.dart';

// 常量定义
const Duration _kSnackBarDuration = Duration(seconds: 3);
const Duration _kShortSnackBarDuration = Duration(milliseconds: 1500);

/// 新建采购单页面
class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final _remarksController = TextEditingController();
  final _supplierController = TextEditingController();

  Supplier? _selectedSupplier;
  Shop? _selectedShop;
  bool _isProcessing = false;
  String? _lastScannedBarcode;

  final FocusNode _shopFocusNode = FocusNode();
  final FocusNode _supplierFocusNode = FocusNode();
  final List<FocusNode> _quantityFocusNodes = [];
  final List<FocusNode> _amountFocusNodes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseListProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _supplierController.dispose();
    _shopFocusNode.dispose();
    _supplierFocusNode.dispose();
    for (var node in _quantityFocusNodes) {
      node.dispose();
    }
    for (var node in _amountFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _ensureFocusNodes(int itemCount) {
    while (_quantityFocusNodes.length < itemCount) {
      _quantityFocusNodes.add(FocusNode());
    }
    while (_amountFocusNodes.length < itemCount) {
      _amountFocusNodes.add(FocusNode());
    }
  }

  Future<void> _handleNextStep(int index) async {
    final purchaseItems = ref.read(purchaseListProvider);
    if (index >= purchaseItems.length) return;

    final item = purchaseItems[index];
    final productAsync = ref.read(productByIdProvider(item.productId));

    productAsync.when(
      data: (product) async {
        if (product?.enableBatchManagement == true) {
          _amountFocusNodes[index].unfocus();
          final pickedDate = await _selectProductionDate(item);
          if (pickedDate != null) {
            final updatedItem = item.copyWith(productionDate: pickedDate);
            ref.read(purchaseListProvider.notifier).updateItem(updatedItem);
          }
        }
        _moveToNextQuantity(index);
      },
      loading: () => _moveToNextQuantity(index),
      error: (_, __) => _moveToNextQuantity(index),
    );
  }

  void _moveToNextQuantity(int index) {
    final itemCount = ref.read(purchaseListProvider).length;
    if (index + 1 < itemCount) {
      _quantityFocusNodes[index + 1].requestFocus();
    }
  }

  Future<DateTime?> _selectProductionDate(PurchaseItem item) async {
    return await CustomDatePicker.show(
      context: context,
      initialDate: item.productionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: '选择生产日期',
    );
  }

  void _addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    // 如果没有返回结果或结果为空，则直接返回
    if (result == null || result.isEmpty) return;

    try {
      // 核心修复：
      // 使用 `ref.read(provider.future)` 来异步等待数据加载完成。
      // 这可以确保无论 `allProductsWithUnitProvider` 是否已缓存数据，
      // 我们都能在获取到数据后再执行后续逻辑，从而修复首次加载时数据未就绪的bug。
      final productsWithUnit = await ref.read(
        allProductsWithUnitProvider.future,
      );

      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        ref
            .read(purchaseListProvider.notifier)
            .addOrUpdateItem(product: p.product, unitName: p.unitName);
      }
    } catch (e) {
      // 捕获并处理可能的异常
      if (!mounted) return;
      _showErrorMessage('添加货品失败: ${e.toString()}');
    }
  }

  void _scanToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: UniversalBarcodeScanner(
              config: const BarcodeScannerConfig(
                title: '扫码添加货品',
                subtitle: '扫描货品条码以添加到采购单',
              ),
              onBarcodeScanned: _handleSingleProductScan,
            ),
          ),
        ),
      ),
    );
  }

  void _continuousScan() {
    _lastScannedBarcode = null; // 重置上次扫描的条码
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: UniversalBarcodeScanner(
              config: const BarcodeScannerConfig(
                title: '连续扫码',
                subtitle: '将条码对准扫描框，自动连续添加',
                continuousMode: true, // 启用连续扫码模式
                continuousDelay: 1500, // 设置扫码间隔
              ),
              onBarcodeScanned: _handleContinuousProductScan,
            ),
          ),
        ),
      ),
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存草稿功能待实现')));
  }

  void _confirmPurchase() async {
    if (_isProcessing) return;
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

    String? supplierId;
    String? supplierName;

    if (_selectedSupplier != null) {
      supplierId = _selectedSupplier!.id;
      supplierName = _selectedSupplier!.name;
    } else {
      supplierId = 'supplier_${DateTime.now().millisecondsSinceEpoch}';
      supplierName = _supplierController.text.trim();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(width: 24),
              Text('正在处理...', style: theme.textTheme.titleMedium),
            ],
          ),
        );
      },
    );

    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final receiptNumber = await purchaseService.processOneClickInbound(
        supplierId: supplierId,
        shopId: _selectedShop!.id,
        purchaseItems: ref.read(purchaseListProvider),
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        supplierName: supplierName,
      );

      Navigator.of(context).pop();
      _showSuccessMessage('✅ 一键入库成功！入库单号：$receiptNumber');

      // 核心修复：使入库记录和库存查询的Provider失效，以便在导航后刷新数据
      ref.invalidate(inboundRecordsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // 使用 go 而不是 push, 以替换当前页面，而不是堆叠
          context.go(AppRoutes.inventoryInboundRecords);
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorMessage('❌ 一键入库失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleSingleProductScan(String barcode) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(width: 16),
            const Text('正在查询货品信息...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      if (!mounted) return;

      // 无论成功与否，都先关闭扫码页面
      Navigator.of(context).pop();

      if (result != null) {
        ref
            .read(purchaseListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitName: result.unitName,
              barcode: barcode,
            );
      } else {
        // 如果没有找到产品，显示对话框
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      // 关闭扫码页面
      Navigator.of(context).pop();
      // 显示错误信息
      _showErrorMessage('❌ 查询货品失败: $e');
    }
  }

  void _handleContinuousProductScan(String barcode) async {
    // 连续扫码去重：如果条码与上一个相同，则忽略
    if (barcode == _lastScannedBarcode) {
      return;
    }

    // 在连续扫码模式下，不显示全局的加载提示，而是快速反馈
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text('条码: $barcode...')),
          ],
        ),
        duration: _kShortSnackBarDuration,
      ),
    );

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      if (!mounted) return;

      if (result != null) {
        ref
            .read(purchaseListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitName: result.unitName,
              barcode: barcode,
            );
        _lastScannedBarcode = barcode; // 仅在成功时更新上一个条码
        // 成功添加后给予一个更明确的提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.product.name} 已添加'),
            backgroundColor: Colors.green[600],
            duration: _kShortSnackBarDuration,
          ),
        );
      } else {
        _lastScannedBarcode = null; // 如果未找到，则允许立即重扫
        // 未找到货品时给予一个失败提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 未找到条码对应的货品: $barcode'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: _kShortSnackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _lastScannedBarcode = null; // 如果出错，则允许立即重扫
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 查询失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: _kShortSnackBarDuration,
        ),
      );
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        return AlertDialog(
          title: Text('货品未找到', style: textTheme.titleLarge),
          content: Text(
            '条码 $barcode 对应的货品未在系统中找到。',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    if (_selectedSupplier == null && _supplierController.text.trim().isEmpty) {
      _showErrorMessage('请选择或输入供应商名称');
      return false;
    }
    if (_selectedShop == null) {
      _showErrorMessage('请选择采购店铺');
      return false;
    }
    final purchaseItems = ref.read(purchaseListProvider);
    if (purchaseItems.isEmpty) {
      _showErrorMessage('请先添加采购货品');
      return false;
    }
    for (final item in purchaseItems) {
      if (item.quantity <= 0) {
        _showErrorMessage('货品"${item.productName}"的数量必须大于0');
        return false;
      }
      if (item.unitPrice < 0) {
        _showErrorMessage('货品"${item.productName}"的单价不能为负数');
        return false;
      }
    }
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: _kSnackBarDuration,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: _kSnackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final purchaseItemIds = ref.watch(
      purchaseListProvider.select((items) => items.map((e) => e.id).toList()),
    );
    final totals = ref.watch(purchaseTotalsProvider);
    final totalVarieties = totals['varieties']?.toInt() ?? 0;
    final totalQuantity = totals['quantity']?.toInt() ?? 0;
    final totalAmount = totals['amount'] ?? 0.0;

    _ensureFocusNodes(purchaseItemIds.length);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: '返回',
        ),
        title: const Text('新建采购单'),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: Text(
              '保存草稿',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(theme, textTheme),
            const SizedBox(height: 16),
            if (purchaseItemIds.isEmpty)
              _buildEmptyState(theme, textTheme)
            else
              ...purchaseItemIds.asMap().entries.map((entry) {
                final index = entry.key;
                final itemId = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PurchaseItemCard(
                    key: ValueKey(itemId),
                    itemId: itemId,
                    quantityFocusNode: _quantityFocusNodes.length > index
                        ? _quantityFocusNodes[index]
                        : null,
                    amountFocusNode: _amountFocusNodes.length > index
                        ? _amountFocusNodes[index]
                        : null,
                    onAmountSubmitted: () => _handleNextStep(index),
                  ),
                );
              }),
            const SizedBox(height: 16),
            _buildActionButtons(theme, textTheme),
            const SizedBox(height: 16),
            _buildTotalsBar(
              theme,
              textTheme,
              totalVarieties,
              totalQuantity,
              totalAmount,
            ),
            const SizedBox(height: 16),
            _buildBottomAppBar(theme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无货品',
            style: textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请使用下方按钮添加货品到采购单',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _addManualProduct,
            icon: const Icon(Icons.add, size: 18),
            label: Text('添加货品', style: textTheme.bodyMedium),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _scanToAddProduct,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text('扫码添加', style: textTheme.bodyMedium),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _continuousScan,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: Text('连续扫码', style: textTheme.bodyMedium),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsBar(
    ThemeData theme,
    TextTheme textTheme,
    int totalVarieties,
    int totalQuantity,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTotalItem(textTheme, '品种', totalVarieties.toString()),
          _buildTotalItem(textTheme, '总数', totalQuantity.toString()),
          _buildTotalItem(
            textTheme,
            '总金额',
            '¥${totalAmount.toStringAsFixed(2)}',
            isAmount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
    TextTheme textTheme,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isAmount
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar(ThemeData theme, TextTheme textTheme) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _confirmPurchase,
      icon: _isProcessing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.check_circle_outline, size: 24),
      label: Text(
        _isProcessing ? '正在入库...' : '一键入库',
        style: textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, TextTheme textTheme) {
    final allShopsAsync = ref.watch(allShopsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        allShopsAsync.when(
          data: (shops) {
            // 设置默认店铺为“长山的店”，如果它存在且尚未选择店铺
            if (_selectedShop == null) {
              final defaultShop = shops.firstWhereOrNull(
                (shop) => shop.name == '长山的店',
              );
              if (defaultShop != null) {
                // 使用WidgetsBinding.instance.addPostFrameCallback确保在UI更新后设置状态
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedShop = defaultShop;
                    });
                  }
                });
              }
            }
            return DropdownButtonFormField<Shop>(
              key: const Key('shop_dropdown'),
              focusNode: _shopFocusNode,
              value: _selectedShop,
              decoration: const InputDecoration(labelText: '采购店铺'),
              items: shops
                  .map(
                    (shop) =>
                        DropdownMenuItem(value: shop, child: Text(shop.name)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShop = value;
                });
              },
              // validator: (value) => value == null ? '请选择采购店铺' : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('无法加载店铺: $err'),
        ),
        const SizedBox(height: 16),

        TypeAheadField<Supplier>(
          key: const Key('supplier_typeahead'),
          controller: _supplierController,
          focusNode: _supplierFocusNode,
          suggestionsCallback: (pattern) async {
            return await ref.read(searchSuppliersProvider(pattern).future);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(title: Text(suggestion.name));
          },
          onSelected: (suggestion) {
            setState(() {
              _selectedSupplier = suggestion;
              _supplierController.text = suggestion.name;
            });
            _shopFocusNode.requestFocus();
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: '供应商',
                hintText: '搜索或选择一个供应商',
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // TextFormField(
        //   key: const Key('remarks_textfield'),
        //   controller: _remarksController,
        //   decoration: const InputDecoration(
        //     labelText: '备注',
        //     hintText: '输入采购单备注信息 (可选)',
        //     prefixIcon: Icon(Icons.notes_outlined),
        //   ),
        //   textCapitalization: TextCapitalization.sentences,
        // ),
        // const SizedBox(height: 16),
        Divider(color: theme.colorScheme.outline.withOpacity(0.5)),
      ],
    );
  }
}

// 连续扫码页面也需要重构以使用Provider，此处暂时省略
// class _SimpleContinuousScanPage ...
