import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../application/provider/stocktake_providers.dart';

/// 添加盘点项对话框
class AddStocktakeItemDialog extends ConsumerStatefulWidget {
  final int stocktakeId;
  final int shopId;

  const AddStocktakeItemDialog({
    super.key,
    required this.stocktakeId,
    required this.shopId,
  });

  @override
  ConsumerState<AddStocktakeItemDialog> createState() =>
      _AddStocktakeItemDialogState();
}

class _AddStocktakeItemDialogState
    extends ConsumerState<AddStocktakeItemDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  dynamic _selectedProduct;
  List<dynamic> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '添加盘点项',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // 搜索框
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索商品名称或条码',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),

            // 搜索结果或已选商品
            if (_selectedProduct != null)
              _buildSelectedProduct()
            else if (_searchResults.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.sku ?? ''),
                      onTap: () => _selectProduct(product),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('未找到商品')),
              ),

            // 数量输入（选中商品后显示）
            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '实盘数量',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('确认添加'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProduct() {
    return Card(
      child: ListTile(
        title: Text(_selectedProduct.name),
        subtitle: Text(_selectedProduct.sku ?? ''),
        trailing: IconButton(
          onPressed: () => setState(() => _selectedProduct = null),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final productsAsync = ref.read(allProductsProvider);
    productsAsync.whenData((products) {
      final results = products.where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(query.toLowerCase()) ?? false));
      if (mounted) {
        setState(() {
          _searchResults = results.toList();
        });
      }
    });
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _selectedProduct = product;
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _confirm() {
    if (_selectedProduct == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效数量')),
      );
      return;
    }

    // 添加盘点项
    ref
        .read(stocktakeEntryNotifierProvider(
                (stocktakeId: widget.stocktakeId, shopId: widget.shopId))
            .notifier)
        .addItem(
          productId: _selectedProduct.id,
          actualQuantity: quantity,
        );

    Navigator.pop(context);
  }
}
