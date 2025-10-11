import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/flavor_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/models/scanned_product_payload.dart';
import '../../../../core/widgets/product_info_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  Future<void> _scanAndShowProductDialog() async {
    // 1) 调起扫码
    final barcode = await BarcodeScannerService.quickScan(context, title: '扫描条码');
    if (!mounted || barcode == null || barcode.isEmpty) return;

    // 2) 查询货品主要信息
    try {
      final operations = ref.read(productOperationsProvider.notifier);
      final result = await operations.getProductWithUnitByBarcode(barcode);

      if (!mounted) return;

      if (result == null) {
        showAppSnackBar(context, message: '未找到条码对应的货品', isError: true);
        return;
      }

      // 3) 构建 payload 并展示复用对话框
      final payload = ScannedProductPayload(
        product: result.product,
        barcode: barcode,
        unitId: result.unitId,
        unitName: result.unitName,
        conversionRate: result.conversionRate,
        sellingPriceInCents: result.sellingPriceInCents,
        wholesalePriceInCents: result.wholesalePriceInCents,
        averageUnitPriceInCents: result.averageUnitPriceInCents,
      );

      final action = await showProductInfoDialog(context, payload: payload);
      if (!mounted) return;
      switch (action) {
        case ProductInfoAction.sale:
          context.push(AppRoutes.saleCreate, extra: payload);
          break;
        case ProductInfoAction.purchase:
          context.push(AppRoutes.inboundCreate, extra: payload);
          break;
        case ProductInfoAction.cancel:
        case null:
          break;
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: '查询货品失败：$e', isError: true);
    }
  }

  // 隐私弹窗已由 AppInitializer 统一处理，这里不再重复处理。

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final flavorConfig = ref.watch(flavorConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stocko - 首页')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '欢迎使用 Stocko 库存管理系统',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '请选择功能模块',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.products),
                    child: const Text('产品管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.productNew),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('新增货品'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.productRanking),
                    child: const Text('产品排行'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inventory),
                    child: const Text('库存管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inboundCreate),
                    child: const Text('新建入库单'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.purchase),
                    child: const Text('采购管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.sales),
                    child: const Text('销售管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.saleCreate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('收银台'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.customers),
                    child: const Text('客户管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('设置'),
                  ),
                  if (flavorConfig.featureFlags[Feature.showDatabaseTools] == true) ...[
                    ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.databaseManagement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('数据库管理'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.databaseViewer),
                      child: const Text('数据库查看器'),
                    ),
                  ],
                  // ElevatedButton(
                  //   onPressed: () =>
                  //       context.push(AppRoutes.categoryTest),
                  //   child: const Text('类别管理测试'),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}