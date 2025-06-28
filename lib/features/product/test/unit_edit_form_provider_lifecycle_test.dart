import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/application/provider/unit_edit_form_providers.dart';
// import 'package:stocko_app/features/product/domain/model/auxiliary_unit_data.dart';

//========== Mock Widgets for Navigation Simulation ==========

/// 模拟的产品列表页 (导航起点)
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Product Edit'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProductEditScreen())),
        ),
      ),
    );
  }
}

/// 模拟的产品编辑页
/// 它是一个 StatefulWidget，会在 dispose 时销毁 unitEditFormProvider 的状态
class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      ref.invalidate(unitEditFormProvider);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Edit')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Unit Edit'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UnitEditScreen())),
        ),
      ),
    );
  }
}

/// 模拟的单位编辑页
/// 它会读取并修改 unitEditFormProvider 的状态
class UnitEditScreen extends ConsumerWidget {
  const UnitEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 Provider 的状态
    final auxiliaryUnits = ref.watch(unitEditFormProvider).auxiliaryUnits;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Edit')),
      body: Column(
        children: [
          // 显示当前辅助单位的数量，用于测试断言
          Text('Auxiliary Units: ${auxiliaryUnits.length}'),
          // 添加一个按钮来修改状态
          ElevatedButton(
            child: const Text('Add Auxiliary Unit'),
            onPressed: () {
              ref.read(unitEditFormProvider.notifier).addAuxiliaryUnit();
            },
          ),
        ],
      ),
    );
  }
}

//========== Tests ==========

void main() {
  testWidgets('Test Case 1: Data is CLEARED after returning to product list', (
    WidgetTester tester,
  ) async {
    // 1. 启动应用，显示产品列表页
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProductListPage())),
    );

    // 2. 进入产品编辑页
    await tester.tap(find.text('Go to Product Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Product Edit'), findsOneWidget);

    // 3. 进入单位编辑页
    await tester.tap(find.text('Go to Unit Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Unit Edit'), findsOneWidget);

    // 4. 确认初始数据为0
    expect(find.text('Auxiliary Units: 0'), findsOneWidget);

    // 5. 添加一个辅助单位，并确认状态已更新
    await tester.tap(find.text('Add Auxiliary Unit'));
    await tester.pump();
    expect(find.text('Auxiliary Units: 1'), findsOneWidget);

    // 6. 返回到产品编辑页
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Product Edit'), findsOneWidget);

    // 7. 关键：再返回到产品列表页。这将导致 ProductEditScreen 被 dispose
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Go to Product Edit'), findsOneWidget); // 确认回到了列表页

    // 8. 再次重复导航流程：列表页 -> 产品编辑页 -> 单位编辑页
    await tester.tap(find.text('Go to Product Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Unit Edit'));
    await tester.pumpAndSettle();

    // 9. 断言：数据已被清除，辅助单位数量应重置为0
    expect(find.text('Auxiliary Units: 0'), findsOneWidget);
  });

  testWidgets(
    'Test Case 2: Data is RETAINED when moving between unit and product edit pages',
    (WidgetTester tester) async {
      // 1. 启动应用，直接导航到产品编辑页
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProductEditScreen(), // 直接从这里开始
          ),
        ),
      );

      // 2. 进入单位编辑页
      await tester.tap(find.text('Go to Unit Edit'));
      await tester.pumpAndSettle();

      // 3. 确认初始数据为0
      expect(find.text('Auxiliary Units: 0'), findsOneWidget);

      // 4. 添加一个辅助单位，并确认状态已更新
      await tester.tap(find.text('Add Auxiliary Unit'));
      await tester.pump();
      expect(find.text('Auxiliary Units: 1'), findsOneWidget);

      // 5. 返回到产品编辑页。此时 ProductEditScreen 并没有被 dispose
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Product Edit'), findsOneWidget);

      // 6. 再次进入单位编辑页
      await tester.tap(find.text('Go to Unit Edit'));
      await tester.pumpAndSettle();

      // 7. 断言：数据被保留，辅助单位数量仍然是1
      expect(find.text('Auxiliary Units: 1'), findsOneWidget);
    },
  );
}
