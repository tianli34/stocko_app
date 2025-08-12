import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart'; // 导入 collection 包
import '../../../product/domain/model/product.dart';
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
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../widgets/sale_item_card.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';

enum SaleMode { sale, nonSale }

/// 新建销售单页面
class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

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
  String? _lastScannedBarcode;

  final FocusNode _shopFocusNode = FocusNode();
  final FocusNode _customerFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  final List<FocusNode> _quantityFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus) {
        _paymentController.clear();
      }
    });
    _paymentController.text = '100';
    _paymentController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleListProvider.notifier).clear();
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
    super.dispose();
  }

  void _ensureFocusNodes(int itemCount) {
    while (_quantityFocusNodes.length < itemCount) {
      _quantityFocusNodes.add(FocusNode());
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
      _quantityFocusNodes[index + 1].requestFocus();
    }
  }

  void _addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    // 如果没有返回结果或结果为空，则直接返回
    if (result == null || result.isEmpty) return;

    try {
      // 核心修复：
      final List<
        ({
          ProductModel product,
          int unitId,
          String unitName,
          int? wholesalePriceInCents,
        })
      >
      productsWithUnit = await ref.read(allProductsWithUnitProvider.future);

      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        final price = p.product.effectivePrice;
        ref
            .read(saleListProvider.notifier)
            .addOrUpdateItem(
              product: p.product,
              unitId: p.unitId,
              unitName: p.unitName,
              sellingPriceInCents: price != null ? price.cents : 0,
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

  void _scanToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: UniversalBarcodeScanner(
              config: const BarcodeScannerConfig(
                title: '扫码添加货品',
                subtitle: '扫描货品条码以添加入库单',
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
        shopId: _selectedShop!.id,
        saleItems: ref.read(saleListProvider),
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        // 新增和修改的参数
        isSaleMode: isSaleMode,
        customerId: customerId ?? 0,
        customerName: customerName,
      );
      print(
        '🔍 [DEBUG] UI: processOneClickSale Settled, receipt: $receiptNumber',
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 销售成功！销售单号：$receiptNumber');

      // 核心修复：使入库记录和库存查询的Provider失效，以便在导航后刷新数据
      ref.invalidate(inboundRecordsProvider);
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
        shopId: _selectedShop!.id,
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
        final price = result.product.effectivePrice;
        ref.read(saleListProvider.notifier).addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              sellingPriceInCents: price != null ? price.cents : 0,
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
      showAppSnackBar(context, message: '❌ 查询货品失败: $e', isError: true);
    }
  }

  void _handleContinuousProductScan(String barcode) async {
    // 连续扫码去重：如果条码与上一个相同，则忽略
    if (barcode == _lastScannedBarcode) {
      return;
    }

    // 在连续扫码模式下，不显示全局的加载提示，而是快速反馈
    HapticFeedback.lightImpact();
    showAppSnackBar(context, message: '条码: $barcode...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      if (!mounted) return;

      if (result != null) {
        final price = result.product.effectivePrice;
        ref.read(saleListProvider.notifier).addOrUpdateItem(
              product: result.product,
              unitId: result.unitId,
              unitName: result.unitName,
              sellingPriceInCents: price != null ? price.cents : 0,
            );
        _lastScannedBarcode = barcode; // 仅在成功时更新上一个条码
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
                    '¥ ${change.toStringAsFixed(2)}',
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
                        showPriceInfo: _currentMode == SaleMode.sale, // 新增
                        quantityFocusNode: _quantityFocusNodes.length > index
                            ? _quantityFocusNodes[index]
                            : null,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: allShopsAsync.when(
                data: (shops) {
                  if (_selectedShop == null) {
                    final defaultShop = shops.firstWhereOrNull(
                      (shop) => shop.name == '长山的店',
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
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
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
                              _shopFocusNode.requestFocus();
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
