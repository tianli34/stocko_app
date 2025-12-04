import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:collection/collection.dart';

import '../../../../config/flavor_config.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../purchase/application/provider/supplier_providers.dart';
import '../../../purchase/domain/model/supplier.dart';
import '../screens/create_inbound_controller.dart';

/// 入库页面头部组件 - 店铺选择和供应商/来源输入
class CreateInboundHeader extends ConsumerWidget {
  final CreateInboundController controller;
  final VoidCallback onStateChanged;

  const CreateInboundHeader({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allShopsAsync = ref.watch(allShopsProvider);
    final flavor = ref.watch(flavorConfigProvider).flavor;
    final isGeneric = flavor == AppFlavor.generic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 自动选择默认店铺
        allShopsAsync.when(
          data: (shops) {
            if (controller.selectedShop == null) {
              final defaultShopName = isGeneric ? '我的店铺' : '长山的店';
              final defaultShop = shops.firstWhereOrNull(
                (shop) => shop.name == defaultShopName,
              );
              if (defaultShop != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.setShop(defaultShop);
                });
              }
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isGeneric) ...[
              _buildShopDropdown(context, ref, allShopsAsync),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: controller.currentMode == InboundMode.purchase
                  ? _buildSupplierInput(context, ref)
                  : _buildSourceInput(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopDropdown(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Shop>> allShopsAsync,
  ) {
    return SizedBox(
      height: 40,
      child: IntrinsicWidth(
        child: allShopsAsync.when(
          data: (shops) {
            return DropdownButtonFormField<Shop>(
              key: const Key('shop_dropdown'),
              focusNode: controller.shopFocusNode,
              value: controller.selectedShop,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: shops
                  .map(
                    (shop) => DropdownMenuItem(
                      value: shop,
                      child: Text(shop.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => controller.setShop(value),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('无法加载店铺: $err'),
        ),
      ),
    );
  }

  Widget _buildSupplierInput(BuildContext context, WidgetRef ref) {
  return Row(
    // 依然保持几何中心对齐，通过调整 Padding 来修正视觉偏差
    crossAxisAlignment: CrossAxisAlignment.center, 
    children: [
      const Text('供应商:', style: TextStyle(fontSize: 17)),
      const SizedBox(width: 8),
      Expanded(
        child: TypeAheadField<Supplier>(
          key: const Key('supplier_typeahead'),
          controller: controller.supplierController,
          focusNode: controller.supplierFocusNode,
          suggestionsCallback: (pattern) =>
              ref.read(searchSuppliersProvider(pattern).future),
          itemBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion.name),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onSelected: controller.setSupplier,
          builder: (context, textController, focusNode) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              // 1. 确保输入字体大小与标签一致
              style: const TextStyle(fontSize: 17), 
              // 2. 移除 textAlignVertical: TextAlignVertical.center
              // 因为这会强制垂直居中，反而我们要手动控制位置
              
              decoration: const InputDecoration(
                hintText: '搜索或选择',
                hintStyle: TextStyle(fontSize: 17, color: Colors.grey),
                isDense: true,
                // 3. 核心修改：使用非对称 Padding
                // 增加 top (12)，减少 bottom (4)，将文字向下推，修正视觉偏差
                contentPadding: EdgeInsets.fromLTRB(0, 12, 0, 4), 
                
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildSourceInput(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('来源:', style: TextStyle(fontSize: 17)),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller.sourceController,
            style: const TextStyle(fontSize: 15.5),
            decoration: const InputDecoration(
              hintText: '输入货品来源 (可选)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ],
    );
  }
}
