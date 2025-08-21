import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/inventory/application/provider/shop_providers.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/inventory/domain/model/shop.dart';
import 'package:stocko_app/features/inventory/presentation/application/inventory_query_service.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/inventory/domain/model/batch.dart' as bm;
import 'package:stocko_app/core/utils/snackbar_helper.dart';
import 'package:stocko_app/features/inventory/presentation/providers/inventory_query_providers.dart';
import 'package:stocko_app/features/inventory/data/repository/inventory_repository.dart';

class AdjustInventoryDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const AdjustInventoryDialog({
    super.key,
    required this.product,
  });

  @override
  _AdjustInventoryDialogState createState() => _AdjustInventoryDialogState();
}

class _AdjustInventoryDialogState extends ConsumerState<AdjustInventoryDialog> {
  final _quantityController = TextEditingController();
  Shop? _selectedShop;
  bm.BatchModel? _selectedBatch;
  List<bm.BatchModel>? _batches;
  bool _isFetchingBatches = false;
  bool _isFetchingInventory = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentInventory() async {
    if (_selectedShop == null || widget.product.id == null) return;
    
    setState(() => _isFetchingInventory = true);
    try {
      final inventory = await ref
          .read(inventoryRepositoryProvider)
          .getInventoryByProductShopAndBatch(
            widget.product.id!,
            _selectedShop!.id!,
            widget.product.enableBatchManagement ? _selectedBatch?.id : null,
          );
      
      if (mounted) {
        setState(() {
          _quantityController.text = inventory?.quantity.toString() ?? '0';
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: '获取库存数量失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingInventory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool batchManaged = widget.product.enableBatchManagement;
    final shopsAsyncValue = ref.watch(allShopsProvider);

    return AlertDialog(
      title: Text('调整库存: ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          shopsAsyncValue.when(
            data: (shops) => DropdownButtonFormField<Shop>(
              value: _selectedShop,
              onChanged: (Shop? newShop) async {
                setState(() {
                  _selectedShop = newShop;
                  _batches = null;
                  _selectedBatch = null;
                  _quantityController.text = '';
                });
                if (newShop != null) {
                  if (batchManaged) {
                    setState(() => _isFetchingBatches = true);
                    try {
                      final productId = widget.product.id;
                      final shopId = newShop.id;

                      if (productId == null || shopId == null) {
                        // Handle error case where IDs are null
                        showAppSnackBar(context,
                            message: '产品或店铺ID无效', isError: true);
                        return;
                      }

                      final batches = await ref
                          .read(productRepositoryProvider)
                          .getBatchesByProductAndShop(productId, shopId);
                      if (mounted) {
                        setState(() {
                          _batches = batches;
                          _selectedBatch = batches.isNotEmpty ? batches.first : null;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        showAppSnackBar(context,
                            message: '获取批次失败: $e', isError: true);
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isFetchingBatches = false);
                      }
                    }
                  } else {
                    // 如果不启用批次管理，直接获取当前库存
                    await _loadCurrentInventory();
                  }
                }
              },
              items: shops.map<DropdownMenuItem<Shop>>((Shop shop) {
                return DropdownMenuItem<Shop>(
                  value: shop,
                  child: Text(shop.name),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: '选择店铺',
                border: OutlineInputBorder(),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('无法加载店铺: $err'),
          ),
          const SizedBox(height: 16),
          if (batchManaged && _selectedShop != null)
            _isFetchingBatches
                ? const Center(child: CircularProgressIndicator())
                : (_batches != null && _batches!.isNotEmpty)
                    ? DropdownButtonFormField<bm.BatchModel>(
                        value: _selectedBatch,
                        onChanged: (bm.BatchModel? newValue) async {
                          setState(() {
                            _selectedBatch = newValue;
                          });
                          // 选择批次后获取当前库存
                          await _loadCurrentInventory();
                        },
                        items: _batches!.map<DropdownMenuItem<bm.BatchModel>>(
                            (bm.BatchModel batch) {
                          return DropdownMenuItem<bm.BatchModel>(
                            value: batch,
                            child: Text(
                                '生产日期: ${batch.productionDate.toLocal().toString().split(' ')[0]}'),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: '选择批次',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : const Text('该店铺无此货品的批次信息'),
          const SizedBox(height: 16),
          _isFetchingInventory
              ? const Center(child: CircularProgressIndicator())
              : TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  enabled: !batchManaged || (batchManaged && _batches != null && _batches!.isNotEmpty),
                  decoration: const InputDecoration(
                    labelText: '调整数量',
                    border: OutlineInputBorder(),
                  ),
                ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            final newQuantity = int.tryParse(_quantityController.text);
            if (_selectedShop == null) {
              showAppSnackBar(context, message: '请选择一个店铺', isError: true);
              return;
            }
            if (newQuantity == null) {
              showAppSnackBar(context, message: '请输入有效的数量', isError: true);
              return;
            }
            if (widget.product.id == null) {
              showAppSnackBar(context, message: '产品ID无效', isError: true);
              return;
            }

            try {
              await ref
                  .read(inventoryQueryServiceProvider)
                  .adjustStock(
                    productId: widget.product.id!,
                    shopId: _selectedShop!.id!,
                    newQuantity: newQuantity,
                    batchId: (batchManaged ? _selectedBatch?.id : null),
                  );
              showAppSnackBar(context, message: '库存调整成功');
              ref.invalidate(inventoryQueryProvider);
              Navigator.of(context).pop();
            } catch (e) {
              showAppSnackBar(context, message: '库存调整失败: $e', isError: true);
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}