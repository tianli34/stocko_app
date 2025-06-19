import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../domain/model/supplier.dart';
import '../../application/provider/supplier_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../widgets/purchase_item_card.dart';
import '../../../../core/widgets/universal_barcode_scanner.dart';
import '../../../purchase/application/supplier_sample_data_service.dart';
import '../../application/service/purchase_service.dart';

/// 采购单商品项
class PurchaseItem {
  final String id;
  final String productId;
  final String productName;
  final String unitName;
  final double unitPrice;
  final double quantity;
  final double amount;
  final DateTime? productionDate;

  PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
    this.productionDate,
  });

  PurchaseItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? unitName,
    double? unitPrice,
    double? quantity,
    double? amount,
    DateTime? productionDate,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      productionDate: productionDate ?? this.productionDate,
    );
  }
}

/// 新建采购单页面
class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final _remarksController = TextEditingController();
  final _supplierController = TextEditingController(); // 新增：供应商输入控制器

  Supplier? _selectedSupplier;
  Shop? _selectedShop;
  // 模拟商品项数据
  final List<PurchaseItem> _purchaseItems = [
    PurchaseItem(
      id: 'item_001',
      productId: 'prod_water', // 使用真实存在的产品ID
      productName: '矿泉水（500ml）',
      unitName: '瓶',
      unitPrice: 2.5,
      quantity: 50,
      amount: 125.0,
      productionDate: DateTime(2025, 6, 18),
    ),
    PurchaseItem(
      id: 'item_002',
      productId: 'prod_chips', // 使用真实存在的产品ID
      productName: '薯片（原味）',
      unitName: '包',
      unitPrice: 5.0,
      quantity: 4,
      amount: 20.0,
    ),
  ];
  @override
  void dispose() {
    _remarksController.dispose();
    _supplierController.dispose(); // 清理供应商输入控制器
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

  void _addManualProduct() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('手动添加商品功能待实现')));
  }

  void _scanToAddProduct() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('扫码添加商品功能待实现')));
  }

  void _continuousScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ContinuousScanPage(
          onProductsScanned: (scannedProducts) {
            setState(() {
              _purchaseItems.addAll(scannedProducts);
            });
          },
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
    // 获取供应商信息
    String? supplierId;
    String? supplierName;

    if (_selectedSupplier != null) {
      // 使用已选择的供应商
      supplierId = _selectedSupplier!.id;
      supplierName = _selectedSupplier!.name;
    } else {
      // 检查用户是否输入了供应商名称
      final inputSupplierName = _supplierController.text.trim();
      if (inputSupplierName.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择或输入供应商名称')));
        return;
      }

      // 为新供应商生成ID
      supplierId = 'supplier_${DateTime.now().millisecondsSinceEpoch}';
      supplierName = inputSupplierName;
    }

    if (_selectedShop == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择采购店铺')));
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加采购商品')));
      return;
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
      Navigator.of(context).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 一键入库成功！入库单号：$receiptNumber'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // 延迟跳转
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go('/');
        }
      });
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 一键入库失败: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      print('一键入库失败: $e');
    }
  }

  double get _totalQuantity =>
      _purchaseItems.fold(0.0, (sum, item) => sum + item.quantity);

  double get _totalAmount =>
      _purchaseItems.fold(0.0, (sum, item) => sum + item.amount);

  void _addTestSuppliers() async {
    try {
      final sampleDataService = ref.read(supplierSampleDataServiceProvider);
      await sampleDataService.createSampleSuppliers();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 测试供应商数据创建成功！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ 创建测试数据失败: $e')));
      }
    }
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
                                  return ListTile(
                                    leading: const Icon(Icons.business),
                                    title: Text(supplier.name),
                                    subtitle: Text('供应商ID: ${supplier.id}'),
                                  );
                                },
                                onSelected: (supplier) {
                                  setState(() {
                                    _selectedSupplier = supplier;
                                    _supplierController.text = supplier.name;
                                  });
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
                  const SizedBox(height: 16), // 采购店铺选择
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
                              data: (shops) => DropdownButtonFormField<Shop>(
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
                                      '${shop.name} (店长: ${shop.manager})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (shop) {
                                  setState(() {
                                    _selectedShop = shop;
                                  });
                                },
                              ),
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

                  // 商品项列表
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

                  // 添加商品按钮区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // 手动添加商品按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addManualProduct,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              '手动添加商品',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 扫码添加商品按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanToAddProduct,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              '扫码添加商品',
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
                          maxLines: 3,
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
                    '合计数量: ${_totalQuantity.toInt()}        合计金额: ￥${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 一键入库按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmPurchase,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('一键入库'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTestSuppliers,
        icon: const Icon(Icons.add_business),
        label: const Text('添加测试供应商'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// 连续扫码页面
class _ContinuousScanPage extends StatefulWidget {
  final Function(List<PurchaseItem>) onProductsScanned;

  const _ContinuousScanPage({required this.onProductsScanned});

  @override
  State<_ContinuousScanPage> createState() => _ContinuousScanPageState();
}

class _ContinuousScanPageState extends State<_ContinuousScanPage> {
  final List<PurchaseItem> _scannedItems = [];
  bool _isProcessing = false;
  String? _lastScannedCode;
  final GlobalKey<_ContinuousBarcodeScannerState> _scannerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 连续扫码器
          _ContinuousBarcodeScanner(
            key: _scannerKey,
            onBarcodeScanned: _handleBarcodeScanned,
          ),

          // 处理加载遮罩
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      '正在查找商品: $_lastScannedCode',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // 顶部标题栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: const Text('连续扫码'),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _scannerKey.currentState?.toggleFlashlight(),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios),
                  onPressed: () => _scannerKey.currentState?.switchCamera(),
                ),
              ],
            ),
          ),

          // 浮动操作栏
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '已扫描: ${_scannedItems.length} 件商品',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_scannedItems.isNotEmpty)
                    ElevatedButton(
                      onPressed: _finishScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('完成扫码'),
                    ),
                ],
              ),
            ),
          ),

          // 商品列表（如果有扫描的商品）
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
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '已扫描商品',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _scannedItems.clear();
                              });
                            },
                            child: const Text('清空'),
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
                              backgroundColor: Colors.green,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item.productName),
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

  void _handleBarcodeScanned(String barcode) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = barcode;
    });

    // 模拟查找商品的延迟
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      // 模拟根据条码查找商品
      final mockProduct = _findProductByBarcode(barcode);

      if (mockProduct != null) {
        setState(() {
          _scannedItems.add(mockProduct);
          _isProcessing = false;
        });

        // 播放成功提示音和震动反馈
        _showSuccessMessage(mockProduct.productName);
      } else {
        setState(() {
          _isProcessing = false;
        });
        _showNotFoundDialog(barcode);
      }
    });
  }

  PurchaseItem? _findProductByBarcode(String barcode) {
    // 模拟商品数据库查询
    final mockProducts = {
      '6901234567890': PurchaseItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productId: 'prod_water',
        productName: '农夫山泉(550ml)',
        unitName: '瓶',
        unitPrice: 2.0,
        quantity: 1,
        amount: 2.0,
        productionDate: DateTime.now(),
      ),
      '6901234567891': PurchaseItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productId: 'prod_chips',
        productName: '乐事薯片(原味)',
        unitName: '包',
        unitPrice: 8.5,
        quantity: 1,
        amount: 8.5,
      ),
      '6901234567892': PurchaseItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productId: 'prod_cookie',
        productName: '奥利奥饼干',
        unitName: '包',
        unitPrice: 12.0,
        quantity: 1,
        amount: 12.0,
      ),
    };

    return mockProducts[barcode];
  }

  void _showSuccessMessage(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ 已添加: $productName'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品未找到'),
        content: Text('条码 $barcode 对应的商品未在系统中找到'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('继续扫码'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualInputDialog(barcode);
            },
            child: const Text('手动添加'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(String barcode) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加商品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('条码: $barcode'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '单价',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '数量',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final quantity =
                  double.tryParse(quantityController.text.trim()) ?? 1.0;
              if (name.isNotEmpty && price > 0) {
                final newItem = PurchaseItem(
                  id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                  productId: 'manual_$barcode',
                  productName: name,
                  unitName: '个',
                  unitPrice: price,
                  quantity: quantity,
                  amount: price * quantity,
                );

                setState(() {
                  _scannedItems.add(newItem);
                });

                Navigator.of(context).pop();
                _showSuccessMessage(name);
              }
            },
            child: const Text('添加'),
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

/// 支持连续扫码的条码扫描器
class _ContinuousBarcodeScanner extends StatefulWidget {
  final OnBarcodeScanned onBarcodeScanned;

  const _ContinuousBarcodeScanner({super.key, required this.onBarcodeScanned});

  @override
  State<_ContinuousBarcodeScanner> createState() =>
      _ContinuousBarcodeScannerState();
}

class _ContinuousBarcodeScannerState extends State<_ContinuousBarcodeScanner> {
  late MobileScannerController _cameraController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: MobileScanner(
        controller: _cameraController,
        onDetect: (capture) {
          if (!_isScanning) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              // 暂停扫描
              setState(() {
                _isScanning = false;
              });

              // 调用回调
              widget.onBarcodeScanned(code);

              // 延迟重置扫描状态，实现连续扫码
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) {
                  setState(() {
                    _isScanning = true;
                  });
                }
              });
            }
          }
        },
      ),
    );
  }

  void toggleFlashlight() {
    _cameraController.toggleTorch();
  }

  void switchCamera() {
    _cameraController.switchCamera();
  }
}
