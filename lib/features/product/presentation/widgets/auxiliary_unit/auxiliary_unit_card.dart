import 'package:flutter/material.dart';

import '../../../shared/constants/product_constants.dart';
import '../form_field_wrapper.dart';
import 'auxiliary_unit_model.dart';

/// 辅单位卡片组件
/// 
/// 显示单个辅单位的编辑表单
class AuxiliaryUnitCard extends StatelessWidget {
  /// 辅单位数据模型
  final AuxiliaryUnitModel auxiliaryUnit;
  
  /// 索引
  final int index;
  
  /// 基本单位名称
  final String? baseUnitName;
  
  /// 删除回调
  final VoidCallback onRemove;
  
  /// 选择单位回调
  final VoidCallback onSelectUnit;
  
  /// 扫描条码回调
  final VoidCallback onScanBarcode;
  
  /// 单位名称变更回调
  final ValueChanged<String> onUnitNameChanged;
  
  /// 换算率变更回调
  final ValueChanged<String> onConversionRateChanged;
  
  /// 条码变更回调
  final ValueChanged<String> onBarcodeChanged;
  
  /// 零售价变更回调
  final ValueChanged<String> onRetailPriceChanged;
  
  /// 批发价变更回调
  final ValueChanged<String> onWholesalePriceChanged;
  
  /// 返回按键回调
  final VoidCallback onReturnPressed;

  const AuxiliaryUnitCard({
    super.key,
    required this.auxiliaryUnit,
    required this.index,
    required this.baseUnitName,
    required this.onRemove,
    required this.onSelectUnit,
    required this.onScanBarcode,
    required this.onUnitNameChanged,
    required this.onConversionRateChanged,
    required this.onBarcodeChanged,
    required this.onRetailPriceChanged,
    required this.onWholesalePriceChanged,
    required this.onReturnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildUnitNameField(context),
            const SizedBox(height: 12),
            _buildConversionRateField(),
            const SizedBox(height: 12),
            _buildBarcodeField(context),
            const SizedBox(height: 12),
            _buildRetailPriceField(),
            const SizedBox(height: 12),
            _buildWholesalePriceField(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '辅单位${index + 1}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 78, 4, 138)),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildUnitNameField(BuildContext context) {
    return FormFieldWrapper(
      label: '辅单位名称',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                hintText: '请输入或选择单位名称',
                border: OutlineInputBorder(),
              ),
              controller: auxiliaryUnit.unitController,
              focusNode: auxiliaryUnit.unitFocusNode,
              onFieldSubmitted: (_) => auxiliaryUnit.conversionRateFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入单位名称';
                }
                return null;
              },
              onChanged: onUnitNameChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSelectUnit,
            icon: const Icon(Icons.list),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).primaryColor,
            ),
            tooltip: '选择单位',
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRateField() {
    return FormFieldWrapper(
      label: '换算率 (相对于${baseUnitName ?? '基本单位'})',
      child: TextFormField(
        decoration: const InputDecoration(
          hintText: '请输入换算率',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        focusNode: auxiliaryUnit.conversionRateFocusNode,
        onFieldSubmitted: (_) => auxiliaryUnit.retailPriceFocusNode.requestFocus(),
        initialValue: auxiliaryUnit.conversionRate > 0
            ? auxiliaryUnit.conversionRate.toString()
            : '',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入换算率';
          }
          final rate = double.tryParse(value.trim());
          if (rate == null || rate <= 0) {
            return '请输入有效的换算率';
          }
          if (rate == kBaseUnitConversionRate) {
            return '辅单位换算率不能为1';
          }
          return null;
        },
        onChanged: onConversionRateChanged,
      ),
    );
  }

  Widget _buildBarcodeField(BuildContext context) {
    return FormFieldWrapper(
      label: '条码',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: auxiliaryUnit.barcodeController,
              decoration: const InputDecoration(
                hintText: '请输入或扫描条码',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!kBarcodePattern.hasMatch(value)) {
                    return '条码只能包含字母、数字和横线';
                  }
                }
                return null;
              },
              onChanged: onBarcodeChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onScanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).primaryColor,
            ),
            tooltip: '扫描条码',
          ),
        ],
      ),
    );
  }

  Widget _buildRetailPriceField() {
    return FormFieldWrapper(
      label: '建议零售价',
      child: TextFormField(
        controller: auxiliaryUnit.retailPriceController,
        focusNode: auxiliaryUnit.retailPriceFocusNode,
        decoration: const InputDecoration(
          hintText: '请输入零售价',
          border: OutlineInputBorder(),
          prefixText: '¥ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _validatePrice,
        onChanged: onRetailPriceChanged,
        onFieldSubmitted: (_) => auxiliaryUnit.wholesalePriceFocusNode.requestFocus(),
      ),
    );
  }

  Widget _buildWholesalePriceField() {
    return FormFieldWrapper(
      label: '批发价',
      child: TextFormField(
        controller: auxiliaryUnit.wholesalePriceController,
        focusNode: auxiliaryUnit.wholesalePriceFocusNode,
        decoration: const InputDecoration(
          hintText: '请输入批发价',
          border: OutlineInputBorder(),
          prefixText: '¥ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _validatePrice,
        onChanged: onWholesalePriceChanged,
        onFieldSubmitted: (_) => onReturnPressed(),
      ),
    );
  }

  String? _validatePrice(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final price = double.tryParse(value.trim());
      if (price == null || price < 0) {
        return '请输入有效的价格';
      }
    }
    return null;
  }
}
