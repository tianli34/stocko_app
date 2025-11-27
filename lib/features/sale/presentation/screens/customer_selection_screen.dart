import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../application/provider/customer_providers.dart';
import '../../domain/model/customer.dart';
import '../../../../core/shared_widgets/loading_widget.dart';
import '../../../../core/shared_widgets/error_widget.dart';
import '../../../../core/utils/snackbar_helper.dart';

class CustomerSelectionScreen extends ConsumerStatefulWidget {
  final int? selectedCustomerId;

  const CustomerSelectionScreen({
    super.key,
    this.selectedCustomerId,
  });

  @override
  ConsumerState<CustomerSelectionScreen> createState() =>
      _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends ConsumerState<CustomerSelectionScreen> {
  int? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.selectedCustomerId;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsyncValue = ref.watch(allCustomersProvider);
    final controllerState = ref.watch(customerControllerProvider);

    ref.listen<AsyncValue<void>>(customerControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        showAppSnackBar(context, message: '操作成功');
      } else if (next.hasError) {
        showAppSnackBar(context,
            message: next.error.toString(), isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('客户管理'),
        actions: [
          IconButton(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.add),
            tooltip: '新增客户',
          ),
        ],
      ),
      body: Column(
        children: [
          if (controllerState.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: customersAsyncValue.when(
              data: (customers) => _buildCustomerList(context, customers),
              loading: () => const LoadingWidget(message: '加载客户列表中...'),
              error: (error, stackTrace) => CustomErrorWidget(
                message: '加载客户列表失败',
                onRetry: () => ref.invalidate(allCustomersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无客户', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              '点击右上角的 + 号添加新客户',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allCustomersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _buildCustomerTile(context, customer);
        },
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    final isSelected = _selectedCustomerId == customer.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Slidable(
        key: ValueKey(customer.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            Expanded(
              child: CustomSlidableAction(
                onPressed: (context) {
                  if (customer.id != null) {
                    ref
                        .read(customerControllerProvider.notifier)
                        .deleteCustomer(customer.id!.toString());
                  }
                },
                backgroundColor: Colors.red,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          child: ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            title: Text(
              customer.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增客户'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '客户名称',
              hintText: '请输入客户名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入客户名称';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final customerName = nameController.text.trim();

                final controller =
                    ref.read(customerControllerProvider.notifier);
                final exists = await controller.isCustomerNameExists(customerName);

                if (exists) {
                  showAppSnackBar(context,
                      message: '客户名称已存在', isError: true);
                  return;
                }

                final customer = Customer(
                  name: customerName,
                );

                await controller.addCustomer(customer);

                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedCustomerId != null) {
      final customers = ref.read(allCustomersProvider).value ?? [];
      final selectedCustomer = customers.firstWhere(
        (customer) => customer.id == _selectedCustomerId,
        orElse: () => throw Exception('选中的客户不存在'),
      );

      Navigator.of(context).pop(selectedCustomer);
    }
  }
}