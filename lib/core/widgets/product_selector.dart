import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../features/product/domain/model/product.dart';
import '../../features/product/application/provider/product_providers.dart';
import '../../features/product/data/repository/unit_repository.dart';
import 'universal_barcode_scanner.dart';

/// 货品选择结果
class ProductSelectionResult {
  final Product product;
  final String unitName;
  final String? barcode;
  final double quantity;

  const ProductSelectionResult({
    required this.product,
    required this.unitName,
    this.barcode,
    this.quantity = 1.0,
  });
}

/// 货品选择组件
class ProductSelector extends ConsumerStatefulWidget {
  final String title;
  final Function(List<ProductSelectionResult>) onProductsSelected;

  const ProductSelector({
    super.key,
    this.title = '选择货品',
    required this.onProductsSelected,
  });

  @override
  ConsumerState<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends ConsumerState<ProductSelector> {
  final _searchController = TextEditingController();
  final List<ProductSelectionResult> _selectedProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          _buildActionButtons(),
          _buildSearchBar(),
          _buildSelectionInfo(),
          Expanded(child: _buildProductList()),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _scanProduct,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫码选择'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showManualAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('手动添加'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TypeAheadField<Product>(
        controller: _searchController,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: '搜索货品名称或条码',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          );
        },
        suggestionsCallback: (pattern) async {
          if (pattern.isEmpty) return [];
          try {
            final allProducts = await ref.read(allProductsProvider.future);
            return allProducts.where((p) => 
              p.name.toLowerCase().contains(pattern.toLowerCase())
            ).take(10).toList();
          } catch (e) {
            return [];
          }
        },
        itemBuilder: (context, product) {
          return ListTile(
            title: Text(product.name),
            subtitle: Text(product.formattedPrice),
            trailing: Text(product.sku ?? ''),
          );
        },
        onSelected: (product) {
          _toggleProductSelection(product);
          _searchController.clear();
        },
      ),
    );
  }

  Widget _buildSelectionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '已选择${_selectedProducts.length}种货品',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedProducts.isNotEmpty
              ? () {
                  widget.onProductsSelected(_selectedProducts);
                  Navigator.of(context).pop();
                }
              : null,
          child: Text('确认选择 (${_selectedProducts.length})'),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final productsAsync = ref.watch(allProductsProvider);
    
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('暂无货品'));
        }
        
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isSelected = _selectedProducts.any((p) => p.product.id == product.id);
            
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipOval(
                          child: Image.file(
                            File(product.image!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.inventory_2,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.inventory_2,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                ),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${product.sku ?? 'SKU: 无'} | ${product.formattedPrice}'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () => _toggleProductSelection(product),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
    );
  }

  void _scanProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UniversalBarcodeScanner(
          config: const BarcodeScannerConfig(
            title: '扫码选择货品',
            subtitle: '扫描货品条码',
            enableManualInput: true,
          ),
          onBarcodeScanned: _handleBarcodeScanned,
        ),
      ),
    );
  }

  void _handleBarcodeScanned(String barcode) async {
    Navigator.of(context).pop(); // 关闭扫码页面
    
    try {
      // 使用新的方法获取商品及其单位信息
      final productOperations = ref.read(productOperationsProvider.notifier);
      final result = await productOperations.getProductWithUnitByBarcode(barcode);
      
      if (result != null) {
        setState(() {
          final selectionResult = ProductSelectionResult(
            product: result.product,
            unitName: result.unitName,
            barcode: barcode,
          );
          _selectedProducts.add(selectionResult);
        });
      } else {
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查询失败: $e')),
      );
    }
  }



  void _toggleProductSelection(Product product) async {
    final isSelected = _selectedProducts.any((p) => p.product.id == product.id);
    
    if (isSelected) {
      setState(() {
        _selectedProducts.removeWhere((p) => p.product.id == product.id);
      });
    } else {
      // 获取商品的实际单位名称
      String unitName = '件'; // 默认单位
      
      if (product.unitId != null) {
        try {
          final unitRepository = ref.read(unitRepositoryProvider);
          final unit = await unitRepository.getUnitById(product.unitId!);
          if (unit != null) {
            unitName = unit.name;
          }
        } catch (e) {
          // 如果获取单位失败，使用默认单位
          print('获取单位信息失败: $e');
        }
      }
      
      setState(() {
        final result = ProductSelectionResult(
          product: product,
          unitName: unitName,
        );
        _selectedProducts.add(result);
      });
    }
  }



  void _showManualAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final barcodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加货品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '货品名称'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '价格'),
            ),
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(labelText: '条码（可选）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              final product = Product(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                suggestedRetailPrice: double.tryParse(priceController.text) ?? 0.0,
                sku: barcodeController.text.isEmpty ? null : barcodeController.text,
              );
              
              Navigator.of(context).pop();
              
              final result = ProductSelectionResult(
                product: product,
                unitName: '件', // 手动添加的商品使用默认单位
                barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
              );
              setState(() {
                _selectedProducts.add(result);
              });
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('货品未找到'),
        content: Text('条码 $barcode 对应的货品未找到'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualAddDialog();
            },
            child: const Text('手动添加'),
          ),
        ],
      ),
    );
  }
}