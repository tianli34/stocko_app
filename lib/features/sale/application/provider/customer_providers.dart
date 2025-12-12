import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart' hide Customer;
import '../../../../core/services/data_refresh_service.dart';
import '../../data/dao/customer_dao.dart';
import '../../data/repository/customer_repository.dart';
import '../../domain/model/customer.dart';
import '../../domain/repository/i_customer_repository.dart';

final customerDaoProvider = Provider<CustomerDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CustomerDao(db);
});

final customerRepositoryProvider = Provider<ICustomerRepository>((ref) {
  final customerDao = ref.watch(customerDaoProvider);
  return CustomerRepository(customerDao);
});

final allCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  // 监听数据刷新触发器
  ref.watch(dataRefreshTriggerProvider);
  
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getAllCustomers();
});

/// 监听所有客户的利润贡献变化 Map<customerId, profitInCents>
/// 当销售交易或交易明细变化时自动更新
final allCustomerProfitsProvider = StreamProvider<Map<int, int>>((ref) {
  // 监听数据刷新触发器
  ref.watch(dataRefreshTriggerProvider);
  
  final dao = ref.watch(customerDaoProvider);
  return dao.watchAllCustomerProfits();
});

final customerControllerProvider =
    StateNotifierProvider<CustomerController, AsyncValue<void>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerController(repository, ref);
});

class CustomerController extends StateNotifier<AsyncValue<void>> {
  final ICustomerRepository _repository;
  final Ref _ref;

  CustomerController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> addCustomer(Customer customer) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addCustomer(customer);
      _ref.invalidate(allCustomersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCustomer(customer);
      _ref.invalidate(allCustomersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCustomer(id);
      _ref.invalidate(allCustomersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> isCustomerNameExists(String name) async {
    return _repository.isCustomerNameExists(name);
  }
}