import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../product/domain/model/product.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/mixins/product_scan_mixin.dart';
import '../../application/provider/sale_list_provider.dart';
import '../../application/provider/customer_providers.dart';
import '../../application/service/sale_service.dart';
import '../../domain/model/customer.dart';
import '../../domain/model/sales_transaction.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../inventory/presentation/providers/outbound_receipts_provider.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../widgets/sale_header_section.dart';
import '../widgets/payment_change_section.dart';
import '../widgets/sale_totals_bar.dart';
import '../widgets/sale_bottom_bar.dart';
import '../widgets/sale_action_buttons.dart';
import '../widgets/sale_cart_list.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/models/scanned_product_payload.dart';

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
  final _paymentController = TextEditingController();

  Customer? _selectedCustomer;
  Shop? _selectedShop;
  bool _isProcessing = false;

  final FocusNode _shopFocusNode = FocusNode();
  final FocusNode _customerFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
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
      _handleInitialPayload();
    });
  }

  void _handleInitialPayload() {
    final p = widget.payload;
    if (p == null) return;
    final priceCents = p.conversionRate == 1
        ? (p.product.effectivePrice?.cents ?? 0)
        : (p.sellingPriceInCents ?? 0);
    try {
      ref.read(saleListProvider.notifier).addOrUpdateItem(
            product: p.product,
            unitId: p.unitId,
            unitName: p.unitName,
            sellingPriceInCents: priceCents,
            conversionRate: p.conversionRate,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _customerController.dispose();
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
  }

  Future<void> _handleNextStep(int index) async {
    final saleItems = ref.read(saleListProvider);
    if (index >= saleItems.length) return;
    _moveToNextQuantity(index);
  }

  void _moveToNextQuantity(int index) {
    final itemCount = ref.read(saleListProvider).length;
    if (index + 1 < itemCount) {
      _priceFocusNodes[index + 1].requestFocus();
    } else {
      _paymentFocusNode.requestFocus();
    }
  }

  // ==================== 添加货品相关 ====================

  void _addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );
    if (result == null || result.isEmpty) return;

    try {
      final List<
              ({
                ProductModel product,
                int unitId,
                String unitName,
                int conversionRate,
                int? sellingPriceInCents,
                int? wholesalePriceInCents,
              })>
          productsWithUnit;

      try {
        productsWithUnit = await ref.read(allProductsWithUnitProvider.future);
      } catch (e) {
        if (!mounted) return;
        showAppSnackBar(context, message: '获取产品数据失败，请稍后重试', isError: true);
        return;
      }

      final selectedProducts =
          productsWithUnit.where((p) => result.contains(p.product.id)).toList();

      for (final p in selectedProducts) {
        try {
          final sellingPrice = p.conversionRate == 1
              ? (p.product.effectivePrice?.cents ?? 0)
              : (p.sellingPriceInCents ?? 0);
          ref.read(saleListProvider.notifier).addOrUpdateItem(
                product: p.product,
                unitId: p.unitId,
                unitName: p.unitName,
                sellingPriceInCents: sellingPrice,
                conversionRate: p.conversionRate,
              );
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: '添加货品失败: ${e.toString()}', isError: true);
    }
  }

  // ==================== 扫码相关 ====================

  void _scanToAddProduct() {
    ProductScanMixin.scanAndAddProduct(
      context: context,
      ref: ref,
      subtitle: '扫描货品条码以添加销售单',
      onProductScanned: (result) {
        final sellingPrice = result.conversionRate == 1
            ? (result.product.effectivePrice?.cents ?? 0)
            : (result.sellingPriceInCents ?? 0);
        ref.read(saleListProvider.notifier).addOrUpdateItem(
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          sellingPriceInCents: sellingPrice,
          conversionRate: result.conversionRate,
        );
      },
    );
  }

  void _continuousScan() {
    ProductScanMixin.continuousScanProduct(
      context: context,
      ref: ref,
      title: '连续扫码',
      subtitle: '将条码对准扫描框，自动连续添加',
      onProductScanned: (result) {
        final sellingPrice = result.conversionRate == 1
            ? (result.product.effectivePrice?.cents ?? 0)
            : (result.sellingPriceInCents ?? 0);
        ref.read(saleListProvider.notifier).addOrUpdateItem(
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          sellingPriceInCents: sellingPrice,
          conversionRate: result.conversionRate,
        );
      },
    );
  }

  // ==================== 销售确认 ====================

  bool _validateForm() {
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
        showAppSnackBar(context,
            message: '货品"${item.productName}"的数量必须大于0', isError: true);
        return false;
      }
      if (item.sellingPriceInCents < 0) {
        showAppSnackBar(context,
            message: '货品"${item.productName}"的单价不能为负数', isError: true);
        return false;
      }
      if (item.sellingPriceInCents == 0) {
        showAppSnackBar(context,
            message: '货品"${item.productName}"的单价不能为0', isError: true);
        return false;
      }
    }
    return true;
  }

  Future<void> _processSale(SalesStatus status) async {
    if (_isProcessing) return;
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);
    _showProcessingDialog();

    try {
      final saleService = ref.read(saleServiceProvider);
      final int customerId;
      final String customerName;

      if (_selectedCustomer != null) {
        customerId = _selectedCustomer!.id ?? 0;
        customerName = _selectedCustomer!.name;
      } else {
        final inputName = _customerController.text.trim();
        if (inputName.isEmpty) {
          customerId = 0;
          customerName = '匿名散客';
        } else {
          // 手动输入了新顾客名，先创建顾客记录
          final customerController = ref.read(customerControllerProvider.notifier);
          final newCustomer = Customer(name: inputName);
          await customerController.addCustomer(newCustomer);
          
          // 获取刚创建的顾客ID
          final allCustomers = await ref.read(allCustomersProvider.future);
          final createdCustomer = allCustomers.firstWhere((c) => c.name == inputName);
          customerId = createdCustomer.id ?? 0;
          customerName = inputName;
        }
      }

      final receiptNumber = await saleService.processOneClickSale(
        salesOrderNo: DateTime.now().millisecondsSinceEpoch,
        shopId: _selectedShop!.id!,
        saleItems: ref.read(saleListProvider),
        remarks:
            _remarksController.text.isNotEmpty ? _remarksController.text : null,
        isSaleMode: true,
        customerId: customerId,
        customerName: customerName,
        status: status,
      );

      Navigator.of(context).pop();
      final isCredit = status == SalesStatus.credit;
      showAppSnackBar(context,
          message: '✅ ${isCredit ? '赊账' : '销售'}成功！销售单号：$receiptNumber');

      ref.invalidate(inboundRecordsProvider);
      ref.invalidate(outboundReceiptsProvider);
      ref.invalidate(inventoryQueryProvider);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.saleRecords);
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      final isCredit = status == SalesStatus.credit;
      showAppSnackBar(context,
          message: '❌ ${isCredit ? '赊账' : '销售'}失败: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProcessingDialog() {
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
  }

  void _confirmSale() => _processSale(SalesStatus.preset);
  void _confirmCreditSale() => _processSale(SalesStatus.credit);

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final saleItemCount = ref.watch(
      saleListProvider.select((items) => items.length),
    );
    final totals = ref.watch(saleTotalsProvider);
    final totalVarieties = totals['varieties']?.toInt() ?? 0;
    final totalQuantity = totals['quantity']?.toInt() ?? 0;
    final totalAmount = totals['amount'] ?? 0.0;

    // 自动更新收款金额
    if (!_paymentFocusNode.hasFocus) {
      final calculatedPayment =
          totalAmount > 0 ? (totalAmount / 100).ceil() * 100.0 : 0.0;
      if (_paymentController.text != calculatedPayment.toStringAsFixed(0)) {
        _paymentController.text = calculatedPayment.toStringAsFixed(0);
      }
    }

    final paymentAmount = double.tryParse(_paymentController.text) ?? 0.0;
    final change = paymentAmount - totalAmount;

    _ensureFocusNodes(saleItemCount);

    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvoked: (bool didPop) {
        if (!didPop) context.go('/');
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
            title:
                Row(mainAxisSize: MainAxisSize.min, children: [Text('收银台')]),
            actions: [const SizedBox(width: 8)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SaleHeaderSection(
                  selectedShop: _selectedShop,
                  selectedCustomer: _selectedCustomer,
                  customerController: _customerController,
                  shopFocusNode: _shopFocusNode,
                  customerFocusNode: _customerFocusNode,
                  onShopChanged: (shop) => setState(() => _selectedShop = shop),
                  onCustomerSelected: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                      if (customer != null) {
                        _customerController.text = customer.name;
                      }
                    });
                  },
                  onCustomerTextChanged: () {
                    // 当用户手动输入时，清除已选择的顾客
                    if (_selectedCustomer != null) {
                      setState(() => _selectedCustomer = null);
                    }
                  },
                  onCustomerSubmitted: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_priceFocusNodes.isNotEmpty) {
                        _priceFocusNodes.first.requestFocus();
                      } else {
                        _paymentFocusNode.requestFocus();
                      }
                    });
                  },
                ),
                const SizedBox(height: 0),
                SaleCartList(
                  shopId: _selectedShop?.id,
                  showPriceInfo: true,
                  priceFocusNodes: _priceFocusNodes,
                  quantityFocusNodes: _quantityFocusNodes,
                  onItemSubmitted: _handleNextStep,
                ),
                const SizedBox(height: 0),
                SaleActionButtons(
                  onAddProduct: _addManualProduct,
                  onScanProduct: _scanToAddProduct,
                  onContinuousScan: _continuousScan,
                ),
                const SizedBox(height: 4),
                SaleTotalsBar(
                  totalVarieties: totalVarieties,
                  totalQuantity: totalQuantity,
                  totalAmount: totalAmount,
                ),
                PaymentChangeSection(
                  paymentController: _paymentController,
                  paymentFocusNode: _paymentFocusNode,
                  change: change,
                ),
                const SizedBox(height: 4),
                SaleBottomBar(
                  isProcessing: _isProcessing,
                  onCreditSale: _confirmCreditSale,
                  onConfirmSale: _confirmSale,
                ),
                const SizedBox(height: 99),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
