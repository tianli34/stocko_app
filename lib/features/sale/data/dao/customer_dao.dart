import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/customers_table.dart';
import '../../domain/model/customer.dart' as domain;

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers])
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
}