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
  Future<int> addBarcode(Barcode barcode) async {
    try {
      print('🗃️ 仓储层：添加条码，ID: ${barcode.id}');
      return await _barcodeDao.insertBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：添加条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMultipleBarcodes(List<Barcode> barcodes) async {
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
  Future<Barcode?> getBarcodeById(String id) async {
    try {
      final data = await _barcodeDao.getBarcodeById(id);
      return data != null ? _dataToBarcode(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据ID获取条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<Barcode?> getBarcodeByValue(String barcode) async {
    try {
      final data = await _barcodeDao.getBarcodeByValue(barcode);
      return data != null ? _dataToBarcode(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据条码值获取条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Barcode>> getBarcodesByProductUnitId(String productUnitId) async {
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
  Future<List<Barcode>> getAllBarcodes() async {
    try {
      final dataList = await _barcodeDao.getAllBarcodes();
      return dataList.map(_dataToBarcode).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有条码失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Barcode>> watchBarcodesByProductUnitId(String productUnitId) {
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
  Future<bool> updateBarcode(Barcode barcode) async {
    try {
      print('🗃️ 仓储层：更新条码，ID: ${barcode.id}');
      return await _barcodeDao.updateBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：更新条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteBarcode(String id) async {
    try {
      print('🗃️ 仓储层：删除条码，ID: $id');
      return await _barcodeDao.deleteBarcode(id);
    } catch (e) {
      print('🗃️ 仓储层：删除条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteBarcodesByProductUnitId(String productUnitId) async {
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
    String productUnitId,
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
  Future<void> upsertBarcode(Barcode barcode) async {
    try {
      print('🗃️ 仓储层：更新或插入条码，ID: ${barcode.id}');
      await _barcodeDao.upsertBarcode(_barcodeToCompanion(barcode));
    } catch (e) {
      print('🗃️ 仓储层：更新或插入条码失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertMultipleBarcodes(List<Barcode> barcodes) async {
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
  BarcodesTableCompanion _barcodeToCompanion(Barcode barcode) {
    return BarcodesTableCompanion(
      id: Value(barcode.id),
      productUnitId: Value(barcode.productUnitId),
      barcode: Value(barcode.barcode),
      createdAt: barcode.createdAt != null
          ? Value(barcode.createdAt!)
          : const Value.absent(),
      updatedAt: Value(barcode.updatedAt ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为Barcode模型
  Barcode _dataToBarcode(BarcodesTableData data) {
    return Barcode(
      id: data.id,
      productUnitId: data.productUnitId,
      barcode: data.barcode,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}

/// Barcode Repository Provider
final barcodeRepositoryProvider = Provider<IBarcodeRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BarcodeRepository(database);
});
