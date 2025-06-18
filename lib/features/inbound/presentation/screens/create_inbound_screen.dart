import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/home_button.dart';
import '../../domain/model/inbound_item.dart';
import '../widgets/inbound_item_card.dart';
import 'inbound_barcode_scanner_screen.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../inventory/domain/model/batch.dart';
import '../../../../core/database/database.dart';

/// 新建入库单页面
class CreateInboundScreen extends ConsumerStatefulWidget {
  const CreateInboundScreen({super.key});

  @override
  ConsumerState<CreateInboundScreen> createState() =>
      _CreateInboundScreenState();
}

class _CreateInboundScreenState extends ConsumerState<CreateInboundScreen> {
  final _remarksController = TextEditingController();
  bool _continuousScanMode = false; // 连续扫码模式开关，默认关闭

  // 模拟入库项目数据
  final List<InboundItem> _inboundItems = [
    InboundItem.create(
      receiptId: 'receipt_001',
      productId: 'prod_001',
      productName: '商品A',
      productSpec: '红色S码',
      productImage: null,
      quantity: 98.0,
      unitId: 'unit_001',
      productionDate: DateTime(2023, 1, 1),
      locationId: 'loc_001',
      locationName: 'A-01-01',
      purchaseQuantity: 100.0,
    ),
    InboundItem.create(
      receiptId: 'receipt_001',
      productId: 'prod_002',
      productName: '商品B',
      productSpec: '蓝色M码',
      productImage: null,
      quantity: 50.0,
      unitId: 'unit_002',
      productionDate: null,
      locationId: null,
      locationName: null,
      purchaseQuantity: null, // 无采购数量显示为 --
    ),
  ];

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _updateInboundItem(String itemId, InboundItem updatedItem) {
    setState(() {
      final index = _inboundItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _inboundItems[index] = updatedItem;
      }
    });
  }

  void _removeInboundItem(String itemId) {
    setState(() {
      _inboundItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _addManualProduct() {
    // TODO: 实现手动添加商品功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('手动添加商品功能待实现')));
  }

  void _scanToAddProduct() async {
    try {
      final result = await Navigator.of(context).push<InboundItem>(
        MaterialPageRoute(
          builder: (context) => const InboundBarcodeScannerScreen(),
        ),
      );

      if (result != null) {
        setState(() {
          _inboundItems.add(result);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加商品: ${result.productName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫码添加商品失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveDraft() {
    // TODO: 实现保存草稿功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存草稿功能待实现')));
  }

  void _submitInbound() async {
    if (_inboundItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加入库商品')));
      return;
    }

    try {
      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在提交入库单...'),
            ],
          ),
        ),
      ); // 获取数据库实例
      final database = ref.read(appDatabaseProvider);
      final inboundReceiptDao = database.inboundReceiptDao;
      final inboundItemDao = database.inboundItemDao;
      final batchDao = database.batchDao;
      final inventoryService = ref.read(inventoryServiceProvider);

      // 获取默认店铺ID（这里简化处理，实际应该让用户选择）
      const defaultShopId = 'shop_001';

      // 1. 创建入库单主记录
      final receiptId = 'receipt_${DateTime.now().millisecondsSinceEpoch}';
      final receiptNumber = await inboundReceiptDao.generateReceiptNumber(
        DateTime.now(),
      );
      final receipt = InboundReceiptsTableCompanion(
        id: drift.Value(receiptId),
        receiptNumber: drift.Value(receiptNumber),
        status: const drift.Value('submitted'),
        remarks: drift.Value(
          _remarksController.text.isNotEmpty ? _remarksController.text : null,
        ),
        shopId: const drift.Value(defaultShopId),
        submittedAt: drift.Value(DateTime.now()),
      );

      await inboundReceiptDao.insertInboundReceipt(receipt);

      // 2. 创建入库单明细记录并处理库存
      for (final item in _inboundItems) {
        // 插入入库明细
        final itemCompanion = InboundReceiptItemsTableCompanion(
          id: drift.Value(item.id),
          receiptId: drift.Value(receiptId),
          productId: drift.Value(item.productId),
          quantity: drift.Value(item.quantity),
          unitId: drift.Value(item.unitId),
          productionDate: drift.Value(item.productionDate),
          locationId: drift.Value(item.locationId),
          purchaseQuantity: drift.Value(item.purchaseQuantity),
          batchNumber: item.productionDate != null
              ? drift.Value(
                  Batch.generateBatchNumber(
                    item.productId,
                    item.productionDate!,
                  ),
                )
              : const drift.Value.absent(),
        );
        await inboundItemDao.insertInboundItem(
          itemCompanion,
        ); // 3. 如果有生产日期，创建或更新批次记录
        // 同一批次在多次入库时需要累加 initialQuantity
        if (item.productionDate != null) {
          final batchNumber = Batch.generateBatchNumber(
            item.productId,
            item.productionDate!,
          ); // 检查批次是否已存在
          final existingBatch = await batchDao.getBatchByNumber(batchNumber);
          if (existingBatch != null) {
            // 如果批次已存在，累加初始数量
            final newInitialQuantity =
                existingBatch.initialQuantity + item.quantity;
            await batchDao.updateBatchQuantity(batchNumber, newInitialQuantity);
          } else {
            // 如果批次不存在，创建新批次
            await batchDao.createBatch(
              productId: item.productId,
              productionDate: item.productionDate!,
              initialQuantity: item.quantity,
              shopId: defaultShopId,
            );
          }
        }

        // 4. 处理库存和流水
        final batchNumber = item.productionDate != null
            ? Batch.generateBatchNumber(item.productId, item.productionDate!)
            : 'BATCH_${DateTime.now().millisecondsSinceEpoch}';

        final success = await inventoryService.inbound(
          productId: item.productId,
          shopId: defaultShopId,
          batchNumber: batchNumber,
          quantity: item.quantity,
          time: DateTime.now(),
        );

        if (!success) {
          throw Exception('商品 ${item.productName} 入库失败');
        }
      } // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('入库单提交成功！单号：$receiptNumber'),
          backgroundColor: Colors.green,
        ),
      ); // 延迟跳转到入库记录页面
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRoutes.inventoryInboundRecords);
        }
      });
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int get _totalItems => _inboundItems.length;
  double get _totalQuantity =>
      _inboundItems.fold(0.0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
          tooltip: '返回',
        ),
        title: const Text('新建入库单'),
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
          // 商品列表区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 入库项目列表
                  ..._inboundItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InboundItemCard(
                        item: item,
                        onUpdate: (updatedItem) =>
                            _updateInboundItem(item.id, updatedItem),
                        onRemove: () => _removeInboundItem(item.id),
                      ),
                    ),
                  ), // 添加商品按钮区域
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
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _addManualProduct,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              '手动添加',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 扫码添加商品按钮
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _scanToAddProduct,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              '扫码添加',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // 连续扫码开关
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '连续扫码',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Switch(
                                value: _continuousScanMode,
                                onChanged: (value) {
                                  setState(() {
                                    _continuousScanMode = value;
                                  });
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 入库到下拉框
                  Row(
                    children: [
                      const Text(
                        '入库到',
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
                            final selectedShopId = ref.watch(
                              selectedShopIdProvider,
                            );

                            return shopsAsync.when(
                              data: (shops) => DropdownButtonFormField<String>(
                                value: selectedShopId,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: shops.map((shop) {
                                  return DropdownMenuItem<String>(
                                    value: shop.id,
                                    child: Text(shop.name),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    ref
                                            .read(
                                              selectedShopIdProvider.notifier,
                                            )
                                            .state =
                                        newValue;
                                  }
                                },
                              ),
                              loading: () => DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: const [],
                                onChanged: null,
                              ),
                              error: (error, stack) =>
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      errorText: '加载店铺失败: $error',
                                    ),
                                    items: const [],
                                    onChanged: null,
                                  ),
                            );
                          },
                        ),
                      ),
                    ],
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
                            hintText: '可输入特殊情况说明...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80), // 为底部统计区域预留空间
                ],
              ),
            ),
          ),
        ],
      ),

      // 底部统计和提交区域
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 统计信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '合计品项: $_totalItems   合计数量: ${_totalQuantity.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 12), // 提交按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitInbound,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('提 交 入 库'),
                  ),
                ),

                const SizedBox(height: 16),

                // 主页按钮
                const HomeButton.compact(
                  width: double.infinity,
                  customLabel: '返回主页',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
