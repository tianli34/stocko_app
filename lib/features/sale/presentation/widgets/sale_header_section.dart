import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:collection/collection.dart';
import '../../../../config/flavor_config.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../application/provider/customer_providers.dart';
import '../../domain/model/customer.dart';

class SaleHeaderSection extends ConsumerWidget {
  final Shop? selectedShop;
  final Customer? selectedCustomer;
  final TextEditingController customerController;
  final FocusNode shopFocusNode;
  final FocusNode customerFocusNode;
  final ValueChanged<Shop?> onShopChanged;
  final ValueChanged<Customer?> onCustomerSelected;
  final VoidCallback onCustomerSubmitted;

  const SaleHeaderSection({
    super.key,
    required this.selectedShop,
    required this.selectedCustomer,
    required this.customerController,
    required this.shopFocusNode,
    required this.customerFocusNode,
    required this.onShopChanged,
    required this.onCustomerSelected,
    required this.onCustomerSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allShopsAsync = ref.watch(allShopsProvider);
    final flavor = ref.watch(flavorConfigProvider).flavor;
    final isGeneric = flavor == AppFlavor.generic;

    return Container(
      decoration: BoxDecoration(
        // border: Border.all(color: Colors.grey),
      ),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        allShopsAsync.when(
          data: (shops) {
            if (selectedShop == null) {
              final defaultShopName = isGeneric ? '我的店铺' : '长山的店';
              final defaultShop = shops.firstWhereOrNull(
                (shop) => shop.name == defaultShopName,
              );
              if (defaultShop != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onShopChanged(defaultShop);
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
              IntrinsicWidth(
                child: allShopsAsync.when(
                  data: (shops) {
                    return DropdownButtonFormField<Shop>(
                      key: const Key('shop_dropdown'),
                      focusNode: shopFocusNode,
                      value: selectedShop,
                      decoration: InputDecoration(
                        isDense: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: shops
                          .map(
                            (shop) => DropdownMenuItem(
                              value: shop,
                              child: Text(shop.name),
                            ),
                          )
                          .toList(),
                      onChanged: onShopChanged,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('无法加载店铺: $err'),
                ),
              ),
            if (!isGeneric) const SizedBox(width: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('顾客:', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TypeAheadField<Customer>(
                      key: const Key('customer_typeahead'),
                      controller: customerController,
                      focusNode: customerFocusNode,
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
                        onCustomerSelected(suggestion);
                        customerFocusNode.unfocus();
                      },
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: '搜索或选择',
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => onCustomerSubmitted(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }
}
