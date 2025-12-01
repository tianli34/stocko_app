import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart'; // 导入 collection 包
import '../../../product/domain/model/product.dart';
import '../../../../config/flavor_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/inbound_list_provider.dart';
import '../../../purchase/application/provider/supplier_providers.dart';
import '../../application/service/inbound_service.dart';
import '../../../purchase/domain/model/supplier.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../widgets/inbound_item_card.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/sound_helper.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../../core/models/scanned_product_payload.dart';
import '../../../../core/widgets/custom_date_picker.dart';

enum InboundMode { purchase, nonPurchase }

/// 新建入库单页面
class CreateInboundScreen extends ConsumerStatefulWidget {
  final ScannedProductPayload? payload;
  const CreateInboundScreen({super.key, this.payload});

  @override
  ConsumerState<CreateInboundScreen> createState() =>
      _CreateInboundScreenState();
}

class _CreateInboundScreenState extends ConsumerState<CreateInboundScreen> {
  final _remarksController = TextEditingController();
  final _supplierController = TextEditingController();
  final _sourceController = TextEditingController(); // 为'来源'新增Controller

  InboundMode _currentMode = InboundMode.purchase; // 默认是采购模式
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
      ref.read(inboundListProvider.notifier).clear();
      // 接收来自首页或其他页面的扫码货品，自动添加到入库清单
      final p = widget.payload;
      if (p != null) {
        try {
          ref
              .read(inboundListProvider.notifier)
              .addOrUpdateItem(
                product: p.product,
                unitId: p.unitId,
                unitName: p.unitName,
                conversionRate: p.conversionRate,
                barcode: p.barcode,
                wholesalePriceInCents: p.wholesalePriceInCents,
              );
          // 可选：提示已添加
          // showAppSnackBar(context, message: '已添加：${p.product.name}');
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _supplierController.dispose();
    _sourceController.dispose();
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
    final inboundItems = ref.read(inboundListProvider);
    if (index >= inboundItems.length) return;

    final item = inboundItems[index];
    final productAsync = ref.read(productByIdProvider(item.productId));

    productAsync.when(
      data: (product) async {
        if (product?.enableBatchManagement == true) {
          _amountFocusNodes[index].unfocus();
          final pickedDate = await _selectProductionDate(item);
          if (pickedDate != null) {
            final updatedItem = item.copyWith(productionDate: pickedDate);
            ref.read(inboundListProvider.notifier).updateItem(updatedItem);
          }
        }
        _moveToNextQuantity(index);
      },
      loading: () => _moveToNextQuantity(index),
      error: (_, __) => _moveToNextQuantity(index),
    );
  }

  void _moveToNextQuantity(int index) {
    final itemCount = ref.read(inboundListProvider).length;
    if (index + 1 < itemCount) {
      _quantityFocusNodes[index + 1].requestFocus();
    }
  }

  Future<DateTime?> _selectProductionDate(InboundItemState item) async {
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
      final List<
        ({
          ProductModel product,
          int unitId,
          String unitName,
          int conversionRate,
          int? sellingPriceInCents,
          int? wholesalePriceInCents,
        })
      >
      productsWithUnit = await ref.read(allProductsWithUnitProvider.future);

      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        ref
            .read(inboundListProvider.notifier)
            .addOrUpdateItem(
              product: p.product,
              unitId: p.unitId,
              unitName: p.unitName,
              conversionRate: p.conversionRate,
              wholesalePriceInCents: p.wholesalePriceInCents,
            );
      }
    } catch (e) {
      // 捕获并处理可能的异常
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: '添加货品失败: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _scanToAddProduct() async {
    final barcode = await BarcodeScannerService.scan(
      context,
      config: const BarcodeScannerConfig(
        title: '扫码添加货品',
        subtitle: '扫描货品条码以添加入库单',
      ),
    );
    if (barcode != null) {
      _handleSingleProductScan(barcode);
    }
  }

  void _continuousScan() {
    _lastScannedBarcode = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerService.scannerBuilder(
          config: const BarcodeScannerConfig(
            title: '连续扫码',
            subtitle: '将条码对准扫描框，自动连续添加',
            continuousMode: true,
            continuousDelay: 1500,
            showScanHistory: true,
            maxHistoryItems: 20,
          ),
          onBarcodeScanned: _handleContinuousProductScan,
          getProductInfo: (barcode) async {
            try {
              final productOperations = ref.read(productOperationsProvider.notifier);
              final result = await productOperations.getProductWithUnitByBarcode(barcode);
              if (result != null) {
                return (
                  name: result.product.name,
                  unitName: result.unitName,
                  conversionRate: result.conversionRate,
                );
              }
              return null;
            } catch (e) {
              return null;
            }
          },
        ),
      ),
    );
  }

  /// 获取供应商信息（采购模式共用）
  ({int? supplierId, String? supplierName}) _getSupplierInfo() {
    if (_selectedSupplier != null) {
      return (supplierId: _selectedSupplier!.id, supplierName: _selectedSupplier!.name);
    } else {
      return (supplierId: null, supplierName: _supplierController.text.trim());
    }
  }

  /// 仅采购（不入库）
  void _confirmPurchaseOnly() async {
    if (_isProcessing) return;
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

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
      final inboundService = ref.read(inboundServiceProvider);
      final supplierInfo = _getSupplierInfo();
      final inboundItems = ref.read(inboundListProvider);

      final orderNumber = await inboundService.processPurchaseOnly(
        shopId: _selectedShop!.id!,
        inboundItems: inboundItems,
        supplierId: supplierInfo.supplierId,
        supplierName: supplierInfo.supplierName,
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 采购成功！采购单号：$orderNumber');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.inventoryPurchaseRecords);
        }
      });
    } catch (e, st) {
      Navigator.of(context).pop();
      debugPrint('❌ 采购失败: $e');
      debugPrintStack(stackTrace: st);
      showAppSnackBar(
        context,
        message: '❌ 采购失败: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmInbound() async {
    if (_isProcessing) return;
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

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
      final inboundService = ref.read(inboundServiceProvider);
      final String source;
      final int? supplierId;
      final String? supplierName;
      final bool isPurchaseMode = _currentMode == InboundMode.purchase;

      if (isPurchaseMode) {
        source = '采购';
        final supplierInfo = _getSupplierInfo();
        supplierId = supplierInfo.supplierId;
        supplierName = supplierInfo.supplierName;
      } else {
        // 非采购模式
        source = _sourceController.text.trim().isEmpty
            ? '非采购'
            : _sourceController.text.trim();
        supplierId = null;
        supplierName = null;
      }

      // 直接使用原始的入库项目列表，不进行合并
      // 这样可以保留不同包装单位的商品记录，与销售记录的方式一致
      final inboundItems = ref.read(inboundListProvider);

      final receiptNumber = await inboundService.processOneClickInbound(
        shopId: _selectedShop!.id!,
        inboundItems: inboundItems,
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        // 新增和修改的参数
        source: source,
        isPurchaseMode: isPurchaseMode,
        supplierId: supplierId,
        supplierName: supplierName,
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 一键入库成功！入库单号：$receiptNumber');

      // 核心修复：使入库记录和库存查询的Provider失效，以便在导航后刷新数据
      ref.invalidate(inboundRecordsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // 使用 go 而不是 push, 以替换当前页面，而不是堆叠
          context.go(AppRoutes.inventoryInboundRecords);
        }
      });
    } catch (e, st) {
      Navigator.of(context).pop();
      // 打印详细堆栈以定位真正的抛错位置
      debugPrint('❌ 一键入库失败: $e');
      debugPrintStack(stackTrace: st);
      showAppSnackBar(
        context,
        message: '❌ 一键入库失败: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleSingleProductScan(String barcode) async {
    showAppSnackBar(context, message: '正在查询货品信息...');

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
            .read(inboundListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              conversionRate: result.conversionRate,
              barcode: barcode,
              wholesalePriceInCents: result.wholesalePriceInCents,
            );
        // 成功添加商品后播放音效
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
      } else {
        // 如果没有找到产品，显示对话框
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      // 关闭扫码页面
      Navigator.of(context).pop();
      // 显示错误信息
      showAppSnackBar(context, message: '❌ 查询货品失败: $e', isError: true);
    }
  }

  void _handleContinuousProductScan(String barcode) async {
    // 在连续扫码模式下，不显示全局的加载提示，而是快速反馈
    showAppSnackBar(context, message: '条码: $barcode...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      if (!mounted) return;

      if (result != null) {
        ref
            .read(inboundListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              conversionRate: result.conversionRate,
              barcode: barcode,
              wholesalePriceInCents: result.wholesalePriceInCents,
            );
        _lastScannedBarcode = barcode; // 仅在成功时更新上一个条码
        // 成功添加商品后播放音效和震动反馈
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        // 成功添加后给予一个更明确的提示
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        _lastScannedBarcode = null; // 如果未找到，则允许立即重扫
        // 未找到货品时给予一个失败提示
        showAppSnackBar(
          context,
          message: '❌ 未找到条码对应的货品: $barcode',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _lastScannedBarcode = null; // 如果出错，则允许立即重扫
      showAppSnackBar(context, message: '❌ 查询失败: $e', isError: true);
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
    if (_currentMode == InboundMode.purchase) {
      if (_selectedSupplier == null &&
          _supplierController.text.trim().isEmpty) {
        showAppSnackBar(context, message: '请选择或输入供应商名称', isError: true);
        return false;
      }
    }
    if (_selectedShop == null) {
      showAppSnackBar(context, message: '请选择入库店铺', isError: true);
      return false;
    }
    final inboundItems = ref.read(inboundListProvider);
    if (inboundItems.isEmpty) {
      showAppSnackBar(context, message: '请先添加货品', isError: true);
      return false;
    }
    for (final item in inboundItems) {
      if (item.quantity <= 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的数量必须大于0',
          isError: true,
        );
        return false;
      }
      if (_currentMode == InboundMode.purchase && item.unitPriceInSis < 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的单价不能为负数',
          isError: true,
        );
        return false;
      }
      // 采购模式下，单价不能为0
      if (_currentMode == InboundMode.purchase && item.unitPriceInSis == 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的单价不能为0',
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final inboundItemIds = ref.watch(
      inboundListProvider.select((items) => items.map((e) => e.id).toList()),
    );
    final totals = ref.watch(inboundTotalsProvider);
    final totalVarieties = totals['varieties']?.toInt() ?? 0;
    final totalQuantity = totals['quantity']?.toInt() ?? 0;
    final totalAmount = totals['amount'] ?? 0.0;

    _ensureFocusNodes(inboundItemIds.length);

    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: AppBar(
            leading: !canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                    tooltip: '返回',
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentMode == InboundMode.purchase ? '采购入库' : '非采购入库'),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_outlined),
                  tooltip: '切换模式',
                  onPressed: () {
                    setState(() {
                      _currentMode = _currentMode == InboundMode.purchase
                          ? InboundMode.nonPurchase
                          : InboundMode.purchase;
                    });
                  },
                ),
              ],
            ),
            actions: [const SizedBox(width: 8)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderSection(theme, textTheme),
                const SizedBox(height: 0),
                if (inboundItemIds.isEmpty)
                  _buildEmptyState(theme, textTheme)
                else
                  ...inboundItemIds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final itemId = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: InboundItemCard(
                        key: ValueKey(itemId),
                        itemId: itemId,
                        showPriceInfo:
                            _currentMode == InboundMode.purchase, // 新增
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
                const SizedBox(height: 0),
                _buildActionButtons(theme, textTheme),
                const SizedBox(height: 4),
                _buildTotalsBar(
                  theme,
                  textTheme,
                  totalVarieties,
                  totalQuantity,
                  totalAmount,
                ),
                const SizedBox(height: 4),
                _buildBottomAppBar(theme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 123, horizontal: 24),
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
            '请使用下方按钮添加货品到入库单',
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
              padding: const EdgeInsets.symmetric(vertical: 0),
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
              padding: const EdgeInsets.symmetric(vertical: 0),
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
              padding: const EdgeInsets.symmetric(vertical: 0),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
          if (_currentMode == InboundMode.purchase)
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
    final isPurchaseMode = _currentMode == InboundMode.purchase;
    
    if (isPurchaseMode) {
      // 采购模式：显示两个按钮
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _confirmPurchaseOnly,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout, size: 20),
              label: Text(
                _isProcessing ? '处理中...' : '采购',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirmInbound,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isProcessing ? '处理中...' : '一键入库',
                style: textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      );
    } else {
      // 非采购模式：只显示一键入库按钮
      return ElevatedButton.icon(
        onPressed: _isProcessing ? null : _confirmInbound,
        icon: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
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
          padding: const EdgeInsets.symmetric(vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }
  }

  Widget _buildHeaderSection(ThemeData theme, TextTheme textTheme) {
    final allShopsAsync = ref.watch(allShopsProvider);
    final flavor = ref.watch(flavorConfigProvider).flavor;
    final isGeneric = flavor == AppFlavor.generic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        allShopsAsync.when(
          data: (shops) {
            if (_selectedShop == null) {
              final defaultShopName = isGeneric ? '我的店铺' : '长山的店';
              final defaultShop = shops.firstWhereOrNull(
                (shop) => shop.name == defaultShopName,
              );
              if (defaultShop != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedShop = defaultShop;
                    });
                  }
                });
              }
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isGeneric)
              IntrinsicWidth(
                child: allShopsAsync.when(
                  data: (shops) {
                    return DropdownButtonFormField<Shop>(
                    key: const Key('shop_dropdown'),
                    focusNode: _shopFocusNode,
                    value: _selectedShop,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    items: shops
                        .map(
                          (shop) => DropdownMenuItem(
                            value: shop,
                            child: Text(shop.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedShop = value;
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('无法加载店铺: $err'),
                ),
              ),
            if (!isGeneric) const SizedBox(width: 16),
            Expanded(
              child: _currentMode == InboundMode.purchase
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('供应商:', style: const TextStyle(fontSize: 17)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TypeAheadField<Supplier>(
                            key: const Key('supplier_typeahead'),
                            controller: _supplierController,
                            focusNode: _supplierFocusNode,
                            suggestionsCallback: (pattern) async {
                              return await ref.read(
                                searchSuppliersProvider(pattern).future,
                              );
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion.name),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                              );
                            },
                            onSelected: (suggestion) {
                              setState(() {
                                _selectedSupplier = suggestion;
                                _supplierController.text = suggestion.name;
                              });
                              // 移除焦点转移，让用户自然操作
                              _supplierFocusNode.unfocus();
                            },
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText: '搜索或选择',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('来源:', style: const TextStyle(fontSize: 17)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _sourceController,
                            style: const TextStyle(fontSize: 15.5),
                            decoration: const InputDecoration(
                              hintText: '输入货品来源 (可选)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Divider(color: theme.colorScheme.outline.withOpacity(0.5)),
      ],
    );
  }
}
