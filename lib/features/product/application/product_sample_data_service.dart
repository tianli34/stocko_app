import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model/product.dart';
import 'provider/product_providers.dart';

/// 产品示例数据服务
/// 用于创建和管理测试产品数据，特别是带有条码的产品
class ProductSampleDataService {
  final ProductController _controller;

  ProductSampleDataService(this._controller);

  /// 创建示例产品数据
  Future<void> createSampleProducts() async {
    final sampleProducts = [
      Product(
        id: 'prod_water_001',
        name: '农夫山泉(550ml)',
        barcode: '6901234567890',
        sku: 'NFM-550',
        retailPrice: 2.0,
        suggestedRetailPrice: 2.5,
        promotionalPrice: 1.8,
        specification: '550ml',
        brand: '农夫山泉',
        stockWarningValue: 50,
        shelfLife: 365,
        shelfLifeUnit: 'days',
        status: 'active',
        enableBatchManagement: false,
        remarks: '天然矿泉水',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_chips_001',
        name: '乐事薯片(原味)',
        barcode: '6901234567891',
        sku: 'LAY-ORG',
        retailPrice: 8.5,
        suggestedRetailPrice: 10.0,
        promotionalPrice: 7.0,
        specification: '70g',
        brand: '乐事',
        stockWarningValue: 20,
        shelfLife: 12,
        shelfLifeUnit: 'months',
        status: 'active',
        enableBatchManagement: false,
        remarks: '原味薯片',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_cookie_001',
        name: '奥利奥饼干',
        barcode: '6901234567892',
        sku: 'ORE-001',
        retailPrice: 12.0,
        suggestedRetailPrice: 15.0,
        promotionalPrice: 10.0,
        specification: '130g',
        brand: '奥利奥',
        stockWarningValue: 30,
        shelfLife: 18,
        shelfLifeUnit: 'months',
        status: 'active',
        enableBatchManagement: false,
        remarks: '夹心饼干',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_milk_001',
        name: '蒙牛纯牛奶',
        barcode: '6901234567893',
        sku: 'MN-MILK',
        retailPrice: 3.5,
        suggestedRetailPrice: 4.0,
        promotionalPrice: 3.0,
        specification: '250ml',
        brand: '蒙牛',
        stockWarningValue: 40,
        shelfLife: 30,
        shelfLifeUnit: 'days',
        status: 'active',
        enableBatchManagement: true,
        remarks: '纯牛奶',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_bread_001',
        name: '桃李面包(切片)',
        barcode: '6901234567894',
        sku: 'TL-BREAD',
        retailPrice: 6.0,
        suggestedRetailPrice: 7.0,
        promotionalPrice: 5.0,
        specification: '400g',
        brand: '桃李',
        stockWarningValue: 15,
        shelfLife: 7,
        shelfLifeUnit: 'days',
        status: 'active',
        enableBatchManagement: true,
        remarks: '新鲜面包',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_instant_noodles_001',
        name: '康师傅红烧牛肉面',
        barcode: '6901234567895',
        sku: 'KSF-BEEF',
        retailPrice: 4.5,
        suggestedRetailPrice: 5.0,
        promotionalPrice: 4.0,
        specification: '125g',
        brand: '康师傅',
        stockWarningValue: 25,
        shelfLife: 12,
        shelfLifeUnit: 'months',
        status: 'active',
        enableBatchManagement: false,
        remarks: '方便面',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_juice_001',
        name: '汇源100%橙汁',
        barcode: '6901234567896',
        sku: 'HY-ORANGE',
        retailPrice: 5.5,
        suggestedRetailPrice: 6.5,
        promotionalPrice: 4.8,
        specification: '1L',
        brand: '汇源',
        stockWarningValue: 35,
        shelfLife: 18,
        shelfLifeUnit: 'months',
        status: 'active',
        enableBatchManagement: false,
        remarks: '100%纯果汁',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'prod_yogurt_001',
        name: '伊利安慕希酸奶',
        barcode: '6901234567897',
        sku: 'YL-AMX',
        retailPrice: 4.0,
        suggestedRetailPrice: 4.8,
        promotionalPrice: 3.5,
        specification: '205g',
        brand: '伊利',
        stockWarningValue: 30,
        shelfLife: 21,
        shelfLifeUnit: 'days',
        status: 'active',
        enableBatchManagement: true,
        remarks: '希腊式酸奶',
        lastUpdated: DateTime.now(),
      ),
    ];

    for (final product in sampleProducts) {
      try {
        await _controller.addProduct(product);
        print('✅ 创建示例产品成功: ${product.name} (条码: ${product.barcode})');
      } catch (e) {
        print('❌ 创建示例产品失败: ${product.name} - $e');
      }
    }
  }

  /// 清除所有产品数据（谨慎使用）
  Future<void> clearAllProducts() async {
    // 注意：这个功能应该只在开发环境使用
    print('⚠️  清除所有产品数据的功能需要在仓储层实现');
  }
}

/// 产品示例数据服务提供者
final productSampleDataServiceProvider = Provider<ProductSampleDataService>((
  ref,
) {
  final controller = ref.watch(productControllerProvider.notifier);
  return ProductSampleDataService(controller);
});
