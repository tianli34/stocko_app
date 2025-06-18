import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/domain/model/product.dart';
import '../../domain/model/inbound_item.dart';

/// 入库扫码页面
class InboundBarcodeScannerScreen extends ConsumerStatefulWidget {
  const InboundBarcodeScannerScreen({super.key});

  @override
  ConsumerState<InboundBarcodeScannerScreen> createState() =>
      _InboundBarcodeScannerScreenState();
}

class _InboundBarcodeScannerScreenState
    extends ConsumerState<InboundBarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码添加商品'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flip_camera_ios),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: kIsWeb || const bool.fromEnvironment('flutter.test')
                    ? Container(
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Text(
                            '相机预览\n(测试模式)',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) {
                          if (!isScanning || isSearching) return;

                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final String? code = barcodes.first.rawValue;
                            if (code != null && code.isNotEmpty) {
                              setState(() {
                                isScanning = false;
                              });
                              _searchProductByBarcode(code);
                            }
                          }
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSearching) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      '正在搜索商品...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ] else ...[
                    const Text(
                      '将条码对准扫描框',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 手动输入按钮
                        _buildActionButton(
                          icon: Icons.keyboard,
                          label: '手动输入',
                          onPressed: () => _showManualInputDialog(),
                        ),
                        // 从相册选择按钮
                        _buildActionButton(
                          icon: Icons.photo_library,
                          label: '从相册选择',
                          onPressed: () => _pickFromGallery(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              iconSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 根据条码搜索商品
  void _searchProductByBarcode(String barcode) async {
    setState(() {
      isSearching = true;
    });

    try {
      final productController = ref.read(productControllerProvider.notifier);
      final product = await productController.getProductByBarcode(barcode);

      if (mounted) {
        setState(() {
          isSearching = false;
        });

        if (product != null) {
          _showProductFoundDialog(product, barcode);
        } else {
          _showProductNotFoundDialog(barcode);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        _showErrorDialog('搜索商品时发生错误: ${e.toString()}');
      }
    }
  }

  /// 显示找到商品的对话框
  void _showProductFoundDialog(Product product, String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text('找到商品'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品信息
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.specification != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '规格: ${product.specification}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '条码: $barcode',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanning = true;
                });
              },
              child: const Text('重新扫描'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // 创建入库项目
                final now = DateTime.now();
                final inboundItem = InboundItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  receiptId: '', // 稍后由入库单设置
                  productId: product.id,
                  productName: product.name,
                  productSpec: product.specification ?? '',
                  productImage: product.image,
                  quantity: 1.0, // 默认入库数量为1
                  unitId: product.unitId ?? 'default_unit', // 使用产品的单位ID
                  productionDate: product.enableBatchManagement
                      ? DateTime.now()
                      : null,
                  locationId: null,
                  locationName: null,
                  purchaseQuantity: 0.0, // 默认采购数量为0
                  createdAt: now,
                  updatedAt: now,
                );

                Navigator.of(context).pop(inboundItem);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('添加到入库单'),
            ),
          ],
        );
      },
    );
  }

  /// 显示未找到商品的对话框
  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('未找到商品'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('系统中没有找到对应的商品信息：'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '您可以：\n1. 重新扫描确认条码正确\n2. 先添加该商品到系统中\n3. 手动输入正确的条码',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanning = true;
                });
              },
              child: const Text('重新扫描'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回到入库单页面
                // TODO: 可以跳转到新增商品页面
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('添加新商品'),
            ),
          ],
        );
      },
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Text('错误'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanning = true;
                });
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示手动输入对话框
  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('手动输入条码'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: '条码',
              hintText: '请输入条码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(context).pop();
                  _searchProductByBarcode(code);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 从相册选择图片扫描
  void _pickFromGallery() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该功能暂不可用，请使用相机扫描'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
