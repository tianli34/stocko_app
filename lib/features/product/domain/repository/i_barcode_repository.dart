import '../model/barcode.dart';

/// 条码仓储接口
/// 定义条码相关的业务操作规范
abstract class IBarcodeRepository {
  /// 添加条码
  Future<int> addBarcode(BarcodeModel barcode);

  /// 批量添加条码
  Future<void> addMultipleBarcodes(List<BarcodeModel> barcodes);

  /// 根据ID获取条码
  Future<BarcodeModel?> getBarcodeById(int id);

  /// 根据条码值获取条码信息
  Future<BarcodeModel?> getBarcodeByValue(String barcode);

  /// 根据产品单位ID获取所有条码
  Future<List<BarcodeModel>> getBarcodesByProductUnitId(int? productUnitId);

  /// 获取所有条码
  Future<List<BarcodeModel>> getAllBarcodes();

  /// 监听产品单位的条码变化
  Stream<List<BarcodeModel>> watchBarcodesByProductUnitId(int productUnitId);

  /// 更新条码
  Future<bool> updateBarcode(BarcodeModel barcode);

  /// 删除条码
  Future<int> deleteBarcode(int id);

  /// 删除产品单位的所有条码
  Future<int> deleteBarcodesByProductUnitId(int productUnitId);

  /// 检查条码是否已存在
  Future<bool> barcodeExists(String barcode);

  /// 检查产品单位是否已有该条码
  Future<bool> productUnitHasBarcode(int productUnitId, String barcode);

  /// 更新或插入条码
  Future<void> upsertBarcode(BarcodeModel barcode);

  /// 批量更新或插入条码
  Future<void> upsertMultipleBarcodes(List<BarcodeModel> barcodes);
}
