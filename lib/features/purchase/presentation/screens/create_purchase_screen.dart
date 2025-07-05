import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/constants/app_routes.dart';
import '../../domain/model/supplier.dart';
import '../../domain/model/purchase_item.dart';
import '../../application/provider/supplier_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../widgets/purchase_item_card.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../application/service/purchase_service.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/presentation/screens/product_selection_screen.dart';
import '../../../product/data/repository/unit_repository.dart';

// 常量定义
const String _kDefaultUnitName = '件';
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
  // 采购货品项列表（初始为空）
  final List<PurchaseItem> _purchaseItems = [];
  bool _isProcessing = false; // 添加处理状态

  /// 防抖处理，避免频繁操作
  Timer? _debounceTimer;

  @override
  void dispose() {
    _remarksController.dispose();
    _supplierController.dispose(); // 清理供应商输入控制器
    _debounceTimer?.cancel(); // 清理定时器
    super.dispose();
  }

  void _updatePurchaseItem(String itemId, PurchaseItem updatedItem) {
    setState(() {
      final index = _purchaseItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _purchaseItems[index] = updatedItem;
      }
    });
  }

  void _removePurchaseItem(String itemId) {
    setState(() {
      _purchaseItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _addManualProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    if (result != null && result is List) {
      final productsAsync = ref.read(allProductsProvider);
      productsAsync.whenData((products) async {
        final selectedProducts = products
            .where((p) => result.contains(p.id))
            .toList();
        final unitRepository = ref.read(unitRepositoryProvider);

        for (final product in selectedProducts) {
          String unitName = _kDefaultUnitName;
          if (product.unitId != null) {
            final unit = await unitRepository.getUnitById(product.unitId!);
            unitName = unit?.name ?? _kDefaultUnitName;
          }
          _addProductWithQuantity(product, unitName: unitName);
        }
      });
    }
  }

  /// 添加指定数量的货品到采购列表
  void _addProductWithQuantity(
    dynamic product, {
    String? unitName,
    String? barcode,
    double quantity = 1.0,
  }) {
    final actualUnitName = unitName ?? _kDefaultUnitName;
    final itemId = barcode != null
        ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
        : 'item_${DateTime.now().millisecondsSinceEpoch}';

    final purchaseItem = PurchaseItem(
      id: itemId,
      productId: product.id,
      productName: product.name,
      unitName: actualUnitName,
      unitPrice: 0.0,
      quantity: quantity,
      amount: 0.0,
      productionDate: DateTime.now(),
    );

    setState(() {
      _purchaseItems.add(purchaseItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ 已添加: ${product.name} x${quantity.toInt()}'),
        backgroundColor: Colors.green,
      ),
    );
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
                enableManualInput: true,
                enableGalleryPicker: false,
                enableFlashlight: true,
                enableCameraSwitch: true,
                enableScanSound: true,
              ),
              onBarcodeScanned: _handleSingleProductScan,
            ),
          ),
        ),
      ),
    );
  }

  void _continuousScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: _SimpleContinuousScanPage(
              ref: ref,
              onProductsScanned: (scannedProducts) {
                setState(() {
                  _purchaseItems.addAll(scannedProducts);
                });
              },
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
    // 防止重复提交
    if (_isProcessing) return;

    // 验证表单
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // 获取供应商信息
    String? supplierId;
    String? supplierName;

    if (_selectedSupplier != null) {
      // 使用已选择的供应商
      supplierId = _selectedSupplier!.id;
      supplierName = _selectedSupplier!.name;
    } else {
      // 为新供应商生成ID
      supplierId = 'supplier_${DateTime.now().millisecondsSinceEpoch}';
      supplierName = _supplierController.text.trim();
    }

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在处理一键入库...'),
          ],
        ),
      ),
    );

    try {
      final purchaseService = ref.read(purchaseServiceProvider); // 执行一键入库
      final receiptNumber = await purchaseService.processOneClickInbound(
        supplierId: supplierId,
        shopId: _selectedShop!.id,
        purchaseItems: _purchaseItems,
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        supplierName: supplierName, // 传递供应商名称用于自动创建
      );

      // 关闭加载对话框
      Navigator.of(context).pop(); // 显示成功提示
      _showSuccessMessage('✅ 一键入库成功！入库单号：$receiptNumber'); // 延迟跳转到入库记录屏幕
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.inventoryInboundRecords);
        }
      });
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop(); // 显示错误提示
      _showErrorMessage('❌ 一键入库失败: ${e.toString()}');
      print('一键入库失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  double get _totalQuantity =>
      _purchaseItems.fold(0.0, (sum, item) => sum + item.quantity);
  double get _totalAmount =>
      _purchaseItems.fold(0.0, (sum, item) => sum + item.amount);
  int get _totalVarieties => _purchaseItems.length;

  /// 处理单次扫码添加货品
  void _handleSingleProductScan(String barcode) async {
    // 先显示加载提示（不要立即关闭扫码页面）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在查询货品信息...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // 使用新的方法获取货品及其单位信息
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      // 查询完成后，延迟关闭扫码页面，让音效播放完毕
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭扫码页面
        }
      });

      if (!mounted) return;
      if (result != null) {
        _addOrUpdatePurchaseItem(
          result.product,
          unitName: result.unitName,
          barcode: barcode,
        );
      } else {
        // 货品未找到，在扫码页面关闭后稍微延迟显示对话框
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _showProductNotFoundDialog(barcode);
          }
        });
      }
    } catch (e) {
      // 出错时也要关闭扫码页面
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭扫码页面
        }
      });

      if (!mounted) return;

      // 延迟显示错误信息，确保扫码页面已关闭
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 查询货品失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  /// 获取用户友好的错误信息
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return '网络连接超时，请检查网络后重试';
    } else if (errorString.contains('connection') ||
        errorString.contains('network')) {
      return '网络连接失败，请检查网络设置';
    } else if (errorString.contains('permission')) {
      return '权限不足，请检查应用权限设置';
    } else if (errorString.contains('database')) {
      return '数据库操作失败，请重试';
    } else if (errorString.contains('invalid')) {
      return '数据格式无效，请检查输入';
    } else if (errorString.contains('not found')) {
      return '未找到相关数据';
    } else {
      // 返回简化的错误信息，避免暴露技术细节
      return '操作失败，请重试';
    }
  }

  /// 显示货品未找到对话框
  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('货品未找到'),
        content: Text('条码 $barcode 对应的货品未在系统中找到'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('手动添加'),
          ),
        ],
      ),
    );
  }

  /// 验证表单输入
  bool _validateForm() {
    // 检查供应商
    if (_selectedSupplier == null && _supplierController.text.trim().isEmpty) {
      _showErrorMessage('请选择或输入供应商名称');
      return false;
    }

    // 检查店铺
    if (_selectedShop == null) {
      _showErrorMessage('请选择采购店铺');
      return false;
    }

    // 检查货品项
    if (_purchaseItems.isEmpty) {
      _showErrorMessage('请先添加采购货品');
      return false;
    }

    // 检查货品项数据完整性
    for (final item in _purchaseItems) {
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

  /// 显示错误消息
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: _kSnackBarDuration,
      ),
    );
  }

  /// 显示成功消息
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: _kSnackBarDuration,
      ),
    );
  }

  /// 验证输入的数值是否有效
  bool _isValidNumber(String value, {double? min, double? max}) {
    final number = double.tryParse(value);
    if (number == null) return false;
    if (min != null && number < min) return false;
    if (max != null && number > max) return false;
    return true;
  }

  /// 验证货品名称
  String? _validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '货品名称不能为空';
    }
    if (value.trim().length > 100) {
      return '货品名称不能超过100个字符';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Text('保存草稿', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 采购店铺选择
                  Row(
                    children: [
                      const Text(
                        '采购店铺*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final shopsAsync = ref.watch(allShopsProvider);
                            return shopsAsync.when(
                              data: (shops) {
                                // 自动选择'长山的店'作为默认店铺
                                if (_selectedShop == null && shops.isNotEmpty) {
                                  final defaultShop = shops.firstWhere(
                                    (shop) => shop.name == '长山的店',
                                    orElse: () => shops.first,
                                  );
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedShop = defaultShop;
                                      });
                                    }
                                  });
                                }

                                return DropdownButtonFormField<Shop>(
                                  value: _selectedShop,
                                  decoration: const InputDecoration(
                                    hintText: '请选择店铺',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: shops.map((shop) {
                                    return DropdownMenuItem<Shop>(
                                      value: shop,
                                      child: Text(
                                        shop.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (shop) {
                                    setState(() {
                                      _selectedShop = shop;
                                    });
                                  },
                                );
                              },
                              loading: () => Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(child: Text('加载店铺中...')),
                              ),
                              error: (error, stack) => Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '加载失败: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 供应商选择
                  Row(
                    children: [
                      const Text(
                        '供应商*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final suppliersAsync = ref.watch(
                              allSuppliersProvider,
                            );
                            return suppliersAsync.when(
                              data: (suppliers) => TypeAheadField<Supplier>(
                                controller: _supplierController,
                                suggestionsCallback: (pattern) {
                                  if (pattern.isEmpty) {
                                    return Future.value(suppliers);
                                  }
                                  return Future.value(
                                    suppliers
                                        .where(
                                          (supplier) => supplier.name
                                              .toLowerCase()
                                              .contains(pattern.toLowerCase()),
                                        )
                                        .toList(),
                                  );
                                },
                                itemBuilder: (context, supplier) {
                                  return ListTile(title: Text(supplier.name));
                                },
                                onSelected: (supplier) {
                                  setState(() {
                                    _selectedSupplier = supplier;
                                    _supplierController.text = supplier.name;
                                  });
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                builder: (context, controller, focusNode) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onChanged: (value) {
                                      // 如果用户修改了文本，清除已选择的供应商
                                      if (_selectedSupplier != null &&
                                          value != _selectedSupplier!.name) {
                                        setState(() {
                                          _selectedSupplier = null;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: '请输入或选择供应商名称',
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _selectedSupplier != null
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : const Icon(Icons.arrow_drop_down),
                                    ),
                                  );
                                },
                                emptyBuilder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '未找到匹配的供应商',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '您可以直接输入新供应商名称，系统将自动创建',
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                errorBuilder: (context, error) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    '搜索出错: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                loadingBuilder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 12),
                                      Text('搜索中...'),
                                    ],
                                  ),
                                ),
                              ),
                              loading: () => Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(child: Text('加载供应商中...')),
                              ),
                              error: (error, stack) => Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '加载失败: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 货品项列表
                  if (_purchaseItems.isEmpty)
                    // 空列表提示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '暂无货品',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '请使用下方按钮添加货品到采购单',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // 货品项列表
                    ..._purchaseItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PurchaseItemCard(
                          item: item,
                          onUpdate: (updatedItem) =>
                              _updatePurchaseItem(item.id, updatedItem),
                          onRemove: () => _removePurchaseItem(item.id),
                        ),
                      ),
                    ),

                  // 添加货品按钮区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // 手动添加货品按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addManualProduct,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              '添加货品',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 扫码添加货品按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanToAddProduct,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              '扫码添加',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 连续扫码按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _continuousScan,
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text(
                              '连续扫码',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 备注区域
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          '备注',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _remarksController,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            hintText: '请输入备注信息（选填）',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 底部统计和操作区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 汇总信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '品种: $_totalVarieties        数量: ${_totalQuantity.toInt()}        金额: ￥${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16), // 一键入库按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmPurchase,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('处理中...'),
                            ],
                          )
                        : const Text('一键入库'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 添加或更新货品到采购列表（共用逻辑）
  void _addOrUpdatePurchaseItem(
    dynamic product, {
    String? unitName,
    String? barcode,
  }) {
    // 根据条码检查是否已存在相同的货品规格（优先使用条码，其次使用货品ID+单位名称）
    final existingItemIndex = _purchaseItems.indexWhere((item) {
      if (barcode != null && item.id.contains(barcode)) {
        return true; // 根据条码匹配
      }
      return item.productId == product.id &&
          item.unitName == (unitName ?? _kDefaultUnitName);
    });

    if (existingItemIndex != -1) {
      // 如果货品已存在，增加数量
      final existingItem = _purchaseItems[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
        amount: (existingItem.quantity + 1) * existingItem.unitPrice,
      );

      setState(() {
        _purchaseItems[existingItemIndex] = updatedItem;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ ${product.name} 数量+1 (共${updatedItem.quantity}${updatedItem.unitName})',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // 如果是新货品，创建新的采购项
      final actualUnitName = unitName ?? _kDefaultUnitName;
      // 使用条码作为唯一标识符，如果没有条码则使用时间戳
      final itemId = barcode != null
          ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
          : 'item_${DateTime.now().millisecondsSinceEpoch}';

      final purchaseItem = PurchaseItem(
        id: itemId,
        productId: product.id,
        productName: product.name,
        unitName: actualUnitName,
        unitPrice: 0.0,
        quantity: 1,
        amount: 0.0,
        productionDate: DateTime.now(),
      );

      setState(() {
        _purchaseItems.add(purchaseItem);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ 已添加: ${product.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// 简洁的连续扫码页面 - 基于 UniversalBarcodeScanner
class _SimpleContinuousScanPage extends StatefulWidget {
  final Function(List<PurchaseItem>) onProductsScanned;
  final WidgetRef ref;

  const _SimpleContinuousScanPage({
    required this.onProductsScanned,
    required this.ref,
  });

  @override
  State<_SimpleContinuousScanPage> createState() =>
      _SimpleContinuousScanPageState();
}

class _SimpleContinuousScanPageState extends State<_SimpleContinuousScanPage> {
  final List<PurchaseItem> _scannedItems = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 使用通用扫码器
          UniversalBarcodeScanner(
            config: BarcodeScannerConfig(
              title: '连续扫码',
              subtitle: '已扫描: ${_scannedItems.length} 件货品',
              enableManualInput: true,
              enableGalleryPicker: false,
              enableFlashlight: true,
              enableCameraSwitch: true,
              enableScanSound: true,
              continuousMode: true, // 启用连续扫码模式
              continuousDelay: 800, // 扫码后800毫秒重新启用
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              additionalActions: [
                if (_scannedItems.isNotEmpty)
                  TextButton(
                    onPressed: _finishScanning,
                    child: const Text(
                      '完成',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            isLoading: _isLoading,
            onBarcodeScanned: _handleBarcodeScanned,
            loadingWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  '正在查询货品...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),

          // 货品列表浮层
          if (_scannedItems.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '已扫描货品 (${_scannedItems.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _scannedItems.clear();
                                  });
                                },
                                child: const Text('清空'),
                              ),
                              ElevatedButton(
                                onPressed: _finishScanning,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('完成'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _scannedItems.length,
                        itemBuilder: (context, index) {
                          final item = _scannedItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '数量: ${item.quantity} ${item.unitName}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _scannedItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBarcodeScanned(String barcode) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 使用新的方法获取货品及其单位信息
      final productOperations = widget.ref.read(
        productOperationsProvider.notifier,
      );
      final result = await productOperations.getProductWithUnitByBarcode(
        barcode,
      );

      if (!mounted) return;

      if (result != null) {
        _addOrUpdateProduct(
          result.product,
          unitName: result.unitName,
          barcode: barcode,
        );
        _showSuccessMessage('✓ 已添加: ${result.product.name}');
      } else {
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('❌ 查询货品失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addOrUpdateProduct(
    dynamic product, {
    String? unitName,
    String? barcode,
  }) {
    // 根据条码检查是否已存在相同的货品规格
    final existingItemIndex = _scannedItems.indexWhere((item) {
      if (barcode != null && item.id.contains(barcode)) {
        return true;
      }
      return item.productId == product.id &&
          item.unitName == (unitName ?? _kDefaultUnitName);
    });

    if (existingItemIndex != -1) {
      // 如果货品已存在，增加数量
      final existingItem = _scannedItems[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
        amount: (existingItem.quantity + 1) * existingItem.unitPrice,
      );

      setState(() {
        _scannedItems[existingItemIndex] = updatedItem;
      });

      _showSuccessMessage(
        '✓ ${product.name} 数量+1 (共${updatedItem.quantity}${updatedItem.unitName})',
      );
    } else {
      // 如果是新货品，创建新的采购项
      final actualUnitName = unitName ?? _kDefaultUnitName;
      final itemId = barcode != null
          ? 'item_${barcode}_${DateTime.now().millisecondsSinceEpoch}'
          : 'item_${DateTime.now().millisecondsSinceEpoch}';

      final purchaseItem = PurchaseItem(
        id: itemId,
        productId: product.id,
        productName: product.name,
        unitName: actualUnitName,
        unitPrice: 0.0,
        quantity: 1,
        amount: 0.0,
        productionDate: DateTime.now(),
      );

      setState(() {
        _scannedItems.add(purchaseItem);
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: _kShortSnackBarDuration,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: _kSnackBarDuration,
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('货品未找到'),
        content: Text('条码 $barcode 对应的货品未在系统中找到'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续扫码'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('手动添加'),
          ),
        ],
      ),
    );
  }

  void _finishScanning() {
    if (_scannedItems.isNotEmpty) {
      widget.onProductsScanned(_scannedItems);
      Navigator.of(context).pop();
    }
  }
}
