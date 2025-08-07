import '../model/product_unit.dart';

/// 产品单位仓储接口
/// 定义产品单位关联相关的业务操作规范
abstract class IProductUnitRepository {
  /// 添加产品单位
  Future<int> addProductUnit(ProductUnit productUnit);

  /// 批量添加产品单位
  Future<void> addMultipleProductUnits(List<ProductUnit> productUnits);

  /// 根据产品单位ID获取产品单位
  Future<ProductUnit?> getProductUnitById(String productUnitId);
  /// 根据产品ID获取所有产品单位
  Future<List<ProductUnit>> getProductUnitsByProductId(int productId);

  /// 获取所有产品单位
  Future<List<ProductUnit>> getAllProductUnits();

  /// 监听产品的所有单位变化
  Stream<List<ProductUnit>> watchProductUnitsByProductId(int productId);

  /// 更新产品单位
  Future<bool> updateProductUnit(ProductUnit productUnit);

  /// 删除产品单位
  Future<int> deleteProductUnit(String productUnitId);

  /// 删除产品的所有单位
  Future<int> deleteProductUnitsByProductId(int productId);

  /// 检查产品是否已配置某个单位
  Future<bool> isUnitConfiguredForProduct(int productId, String unitId);

  /// 获取产品的基础单位
  Future<ProductUnit?> getBaseUnitForProduct(int productId);

  /// 更新或插入产品单位
  Future<void> upsertProductUnit(ProductUnit productUnit);

  /// 批量更新或插入产品单位
  Future<void> upsertMultipleProductUnits(List<ProductUnit> productUnits);

  /// 替换产品的所有单位配置
  /// 这会删除产品的现有单位配置，然后添加新的配置
  Future<void> replaceProductUnits(
    int productId,
    List<ProductUnit> productUnits,
  );
}
