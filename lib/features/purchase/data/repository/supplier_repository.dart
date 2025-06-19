import '../../domain/repository/i_supplier_repository.dart';
import '../../domain/model/supplier.dart';
import '../../../../core/database/database.dart';
import '../dao/supplier_dao.dart';
import 'package:drift/drift.dart';

/// 供应商仓储实现类
/// 基于本地数据库的供应商数据访问层实现
class SupplierRepository implements ISupplierRepository {
  final SupplierDao _supplierDao;

  SupplierRepository(AppDatabase database)
    : _supplierDao = database.supplierDao;

  @override
  Future<int> addSupplier(Supplier supplier) async {
    try {
      print('🗃️ 仓储层：添加供应商，ID: ${supplier.id}, 名称: ${supplier.name}');
      return await _supplierDao.insertSupplier(_supplierToCompanion(supplier));
    } catch (e) {
      print('🗃️ 仓储层：添加供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    try {
      final data = await _supplierDao.getSupplierById(id);
      return data != null ? _supplierDataToModel(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据ID获取供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<Supplier?> getSupplierByName(String name) async {
    try {
      final data = await _supplierDao.getSupplierByName(name);
      return data != null ? _supplierDataToModel(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据名称获取供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Supplier>> getAllSuppliers() async {
    try {
      final dataList = await _supplierDao.getAllSuppliers();
      return dataList.map(_supplierDataToModel).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有供应商失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Supplier>> watchAllSuppliers() {
    try {
      return _supplierDao.watchAllSuppliers().map(
        (dataList) => dataList.map(_supplierDataToModel).toList(),
      );
    } catch (e) {
      print('🗃️ 仓储层：监听所有供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      print('🗃️ 仓储层：更新供应商，ID: ${supplier.id}, 名称: ${supplier.name}');
      return await _supplierDao.updateSupplier(_supplierToCompanion(supplier));
    } catch (e) {
      print('🗃️ 仓储层：更新供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteSupplier(String id) async {
    try {
      print('🗃️ 仓储层：删除供应商，ID: $id');
      final success = await _supplierDao.deleteSupplier(id);
      return success ? 1 : 0;
    } catch (e) {
      print('🗃️ 仓储层：删除供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isSupplierNameExists(String name, [String? excludeId]) async {
    try {
      final supplier = await _supplierDao.getSupplierByName(name);
      if (supplier == null) return false;
      if (excludeId != null && supplier.id == excludeId) return false;
      return true;
    } catch (e) {
      print('🗃️ 仓储层：检查供应商名称是否存在失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Supplier>> searchSuppliersByName(String searchTerm) async {
    try {
      final dataList = await _supplierDao.searchSuppliersByName(searchTerm);
      return dataList.map(_supplierDataToModel).toList();
    } catch (e) {
      print('🗃️ 仓储层：根据名称搜索供应商失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> getSupplierCount() async {
    try {
      return await _supplierDao.getSupplierCount();
    } catch (e) {
      print('🗃️ 仓储层：获取供应商数量失败: $e');
      rethrow;
    }
  }

  /// 将领域模型转换为数据库Companion对象
  SuppliersTableCompanion _supplierToCompanion(Supplier supplier) {
    return SuppliersTableCompanion(
      id: Value(supplier.id),
      name: Value(supplier.name),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// 将数据库Data对象转换为领域模型
  Supplier _supplierDataToModel(SuppliersTableData data) {
    return Supplier(id: data.id, name: data.name);
  }
}
