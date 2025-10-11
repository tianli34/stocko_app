import 'package:flutter/material.dart';

/// 价格区块：促销价 + 建议零售价
class PricingSection extends StatefulWidget {
  final TextEditingController promotionalPriceController;
  final TextEditingController suggestedRetailPriceController;

  const PricingSection({
    super.key,
    required this.promotionalPriceController,
    required this.suggestedRetailPriceController,
  });

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  late FocusNode _promotionalPriceFocusNode;
  late FocusNode _suggestedRetailPriceFocusNode;
  bool _isPromotionalPriceFocused = false;
  bool _isSuggestedRetailPriceFocused = false;

  @override
  void initState() {
    super.initState();
    // 创建新的 FocusNode
    _promotionalPriceFocusNode = FocusNode();
    _suggestedRetailPriceFocusNode = FocusNode();
    // 添加监听器
    _promotionalPriceFocusNode.addListener(_onPromotionalPriceFocusChange);
    _suggestedRetailPriceFocusNode.addListener(_onSuggestedRetailPriceFocusChange);
  }

  @override
  void dispose() {
    // 释放 FocusNode
    _promotionalPriceFocusNode.dispose();
    _suggestedRetailPriceFocusNode.dispose();
    super.dispose();
  }

  void _onPromotionalPriceFocusChange() {
    setState(() {
      _isPromotionalPriceFocused = _promotionalPriceFocusNode.hasFocus;
    });
  }

  void _onSuggestedRetailPriceFocusChange() {
    setState(() {
      _isSuggestedRetailPriceFocused = _suggestedRetailPriceFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标签显示在左边
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '促销价',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.promotionalPriceController,
                  focusNode: _promotionalPriceFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _isPromotionalPriceFocused ? '' : '',
                    prefixText: '¥ ',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标签显示在左边
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '建议零售价',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.suggestedRetailPriceController,
                  focusNode: _suggestedRetailPriceFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _isSuggestedRetailPriceFocused ? '' : '',
                    prefixText: '¥ ',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
