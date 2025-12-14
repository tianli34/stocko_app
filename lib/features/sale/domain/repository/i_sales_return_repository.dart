import '../model/sales_return.dart';
import '../model/sales_return_item.dart';

/// 销售退货仓库接口
abstract class ISalesReturnRepository {
  /// 创建退货单，返回生成的ID
  Future<int> addSalesReturn(SalesReturnModel salesReturn);

  /// 添加退货明细
  Future<int> addSalesReturnItem(SalesReturnItemModel item);

  /// 根据ID获取退货单
  Future<SalesReturnModel?> getSalesReturnById(int id);

  /// 根据原销售单ID获取退货单列表
  Future<List<SalesReturnModel>> getSalesReturnsByTransactionId(int transactionId);

  /// 获取店铺的所有退货单
  Future<List<SalesReturnModel>> getSalesReturnsByShopId(int shopId);

  /// 监听所有退货单
  Stream<List<SalesReturnModel>> watchAllSalesReturns();

  /// 更新退货单状态
  Future<bool> updateSalesReturnStatus(int id, SalesReturnStatus status);

  /// 获取原销售单已退货的商品数量
  Future<Map<int, int>> getReturnedQuantitiesByTransactionId(int transactionId);
}
