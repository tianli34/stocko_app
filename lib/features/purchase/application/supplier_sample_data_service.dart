import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model/supplier.dart';
import 'provider/supplier_providers.dart';

/// 供应商示例数据服务
/// 用于创建和管理测试供应商数据
class SupplierSampleDataService {
  final SupplierController _controller;

  SupplierSampleDataService(this._controller);

  /// 创建示例供应商数据
  Future<void> createSampleSuppliers() async {
    final sampleSuppliers = [
      const Supplier(id: 'supplier_001', name: '北京百货供应商'),
      const Supplier(id: 'supplier_002', name: '上海食品批发商'),
      const Supplier(id: 'supplier_003', name: '广州日用品供应商'),
      const Supplier(id: 'supplier_004', name: '深圳电子产品供应商'),
      const Supplier(id: 'supplier_005', name: '杭州服装供应商'),
    ];

    for (final supplier in sampleSuppliers) {
      try {
        await _controller.addSupplier(supplier);
        print('✅ 创建示例供应商成功: ${supplier.name}');
      } catch (e) {
        print('❌ 创建示例供应商失败: ${supplier.name} - $e');
      }
    }
  }

  /// 清除所有供应商数据（谨慎使用）
  Future<void> clearAllSuppliers() async {
    // 注意：这个功能应该只在开发环境使用
    print('⚠️  清除所有供应商数据的功能需要在仓储层实现');
  }
}

/// 供应商示例数据服务提供者
final supplierSampleDataServiceProvider = Provider<SupplierSampleDataService>((
  ref,
) {
  final controller = ref.watch(supplierControllerProvider.notifier);
  return SupplierSampleDataService(controller);
});
