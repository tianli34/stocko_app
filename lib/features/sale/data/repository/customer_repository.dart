import '../../domain/model/customer.dart' as domain;
import '../../domain/repository/i_customer_repository.dart';
import '../dao/customer_dao.dart';
import '../../../../core/database/database.dart';

class CustomerRepository implements ICustomerRepository {
  final CustomerDao _customerDao;

  CustomerRepository(this._customerDao);

  @override
  Future<void> addCustomer(domain.Customer customer) {
    return _customerDao.addCustomer(customer);
  }

  @override
  Future<void> deleteCustomer(String id) {
    return _customerDao.deleteCustomer(int.parse(id));
  }

  @override
  Future<List<domain.Customer>> getAllCustomers() async {
    final customers = await _customerDao.getAllCustomers();
    return customers.map((c) => c.toDomain()).toList();
  }

  @override
  Future<domain.Customer?> getCustomerById(String id) async {
    final customer = await _customerDao.getCustomerById(int.parse(id));
    return customer?.toDomain();
  }

  @override
  Future<void> updateCustomer(domain.Customer customer) {
    return _customerDao.updateCustomer(customer);
  }

  @override
  Future<bool> isCustomerNameExists(String name) {
    return _customerDao.isCustomerNameExists(name);
  }
}

extension on Customer {
  domain.Customer toDomain() {
    return domain.Customer(
      id: id,
      name: name,
    );
  }
}