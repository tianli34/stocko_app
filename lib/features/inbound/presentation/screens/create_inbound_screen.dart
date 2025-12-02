import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/scanned_product_payload.dart';
import '../../application/provider/inbound_list_provider.dart';
import '../widgets/create_inbound_action_buttons.dart';
import '../widgets/create_inbound_bottom_bar.dart';
import '../widgets/create_inbound_header.dart';
import '../widgets/create_inbound_totals_bar.dart';
import '../widgets/inbound_cart_list.dart';
import 'create_inbound_actions.dart';
import 'create_inbound_controller.dart';

export 'create_inbound_controller.dart' show InboundMode;

/// 新建入库单页面
class CreateInboundScreen extends ConsumerStatefulWidget {
  final ScannedProductPayload? payload;
  const CreateInboundScreen({super.key, this.payload});

  @override
  ConsumerState<CreateInboundScreen> createState() =>
      _CreateInboundScreenState();
}

class _CreateInboundScreenState extends ConsumerState<CreateInboundScreen>
    with CreateInboundActions {
  late final CreateInboundController _controller;

  @override
  CreateInboundController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateInboundController(
      ref: ref,
      context: context,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init(widget.payload);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final inboundItemCount = ref.watch(
      inboundListProvider.select((items) => items.length),
    );
    final totals = ref.watch(inboundTotalsProvider);
    final totalVarieties = totals['varieties']?.toInt() ?? 0;
    final totalQuantity = totals['quantity']?.toInt() ?? 0;
    final totalAmount = totals['amount'] ?? 0.0;

    _controller.ensureFocusNodes(inboundItemCount);

    final canPop = context.canPop();
    final isPurchaseMode = _controller.currentMode == InboundMode.purchase;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: _buildAppBar(canPop, textTheme),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreateInboundHeader(
                  controller: _controller,
                  onStateChanged: () => setState(() {}),
                ),
                const SizedBox(height: 0),
                InboundCartList(
                  showPriceInfo: isPurchaseMode,
                  quantityFocusNodes: _controller.quantityFocusNodes,
                  amountFocusNodes: _controller.amountFocusNodes,
                  onAmountSubmitted: _controller.handleNextStep,
                ),
                const SizedBox(height: 0),
                CreateInboundActionButtons(
                  onAddManual: addManualProduct,
                  onScanSingle: scanToAddProduct,
                  onScanContinuous: continuousScan,
                ),
                const SizedBox(height: 4),
                CreateInboundTotalsBar(
                  totalVarieties: totalVarieties,
                  totalQuantity: totalQuantity,
                  totalAmount: totalAmount,
                  showAmount: isPurchaseMode,
                ),
                const SizedBox(height: 4),
                CreateInboundBottomBar(
                  currentMode: _controller.currentMode,
                  isProcessing: _controller.isProcessing,
                  onPurchaseOnly: confirmPurchaseOnly,
                  onInbound: confirmInbound,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool canPop, TextTheme textTheme) {
    return AppBar(
      leading: !canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
              tooltip: '返回',
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_controller.currentMode == InboundMode.purchase
              ? '采购入库'
              : '非采购入库'),
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: '切换模式',
            onPressed: _controller.toggleMode,
          ),
        ],
      ),
      actions: [const SizedBox(width: 8)],
    );
  }
}
