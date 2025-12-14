import '../model/stocktake_order.dart';
import '../model/stocktake_status.dart';

/// 盘点单仓库接口
abstract class IStocktakeOrderRepository {
  /// 创建盘点单
  Future<int> createOrder(StocktakeOrderModel order);

  /// 更新盘点单
  Future<bool> updateOrder(StocktakeOrderModel order);

  /// 删除盘点单
  Future<bool> deleteOrder(int id);

  /// 根据ID获取盘点单
  Future<StocktakeOrderModel?> getOrderById(int id);

  /// 根据单号获取盘点单
  Future<StocktakeOrderModel?> getOrderByNumber(String orderNumber);

  /// 获取店铺的盘点单列表
  Future<List<StocktakeOrderModel>> getOrdersByShop(int shopId);

  /// 获取所有盘点单
  Future<List<StocktakeOrderModel>> getAllOrders();

  /// 根据状态获取盘点单
  Future<List<StocktakeOrderModel>> getOrdersByStatus(StocktakeStatus status);

  /// 更新盘点单状态
  Future<bool> updateStatus(int id, StocktakeStatus status);

  /// 监听盘点单列表
  Stream<List<StocktakeOrderModel>> watchAllOrders();

  /// 监听店铺的盘点单列表
  Stream<List<StocktakeOrderModel>> watchOrdersByShop(int shopId);
}
