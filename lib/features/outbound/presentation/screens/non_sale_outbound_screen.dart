import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import '../../../product/domain/model/product.dart';
import '../../../../config/flavor_config.dart';
import '../../../sale/application/provider/sale_list_provider.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/presentation/providers/inbound_records_provider.dart';
import '../../../inventory/presentation/providers/inventory_query_providers.dart';
import '../../../inventory/presentation/providers/outbound_receipts_provider.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../../../sale/presentation/widgets/sale_item_card.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/sound_helper.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../application/service/outbound_service.dart';

/// 预设的非售出库原因
const List<String> _presetReasons = [
  '报损',
  '过期',
  '调拨',
  '赠送',
  '自用',
  '退货',
  '盘亏',
];

/// 非售出库页面
class NonSaleOutboundScreen extends ConsumerStatefulWidget {
  const NonSaleOutboundScreen({super.key});

  @override
  ConsumerState<NonSaleOutboundScreen> createState() => _NonSaleOutboundScreenState();
}

class _NonSaleOutboundScreenState extends ConsumerState<NonSaleOutboundScreen> {
  final _reasonController = TextEditingController();

  Shop? _selectedShop;
  String? _selectedReason;
  bool _isProcessing = false;

  final FocusNode _shopFocusNode = FocusNode();
  final FocusNode _reasonFocusNode = FocusNode();
  final List<FocusNode> _quantityFocusNodes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleListProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _shopFocusNode.dispose();
    _reasonFocusNode.dispose();
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

  void _addManualProduct() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    if (result == null || result.isEmpty) return;

    try {
      final List<({
        ProductModel product,
        int unitId,
        String unitName,
        int conversionRate,
        int? sellingPriceInCents,
        int? wholesalePriceInCents,
      })> productsWithUnit;

      try {
        productsWithUnit = await ref.read(allProductsWithUnitProvider.future);
      } catch (e) {
        if (!mounted) return;
        showAppSnackBar(context, message: '获取产品数据失败，请稍后重试', isError: true);
        return;
      }

      final selectedProducts = productsWithUnit
          .where((p) => result.contains(p.product.id))
          .toList();

      for (final p in selectedProducts) {
        try {
          ref.read(saleListProvider.notifier).addOrUpdateItem(
            product: p.product,
            unitId: p.unitId,
            unitName: p.unitName,
            sellingPriceInCents: 0, // 非售出库不需要价格
            conversionRate: p.conversionRate,
          );
        } catch (e) {
          print('添加产品失败: ${p.product.name}, 错误: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: '添加货品失败: ${e.toString()}', isError: true);
    }
  }

  void _scanToAddProduct() async {
    final barcode = await BarcodeScannerService.scan(
      context,
      config: const BarcodeScannerConfig(
        title: '扫码添加货品',
        subtitle: '扫描货品条码以添加出库单',
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

  void _handleSingleProductScan(String barcode) async {
    showAppSnackBar(context, message: '正在查询货品信息...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result != null) {
        ref.read(saleListProvider.notifier).addOrUpdateItem(
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          sellingPriceInCents: 0,
          conversionRate: result.conversionRate,
        );
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
      } else {
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, message: '❌ 查询货品失败: $e', isError: true);
    }
  }

  void _handleContinuousProductScan(String barcode) async {
    showAppSnackBar(context, message: '条码: $barcode...');

    try {
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);

      if (!mounted) return;

      if (result != null) {
        ref.read(saleListProvider.notifier).addOrUpdateItem(
          product: result.product,
          unitId: result.unitId,
          unitName: result.unitName,
          sellingPriceInCents: 0,
          conversionRate: result.conversionRate,
        );
        HapticFeedback.lightImpact();
        SoundHelper.playSuccessSound();
        showAppSnackBar(context, message: '✅ ${result.product.name} 已添加');
      } else {
        showAppSnackBar(context, message: '❌ 未找到条码对应的货品: $barcode', isError: true);
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
        return AlertDialog(
          title: Text('货品未找到', style: theme.textTheme.titleLarge),
          content: Text('条码 $barcode 对应的货品未在系统中找到。'),
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
    if (_selectedShop == null) {
      showAppSnackBar(context, message: '请选择出库店铺', isError: true);
      return false;
    }
    final items = ref.read(saleListProvider);
    if (items.isEmpty) {
      showAppSnackBar(context, message: '请先添加货品', isError: true);
      return false;
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        showAppSnackBar(context, message: '货品"${item.productName}"的数量必须大于0', isError: true);
        return false;
      }
    }
    return true;
  }

  void _confirmOutbound() async {
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
      final outboundService = ref.read(outboundServiceProvider);
      final reason = (_selectedReason ?? _reasonController.text.trim()).isEmpty 
          ? '非售' 
          : (_selectedReason ?? _reasonController.text.trim());

      final receiptNumber = await outboundService.processNonSaleOutbound(
        shopId: _selectedShop!.id!,
        items: ref.read(saleListProvider),
        reason: reason,
      );

      Navigator.of(context).pop();
      showAppSnackBar(context, message: '✅ 出库成功！出库单号：$receiptNumber');

      ref.invalidate(inboundRecordsProvider);
      ref.invalidate(outboundReceiptsProvider);
      ref.invalidate(inventoryQueryProvider);

      if (mounted) {
        context.go('/inventory/inbound-records?showOutbound=true');
      }
    } catch (e) {
      Navigator.of(context).pop();
      showAppSnackBar(context, message: '❌ 出库失败: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
            title: const Text('非售出库'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderSection(theme, textTheme),
                const SizedBox(height: 8),
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
                        showPriceInfo: false, // 非售出库不显示价格
                        quantityFocusNode: _quantityFocusNodes.length > index
                            ? _quantityFocusNodes[index]
                            : null,
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                _buildActionButtons(theme, textTheme),
                const SizedBox(height: 8),
                _buildTotalsBar(theme, textTheme, totalVarieties, totalQuantity),
                const SizedBox(height: 8),
                _buildBottomAppBar(theme, textTheme),
                const SizedBox(height: 99),
              ],
            ),
          ),
        ),
      ),
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
              Expanded(
                flex: 2,
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
                          .map((shop) => DropdownMenuItem(
                                value: shop,
                                child: Text(shop.name),
                              ))
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
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('原因:', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _presetReasons;
                        }
                        return _presetReasons.where((reason) =>
                            reason.toLowerCase().contains(
                                textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedReason = selection;
                          _reasonController.text = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        // 同步controller
                        if (_reasonController.text.isNotEmpty && controller.text.isEmpty) {
                          controller.text = _reasonController.text;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: '选择或输入原因',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (value) {
                            _reasonController.text = value;
                            if (!_presetReasons.contains(value)) {
                              _selectedReason = null;
                            }
                          },
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
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
            Icons.outbox_outlined,
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
            '请使用下方按钮添加货品到出库单',
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem(textTheme, '品种', totalVarieties.toString()),
          _buildTotalItem(textTheme, '总数', totalQuantity.toString()),
        ],
      ),
    );
  }

  Widget _buildTotalItem(TextTheme textTheme, String label, String value) {
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar(ThemeData theme, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _confirmOutbound,
        icon: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.outbox, size: 24),
        label: Text(
          _isProcessing ? '正在处理...' : '确认出库',
          style: textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
