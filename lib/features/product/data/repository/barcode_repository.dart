import '../../domain/repository/i_barcode_repository.dart';
import '../../domain/model/barcode.dart';
import '../../../../core/database/database.dart';
import '../dao/barcode_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 条码仓储实现类
/// 基于本地数据库的条码数据访问层实现
class BarcodeRepository implements IBarcodeRepository {
  final BarcodeDao _barcodeDao;

  BarcodeRepository(AppDatabase database) : _barcodeDao = database.barcodeDao;

  @override
  Future<int> addBarcode(BarcodeModel barcode) async {
    try {
      print('🗃️ 仓储层：添加条码，ID: ${barcode.id}');
      return await _barcodeDao.insertBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：添加条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMultipleBarcodes(List<BarcodeModel> barcodes) async {
    try {
      print('🗃️ 仓储层：批量添加条码，数量: ${barcodes.length}');
      final companions = barcodes.map(_barcodeToCompanion).toList();
      await _barcodeDao.insertMultipleBarcodes(companions);
    } catch (e) {
      print('🗃️ 仓储层：批量添加条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<BarcodeModel?> getBarcodeById(int id) async {
    try {
      final data = await _barcodeDao.getBarcodeById(id);
      return data != null ? _dataToBarcode(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据ID获取条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<BarcodeModel?> getBarcodeByValue(String barcode) async {
    try {
      final data = await _barcodeDao.getBarcodeByValue(barcode);
      return data != null ? _dataToBarcode(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据条码值获取条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<BarcodeModel>> getBarcodesByProductUnitId(int? productUnitId) async {
    if (productUnitId == null) {
      return [];
    }
    try {
      final dataList = await _barcodeDao.getBarcodesByProductUnitId(
        productUnitId,
      );
      return dataList.map(_dataToBarcode).toList();
    } catch (e) {
      print('🗃️ 仓储层：根据产品单位ID获取条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<BarcodeModel>> getAllBarcodes() async {
    try {
      final dataList = await _barcodeDao.getAllBarcodes();
      return dataList.map(_dataToBarcode).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有条码失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<BarcodeModel>> watchBarcodesByProductUnitId(int productUnitId) {
    try {
      return _barcodeDao
          .watchBarcodesByProductUnitId(productUnitId)
          .map((dataList) => dataList.map(_dataToBarcode).toList());
    } catch (e) {
      print('🗃️ 仓储层：监听产品单位条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateBarcode(BarcodeModel barcode) async {
    try {
      print('🗃️ 仓储层：更新条码，ID: ${barcode.id}');
      return await _barcodeDao.updateBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：更新条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteBarcode(int id) async {
    try {
      print('🗃️ 仓储层：删除条码，ID: $id');
      return await _barcodeDao.deleteBarcode(id);
    } catch (e) {
      print('🗃️ 仓储层：删除条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteBarcodesByProductUnitId(int productUnitId) async {
    try {
      print('🗃️ 仓储层：删除产品单位的所有条码，产品单位ID: $productUnitId');
      return await _barcodeDao.deleteBarcodesByProductUnitId(productUnitId);
    } catch (e) {
      print('🗃️ 仓储层：删除产品单位条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> barcodeExists(String barcode) async {
    try {
      return await _barcodeDao.barcodeExists(barcode);
    } catch (e) {
      print('🗃️ 仓储层：检查条码是否存在失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> productUnitHasBarcode(
    int productUnitId,
    String barcode,
  ) async {
    try {
      return await _barcodeDao.productUnitHasBarcode(productUnitId, barcode);
    } catch (e) {
      print('🗃️ 仓储层：检查产品单位是否有条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertBarcode(BarcodeModel barcode) async {
    try {
      print('🗃️ 仓储层：更新或插入条码，ID: ${barcode.id}');
      await _barcodeDao.upsertBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：更新或插入条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertMultipleBarcodes(List<BarcodeModel> barcodes) async {
    try {
      print('🗃️ 仓储层：批量更新或插入条码，数量: ${barcodes.length}');
      final companions = barcodes.map(_barcodeToCompanion).toList();
      await _barcodeDao.upsertMultipleBarcodes(companions);
    } catch (e) {
      print('🗃️ 仓储层：批量更新或插入条码失败: $e');
      rethrow;
    }
  }

  /// 将Barcode模型转换为数据库Companion
  BarcodeCompanion _barcodeToCompanion(BarcodeModel barcode) {
    return BarcodeCompanion(
      productUnitId: Value(barcode.productUnitId),
      barcodeValue: Value(barcode.barcodeValue),
    );
  }

  /// 将数据库数据转换为Barcode模型
  BarcodeModel _dataToBarcode(BarcodeData data) {
    return BarcodeModel(
      id: data.id,
      productUnitId: data.productUnitId,
      barcodeValue: data.barcodeValue,
    );
  }
}

/// BarcodeModel Repository Provider
final barcodeRepositoryProvider = Provider<IBarcodeRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BarcodeRepository(database);
});
