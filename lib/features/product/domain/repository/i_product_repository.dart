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

  /// 获取所有产品
  /// 返回当前所有产品的列表
  Future<List<Product>> getAllProducts();
}
