import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/scanned_product_payload.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/custom_date_picker.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../purchase/domain/model/supplier.dart';
import '../../application/provider/inbound_list_provider.dart';

enum InboundMode { purchase, nonPurchase }

/// 入库页面控制器 - 管理业务逻辑
class CreateInboundController {
  final WidgetRef ref;
  final BuildContext context;
  final VoidCallback onStateChanged;

  CreateInboundController({
    required this.ref,
    required this.context,
    required this.onStateChanged,
  });

  final remarksController = TextEditingController();
  final supplierController = TextEditingController();
  final sourceController = TextEditingController();

  InboundMode currentMode = InboundMode.purchase;
  Supplier? selectedSupplier;
  Shop? selectedShop;
  bool isProcessing = false;
  String? lastScannedBarcode;

  final FocusNode shopFocusNode = FocusNode();
  final FocusNode supplierFocusNode = FocusNode();
  final List<FocusNode> quantityFocusNodes = [];
  final List<FocusNode> amountFocusNodes = [];

  void init(ScannedProductPayload? payload) {
    ref.read(inboundListProvider.notifier).clear();
    if (payload != null) {
      try {
        ref.read(inboundListProvider.notifier).addOrUpdateItem(
              product: payload.product,
              unitId: payload.unitId,
              unitName: payload.unitName,
              conversionRate: payload.conversionRate,
              barcode: payload.barcode,
              wholesalePriceInCents: payload.wholesalePriceInCents,
            );
      } catch (_) {}
    }
  }

  void dispose() {
    remarksController.dispose();
    supplierController.dispose();
    sourceController.dispose();
    shopFocusNode.dispose();
    supplierFocusNode.dispose();
    for (var node in quantityFocusNodes) {
      node.dispose();
    }
    for (var node in amountFocusNodes) {
      node.dispose();
    }
  }

  void ensureFocusNodes(int itemCount) {
    while (quantityFocusNodes.length < itemCount) {
      quantityFocusNodes.add(FocusNode());
    }
    while (amountFocusNodes.length < itemCount) {
      amountFocusNodes.add(FocusNode());
    }
  }

  void toggleMode() {
    currentMode = currentMode == InboundMode.purchase
        ? InboundMode.nonPurchase
        : InboundMode.purchase;
    onStateChanged();
  }

  void setShop(Shop? shop) {
    selectedShop = shop;
    onStateChanged();
  }

  void setSupplier(Supplier? supplier) {
    selectedSupplier = supplier;
    if (supplier != null) {
      supplierController.text = supplier.name;
    }
    supplierFocusNode.unfocus();
    onStateChanged();
  }

  Future<void> handleNextStep(int index) async {
    final inboundItems = ref.read(inboundListProvider);
    if (index >= inboundItems.length) return;

    final item = inboundItems[index];
    final productAsync = ref.read(productByIdProvider(item.productId));

    final product = productAsync.valueOrNull;
    
    if (product?.enableBatchManagement == true) {
      // 取消所有焦点，避免日期选择器关闭后焦点回到之前的输入框
      FocusManager.instance.primaryFocus?.unfocus();
      final pickedDate = await _selectProductionDate(item);
      if (pickedDate != null) {
        final updatedItem = item.copyWith(productionDate: pickedDate);
        ref.read(inboundListProvider.notifier).updateItem(updatedItem);
      }
      // 日期选择完成后，处理焦点
      _handleFocusAfterDatePicker(index);
    } else {
      // 不需要选择日期，直接移动到下一个
      _moveToNextQuantity(index);
    }
  }

  /// 日期选择器关闭后处理焦点：移动到下一个数量输入框或取消焦点
  void _handleFocusAfterDatePicker(int index) {
    final itemCount = ref.read(inboundListProvider).length;
    if (index + 1 < itemCount) {
      // 使用延迟确保在 Flutter 焦点恢复机制之后执行
      Future.delayed(const Duration(milliseconds: 100), () {
        quantityFocusNodes[index + 1].requestFocus();
      });
    } else {
      // 没有下一个输入框，焦点保持取消状态
    }
  }

  void _moveToNextQuantity(int index) {
    final itemCount = ref.read(inboundListProvider).length;
    if (index + 1 < itemCount) {
      quantityFocusNodes[index + 1].requestFocus();
    }
  }

  Future<DateTime?> _selectProductionDate(InboundItemState item) async {
    return await CustomDatePicker.show(
      context: context,
      initialDate: item.productionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: '选择生产日期',
    );
  }

  ({int? supplierId, String? supplierName}) getSupplierInfo() {
    if (selectedSupplier != null) {
      return (supplierId: selectedSupplier!.id, supplierName: selectedSupplier!.name);
    } else {
      return (supplierId: null, supplierName: supplierController.text.trim());
    }
  }

  bool validateForm() {
    if (currentMode == InboundMode.purchase) {
      if (selectedSupplier == null && supplierController.text.trim().isEmpty) {
        showAppSnackBar(context, message: '请选择或输入供应商名称', isError: true);
        return false;
      }
    }
    if (selectedShop == null) {
      showAppSnackBar(context, message: '请选择入库店铺', isError: true);
      return false;
    }
    final inboundItems = ref.read(inboundListProvider);
    if (inboundItems.isEmpty) {
      showAppSnackBar(context, message: '请先添加货品', isError: true);
      return false;
    }
    for (final item in inboundItems) {
      if (item.quantity <= 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的数量必须大于0',
          isError: true,
        );
        return false;
      }
      if (currentMode == InboundMode.purchase && item.unitPriceInSis < 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的单价不能为负数',
          isError: true,
        );
        return false;
      }
      if (currentMode == InboundMode.purchase && item.unitPriceInSis == 0) {
        showAppSnackBar(
          context,
          message: '货品"${item.productName}"的单价不能为0',
          isError: true,
        );
        return false;
      }
    }
    return true;
  }
}
