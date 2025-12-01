import 'package:flutter/material.dart';

/// 价格区块：成本 + 零售价 + 促销价 + 建议零售价
class PricingSection extends StatefulWidget {
  final TextEditingController costController;
  final TextEditingController retailPriceController;
  final TextEditingController promotionalPriceController;
  final TextEditingController suggestedRetailPriceController;
  final FocusNode? retailPriceFocusNode;
  final VoidCallback? onRetailPriceSubmitted;

  const PricingSection({
    super.key,
    required this.costController,
    required this.retailPriceController,
    required this.promotionalPriceController,
    required this.suggestedRetailPriceController,
    this.retailPriceFocusNode,
    this.onRetailPriceSubmitted,
  });

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  late FocusNode _costFocusNode;
  late FocusNode _promotionalPriceFocusNode;
  late FocusNode _suggestedRetailPriceFocusNode;

  @override
  void initState() {
    super.initState();
    _costFocusNode = FocusNode();
    _promotionalPriceFocusNode = FocusNode();
    _suggestedRetailPriceFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _costFocusNode.dispose();
    _promotionalPriceFocusNode.dispose();
    _suggestedRetailPriceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPriceField(
          label: '成本',
          controller: widget.costController,
          focusNode: _costFocusNode,
        ),
        const SizedBox(height: 16),
        _buildPriceField(
          label: '促销价',
          controller: widget.promotionalPriceController,
          focusNode: _promotionalPriceFocusNode,
        ),
        const SizedBox(height: 16),
        _buildPriceField(
          label: '建议零售价',
          controller: widget.suggestedRetailPriceController,
          focusNode: _suggestedRetailPriceFocusNode,
        ),
        const SizedBox(height: 16),
        _buildPriceField(
          label: '零售价',
          controller: widget.retailPriceController,
          focusNode: widget.retailPriceFocusNode,
          onFieldSubmitted: (_) => widget.onRetailPriceSubmitted?.call(),
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    void Function(String)? onFieldSubmitted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              onFieldSubmitted: onFieldSubmitted,
              decoration: const InputDecoration(
                prefixText: '¥ ',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
