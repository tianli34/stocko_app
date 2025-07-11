import '../model/product.dart';

/// 产品仓储抽象接口
/// 定义产品数据访问的核心方法
abstract class IProductRepository {
  /// 添加产品
  /// [product] 要添加的产品
  /// 返回添加成功的产品ID
  Future<int> addProduct(Product product);

  /// 更新产品
  /// [product] 要更新的产品
  /// 返回是否更新成功
  Future<bool> updateProduct(Product product);

  /// 删除产品
  /// [id] 产品ID
  /// 返回删除的记录数
  Future<int> deleteProduct(String id);

  /// 根据ID获取产品
  /// [id] 产品ID
  /// 返回产品对象，如果不存在则返回null
  Future<Product?> getProductById(String id);

  /// 监听所有产品变化
  /// 使用Stream实时监听产品列表的变化
  /// 返回产品列表的数据流
  Stream<List<Product>> watchAllProducts();

  /// 监听所有产品及其单位名称
  Stream<List<({Product product, String unitName})>> watchAllProductsWithUnit();

  /// 获取所有产品
  /// 返回当前所有产品的列表
  Future<List<Product>> getAllProducts();

  /// 根据条件查询产品
  /// [categoryId] 类别ID
  /// [status] 产品状态
  /// [keyword] 关键字
  /// 返回符合条件的产品列表
  Future<List<Product>> getProductsByCondition({
    String? categoryId,
    String? status,
    String? keyword,
  });

  /// 监听指定类别的产品
  /// [categoryId] 类别ID
  /// 返回指定类别产品的数据流
  Stream<List<Product>> watchProductsByCategory(String categoryId);

  /// 根据条码查询产品
  /// [barcode] 条码
  /// 返回匹配的产品，如果不存在则返回null
  Future<Product?> getProductByBarcode(String barcode);

  /// 根据条码获取产品及其单位信息
  /// [barcode] 条码
  /// 返回包含产品和单位名称的结果，如果不存在则返回null
  Future<({Product product, String unitName})?> getProductWithUnitByBarcode(
    String barcode,
  );
}
