import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/customers_table.dart';
import '../../../../core/database/sales_transactions_table.dart';
import '../../../../core/database/sales_transaction_items_table.dart';
import '../../../../core/database/product_units_table.dart';
import '../../../../core/database/purchase_order_items_table.dart';
import '../../domain/model/customer.dart' as domain;

part 'customer_dao.g.dart';

@DriftAccessor(tables: [
  Customers,
  SalesTransaction,
  SalesTransactionItem,
  UnitProduct,
  PurchaseOrderItem,
])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Future<List<Customer>> getAllCustomers() => select(customers).get();
  Future<Customer?> getCustomerById(int id) => (select(customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<int> addCustomer(domain.Customer customer) {
    return into(customers).insert(
      CustomersCompanion.insert(
        name: customer.name,
      ),
    );
  }

  Future<bool> updateCustomer(domain.Customer customer) {
    return update(customers).replace(
      Customer(id: customer.id!, name: customer.name),
    );
  }

  Future<int> deleteCustomer(int id) => (delete(customers)..where((tbl) => tbl.id.equals(id))).go();
  Future<bool> isCustomerNameExists(String name) async {
    final result = await (select(customers)..where((tbl) => tbl.name.equals(name))).get();
    return result.isNotEmpty;
  }

  /// 获取所有客户的利润贡献（一次性查询）
  /// 利润 = 销售价 - 采购成本（取最新采购单价）
  Future<Map<int, int>> getAllCustomerProfits() async {
    final result = await customSelect('''
      SELECT 
        c.id as customer_id,
        COALESCE(SUM(
          (sti.price_in_cents - COALESCE(
            (SELECT poi.unit_price_in_sis / 1000
             FROM purchase_order_item poi
             JOIN unit_product up ON poi.unit_product_id = up.id
             WHERE up.product_id = sti.product_id 
               AND up.unit_id = sti.unit_id
             ORDER BY poi.id DESC
             LIMIT 1
            ), 0)
          ) * sti.quantity
        ), 0) as total_profit
      FROM customers c
      LEFT JOIN sales_transaction st ON c.id = st.customer_id 
        AND st.status NOT IN ('cancelled', 'credit')
      LEFT JOIN sales_transaction_item sti ON st.id = sti.sales_transaction_id
      GROUP BY c.id
    ''').get();

    final Map<int, int> profits = {};
    for (final row in result) {
      final customerId = row.read<int>('customer_id');
      final profit = row.read<int>('total_profit');
      profits[customerId] = profit;
    }
    return profits;
  }

  /// 监听所有客户的利润贡献变化（Stream）
  /// 当 customers、sales_transaction 或 sales_transaction_item 表变化时自动更新
  Stream<Map<int, int>> watchAllCustomerProfits() {
    // 监听相关表的变化
    final tableUpdates = TableUpdateQuery.onAllTables([
      customers,
      salesTransaction,
      salesTransactionItem,
    ]);

    // 使用 rxdart 的 startWith 来立即发出初始值，然后监听表变化
    return db
        .tableUpdates(tableUpdates)
        .startWith(const {}) // 立即触发一次
        .asyncMap((_) => getAllCustomerProfits());
  }

  /// 获取单个客户的利润贡献
  Future<int> getCustomerProfit(int customerId) async {
    final result = await customSelect('''
      SELECT 
        COALESCE(SUM(
          (sti.price_in_cents - COALESCE(
            (SELECT poi.unit_price_in_sis / 1000
             FROM purchase_order_item poi
             JOIN unit_product up ON poi.unit_product_id = up.id
             WHERE up.product_id = sti.product_id 
               AND up.unit_id = sti.unit_id
             ORDER BY poi.id DESC
             LIMIT 1
            ), 0)
          ) * sti.quantity
        ), 0) as total_profit
      FROM sales_transaction st
      JOIN sales_transaction_item sti ON st.id = sti.sales_transaction_id
      WHERE st.customer_id = ?
        AND st.status NOT IN ('cancelled', 'credit')
    ''', variables: [Variable.withInt(customerId)]).getSingle();

    return result.read<int>('total_profit');
  }
}