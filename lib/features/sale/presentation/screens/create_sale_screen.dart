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
import '../../application/provider/sale_list_provider.dart';
import '../../application/provider/customer_providers.dart';
import '../../application/service/sale_service.dart';
import '../../domain/model/customer.dart';
import '../../domain/model/sales_transaction.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../inventory/presentation/providers/outbound_receipts_provider.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../widgets/sale_item_card.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/sound_helper.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../../core/models/scanned_product_payload.dart';

enum SaleMode { sale, nonSale }

/// 新建销售单页面
class CreateSaleScreen extends ConsumerStatefulWidget {
  final ScannedProductPayload? payload;
  const CreateSaleScreen({super.key, this.payload});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  final _remarksController = TextEditingController();
  final _customerController = TextEditingController();
  final _sourceController = TextEditingController(); // 为'来源'新增Controller
  final _paymentController = TextEditingController(); // 收款Controller

  final SaleMode _currentMode = SaleMode.sale; // 默认是销售模式
  Customer? _selectedCustomer;
  Shop? _selectedShop;
  bool _isProcessing = false;

  final FocusNode _shopFocusNode = FocusNode();
  final FocusNode _customerFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  // 每个条目的售价与数量 FocusNode 列表
  final List<FocusNode> _priceFocusNodes = [];
  final List<FocusNode> _quantityFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus) {
        _paymentController.clear();
      }
    });
    _paymentController.text = '0';
    _paymentController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleListProvider.notifier).clear();
      // 接收来自首页或其他页面的扫码货品，自动添加到销售清单
      final p = widget.payload;
      if (p != null) {
        // 如果是基本单位（conversionRate = 1），使用 Product 表的 effectivePrice
        // 否则使用 UnitProduct 表的 sellingPriceInCents
        final priceCents = p.conversionRate == 1
            ? (p.product.effectivePrice?.cents ?? 0)
            : (p.sellingPriceInCents ?? 0);
        try {
          ref
              .read(saleListProvider.notifier)
              .addOrUpdateItem(
                product: p.product,
                unitId: p.unitId,
                unitName: p.unitName,
                sellingPriceInCents: priceCents,
                conversionRate: p.conversionRate,
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
    _customerController.dispose();
    _sourceController.dispose();
    _paymentController.dispose();
    _shopFocusNode.dispose();
    _customerFocusNode.dispose();
    _paymentFocusNode.dispose();
    for (var node in _quantityFocusNodes) {
      node.dispose();
    }
    for (var node in _priceFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _ensureFocusNodes(int itemCount) {
    while (_quantityFocusNodes.length < itemCount) {
      _quantityFocusNodes.add(FocusNode());
    }
    while (_priceFocusNodes.length < itemCount) {
      _priceFocusNodes.add(FocusNode());
    }
    // 如果条目减少，不立刻销毁已存在的节点，避免异步 rebuild 期间访问已释放对象
  }

  Future<void> _handleNextStep(int index) async {
    final saleItems = ref.read(saleListProvider);
    if (index >= saleItems.length) return;

    _moveToNextQuantity(index);
  }

  void _moveToNextQuantity(int index) {
    final itemCount = ref.read(saleListProvider).length;
    if (index + 1 < itemCount) {
      // 跳到下一项的售价（先价格后数量）
      _priceFocusNodes[index + 1].requestFocus();
    } else {
      // 最后一项后跳到收款
      _paymentFocusNode.requestFocus();
    }
  }

  void _addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    // 如果没有返回结果或结果为空，则直接返回
    if (result == null || result.isEmpty) return;

    try {
      // 核心修复：安全获取产品数据
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
      productsWithUnit;

      try {
        productsWithUnit = await ref.read(allProductsWithUnitProvider.future);
      } catch (e) {
        print('获取产品单位数据失败: $e');
        if (!mounted) return;
        showAppSnackBar(context, message: '获取产品数据失败，请稍后重试', isError: true);
        return;
      }

      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        try {
          // 如果是基本单位（conversionRate = 1），使用 Product 表的 effectivePrice
          // 否则使用 UnitProduct 表的 sellingPriceInCents
          final sellingPrice = p.conversionRate == 1
              ? (p.product.effectivePrice?.cents ?? 0)
              : (p.sellingPriceInCents ?? 0);
          ref
              .read(saleListProvider.notifier)
              .addOrUpdateItem(
                product: p.product,
                unitId: p.unitId,
                unitName: p.unitName,
                sellingPriceInCents: sellingPrice,
                conversionRate: p.conversionRate,
              );
        } catch (e) {
          print('添加产品失败: ${p.product.name}, 错误: $e');
          // 继续处理下一个产品
        }
      }
    } catch (e) {
      // 捕获并处理可能的异常
      print('添加手动产品时发生错误: $e');
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
        subtitle: '扫描货品条码以添加销售单',
      ),
    );
    if (barcode != null) {
      _handleSingleProductScan(barcode);
    }
  }

  void _continuousScan() {
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

  void _confirmSale() async {
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
      final saleService = ref.read(saleServiceProvider);
      final int? customerId;
      final String? customerName;
      final bool isSaleMode = _currentMode == SaleMode.sale;

      if (isSaleMode) {
        if (_selectedCustomer != null) {
          customerId = _selectedCustomer!.id;
          customerName = _selectedCustomer!.name;
        } else {
          // 如果客户输入框为空，则将客户id置为0
          customerId = _customerController.text.trim().isEmpty ? 0 : null;
          customerName = _customerController.text.trim().isEmpty
              ? '匿名散客'
              : _customerController.text.trim();
        }
      } else {
        // 非销售模式
        customerId = null;
        customerName = null;
      }

      print('🔍 [DEBUG] UI: Starting processOneClickSale');
      print('🔍 [DEBUG] UI - _selectedShop: ${_selectedShop?.id ?? "null"}');
      print(
        '🔍 [DEBUG] UI - _selectedCustomer: ${_selectedCustomer?.id ?? "null"}',
      );
      print(
        '🔍 [DEBUG] UI - _customerController: "${_customerController.text}"',
      );
      print(
        '🔍 [DEBUG] UI - saleItems count: ${ref.read(saleListProvider).length}',
      );
      print('🔍 [DEBUG] UI - remarks: "${_remarksController.text}"');
      print('🔍 [DEBUG] UI - isSaleMode: $isSaleMode');
      print('🔍 [DEBUG] UI - customerId: ${customerId ?? "null"}');
      print('🔍 [DEBUG] UI - customerName: $customerName');

      final receiptNumber = await saleService.processOneClickSale(
        salesOrderNo: DateTime.now().millisecondsSinceEpoch,
        shopId: _selectedShop!.id!,
        saleItems: ref.read(saleListProvider),
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        // 新增和修改的参数
        isSaleMode: isSaleMode,
        customerId: customerId ?? 0,
        customerName: customerName,
        status: SalesStatus.preset, // 普通销售使用已结算状态
      );
      print(
        '🔍 [DEBUG] UI: processOneClickSale Settled, receipt: $receiptNumber',
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 销售成功！销售单号：$receiptNumber');

      // 核心修复：使入库记录和库存查询的Provider失效，以便在导航后刷新数据
      ref.invalidate(inboundRecordsProvider);
      // 同步刷新：使出库记录 Provider 失效，库存记录页的“出库记录”可自动更新
      ref.invalidate(outboundReceiptsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // 使用 go 而不是 push, 以替换当前页面，而不是堆叠
          context.go(AppRoutes.saleRecords);
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        message: '❌ 销售失败: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmCreditSale() async {
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
      final saleService = ref.read(saleServiceProvider);
      final int? customerId;
      final String? customerName;
      final bool isSaleMode = _currentMode == SaleMode.sale;

      if (isSaleMode) {
        if (_selectedCustomer != null) {
          customerId = _selectedCustomer!.id;
          customerName = _selectedCustomer!.name;
        } else {
          // 如果客户输入框为空，则将客户id置为0
          customerId = _customerController.text.trim().isEmpty ? 0 : null;
          customerName = _customerController.text.trim().isEmpty
              ? '匿名散客'
              : _customerController.text.trim();
        }
      } else {
        // 非销售模式
        customerId = null;
        customerName = null;
      }

      print('🔍 [DEBUG] UI: Starting processOneClickSale (Credit)');
      print('🔍 [DEBUG] UI - _selectedShop: ${_selectedShop?.id ?? "null"}');
      print(
        '🔍 [DEBUG] UI - _selectedCustomer: ${_selectedCustomer?.id ?? "null"}',
      );
      print(
        '🔍 [DEBUG] UI - _customerController: "${_customerController.text}"',
      );
      print(
        '🔍 [DEBUG] UI - saleItems count: ${ref.read(saleListProvider).length}',
      );
      print('🔍 [DEBUG] UI - remarks: "${_remarksController.text}"');
      print('🔍 [DEBUG] UI - isSaleMode: $isSaleMode');
      print('🔍 [DEBUG] UI - customerId: ${customerId ?? "null"}');
      print('🔍 [DEBUG] UI - customerName: $customerName');

      final receiptNumber = await saleService.processOneClickSale(
        salesOrderNo: DateTime.now().millisecondsSinceEpoch,
        shopId: _selectedShop!.id!,
        saleItems: ref.read(saleListProvider),
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        // 新增和修改的参数
        isSaleMode: isSaleMode,
        customerId: customerId ?? 0,
        customerName: customerName,
        status: SalesStatus.credit, // 设置为赊账状态
      );
      print(
        '🔍 [DEBUG] UI: processOneClickSale (Credit) Settled, receipt: $receiptNumber',
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 赊账成功！销售单号：$receiptNumber');

      // 核心修复：使入库记录和库存查询的Provider失效，以便在导航后刷新数据
      ref.invalidate(inboundRecordsProvider);
      // 同步刷新：使出库记录 Provider 失效，库存记录页的“出库记录”可自动更新
      ref.invalidate(outboundReceiptsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // 使用 go 而不是 push, 以替换当前页面，而不是堆叠
          context.go(AppRoutes.saleRecords);
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        message: '❌ 赊账失败: ${e.toString()}',
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
        // 如果是基本单位（conversionRate = 1），使用 Product 表的 effectivePrice
        // 否则使用 UnitProduct 表的 sellingPriceInCents
        final sellingPrice = result.conversionRate == 1
            ? (result.product.effectivePrice?.cents ?? 0)
            : (result.sellingPriceInCents ?? 0);
        ref
            .read(saleListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              sellingPriceInCents: sellingPrice,
              conversionRate: result.conversionRate,
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
        // 如果是基本单位（conversionRate = 1），使用 Product 表的 effectivePrice
        // 否则使用 UnitProduct 表的 sellingPriceInCents
        final sellingPrice = result.conversionRate == 1
            ? (result.product.effectivePrice?.cents ?? 0)
            : (result.sellingPriceInCents ?? 0);
        ref
            .read(saleListProvider.notifier)
            .addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              sellingPriceInCents: sellingPrice,
              conversionRate: result.conversionRate,
            );
        // 成功添加商品后播放音效和震动反馈
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        // 成功添加后给予一个更明确的提示
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        // 未找到货品时给予一个失败提示
        showAppSnackBar(
          context,
          message: '❌ 未找到条码对应的货品: $barcode',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
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
    if (_currentMode == SaleMode.sale) {
      // if (_selectedCustomer == null &&
      //     _customerController.text.trim().isEmpty) {
      //   showAppSnackBar(context, message: '请选择或输入客户名称', isError: true);
      //   return false;
      // }
    }
    if (_selectedShop == null) {
      showAppSnackBar(context, message: '请选择入库店铺', isError: true);
      return false;
    }
    final saleItems = ref.read(saleListProvider);
    if (saleItems.isEmpty) {
      showAppSnackBar(context, message: '请先添加货品', isError: true);
      return false;
    }
    for (final item in saleItems) {
      if (item.quantity <= 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的数量必须大于0',
          isError: true,
        );
        return false;
      }
      if (_currentMode == SaleMode.sale && item.sellingPriceInCents < 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的单价不能为负数',
          isError: true,
        );
        return false;
      }
      // 采购模式下，单价不能为0
      if (_currentMode == SaleMode.sale && item.sellingPriceInCents == 0) {
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

  Widget _buildPaymentAndChangeSection(
    ThemeData theme,
    TextTheme textTheme,
    double change,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('收款:', style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: TextFormField(
                  focusNode: _paymentFocusNode,
                  controller: _paymentController,
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: textTheme.titleMedium,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('找零:', style: textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    '¥ ${change.toStringAsFixed(1)}',
                    style: textTheme.titleLarge?.copyWith(
                      color: change < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final saleItemIds = ref.watch(
      saleListProvider.select((items) => items.map((e) => e.id).toList()),
    );
    final totals = ref.watch(saleTotalsProvider);
    final totalVarieties = totals['varieties']?.toInt() ?? 0;
    final totalQuantity = totals['quantity']?.toInt() ?? 0;
    final totalAmount = totals['amount'] ?? 0.0;

    // 根据总金额自动更新收款金额：收款 = 100 * ⌈总金额/100⌉
    if (!_paymentFocusNode.hasFocus) {
      final calculatedPayment = totalAmount > 0
          ? (totalAmount / 100).ceil() * 100.0
          : 0.0;
      if (_paymentController.text != calculatedPayment.toStringAsFixed(0)) {
        _paymentController.text = calculatedPayment.toStringAsFixed(0);
      }
    }

    final paymentAmount = double.tryParse(_paymentController.text) ?? 0.0;
    final change = paymentAmount - totalAmount;

    _ensureFocusNodes(saleItemIds.length);

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
            title: Row(mainAxisSize: MainAxisSize.min, children: [Text('收银台')]),
            actions: [const SizedBox(width: 8)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderSection(theme, textTheme),
                const SizedBox(height: 0),
                if (saleItemIds.isEmpty)
                  _buildEmptyState(theme, textTheme)
                else
                  ...saleItemIds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final itemId = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: SaleItemCard(
                        key: ValueKey(itemId),
                        itemId: itemId,
                        shopId: _selectedShop?.id,
                        showPriceInfo: _currentMode == SaleMode.sale, // 新增
                        // 价格与数量 FocusNode 注入，构建焦点链路
                        sellingPriceFocusNode: _priceFocusNodes.length > index
                            ? _priceFocusNodes[index]
                            : null,
                        quantityFocusNode: _quantityFocusNodes.length > index
                            ? _quantityFocusNodes[index]
                            : null,
                        // 当数量提交时，跳到下一项的售价或收款
                        onSubmitted: () => _handleNextStep(index),
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
                _buildPaymentAndChangeSection(theme, textTheme, change),
                const SizedBox(height: 4),
                _buildBottomAppBar(theme, textTheme),
                const SizedBox(height: 99), //底部留白以避免按钮被遮挡
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
          if (_currentMode == SaleMode.sale)
            _buildTotalItem(
              textTheme,
              '总金额',
              '¥${totalAmount.toStringAsFixed(1)}',
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
    return Row(
      children: [
        Expanded(
          flex: 2, // 赊账按钮占 2 份宽度
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmCreditSale,
            icon: _isProcessing
                ? const SizedBox(
                    width: 12,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.account_balance_wallet_outlined, size: 24),
            label: Text(
              _isProcessing ? '正在处理...' : '赊账',
              style: textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3, // 结账按钮占 3 份宽度
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmSale,
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
              _isProcessing ? '正在处理...' : '结账',
              style: textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
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
              child: _currentMode == SaleMode.sale
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('顾客:', style: const TextStyle(fontSize: 17)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TypeAheadField<Customer>(
                            key: const Key('customer_typeahead'),
                            controller: _customerController,
                            focusNode: _customerFocusNode,
                            suggestionsCallback: (pattern) async {
                              final allCustomers = await ref.read(
                                allCustomersProvider.future,
                              );
                              if (pattern.isEmpty) {
                                return allCustomers;
                              }
                              return allCustomers
                                  .where(
                                    (customer) => customer.name
                                        .toLowerCase()
                                        .contains(pattern.toLowerCase()),
                                  )
                                  .toList();
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
                                _selectedCustomer = suggestion;
                                _customerController.text = suggestion.name;
                              });
                              // 选中客户后失去焦点
                              _customerFocusNode.unfocus();
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
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  // 顾客后跳到首个售价；如果没有条目则跳到收款
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_priceFocusNodes.isNotEmpty) {
                                      _priceFocusNodes.first.requestFocus();
                                    } else {
                                      _paymentFocusNode.requestFocus();
                                    }
                                  });
                                },
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
