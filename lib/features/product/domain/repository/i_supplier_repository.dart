import '../model/supplier.dart';

/// 供应商仓储接口
/// 定义供应商相关的业务操作规范
abstract class ISupplierRepository {
  /// 添加供应商
  Future<int> addSupplier(Supplier supplier);

  /// 根据ID获取供应商
  Future<Supplier?> getSupplierById(String id);

  /// 根据名称获取供应商
  Future<Supplier?> getSupplierByName(String name);

  /// 获取所有供应商
  Future<List<Supplier>> getAllSuppliers();

  /// 监听所有供应商变化
  Stream<List<Supplier>> watchAllSuppliers();

  /// 更新供应商
  Future<bool> updateSupplier(Supplier supplier);

  /// 删除供应商
  Future<int> deleteSupplier(String id);

  /// 检查供应商名称是否已存在
  Future<bool> isSupplierNameExists(String name, [String? excludeId]);

  /// 根据名称搜索供应商
  Future<List<Supplier>> searchSuppliersByName(String searchTerm);

  /// 获取供应商数量
  Future<int> getSupplierCount();
}
