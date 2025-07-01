import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/product/presentation/screens/add_auxiliary_unit_screen.dart';
import 'package:stocko_app/features/product/presentation/screens/product_add_edit_screen.dart';
import 'package:stocko_app/features/product/presentation/screens/product_list_screen.dart';
import 'package:stocko_app/features/product/application/provider/unit_edit_form_providers.dart';

void main() {
  testWidgets(
    'Auxiliary unit data is cleared after navigating back and re-entering UnitEditScreen',
    (WidgetTester tester) async {
      // 使用一个独立的 ProviderContainer 来跟踪 Provider 状态
      final container = ProviderContainer();
      final navKey = GlobalKey<NavigatorState>();

      // 构建测试应用
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navKey,
            initialRoute: '/',
            routes: {
              '/': (context) => const ProductListScreen(),
              '/add': (context) => const ProductAddEditScreen(),
              '/unit': (context) => const UnitEditScreen(),
            },
          ),
        ),
      );

      // 1. 从产品列表页进入添加产品页
      navKey.currentState!.pushNamed('/add');
      await tester.pumpAndSettle();

      // 2. 从添加产品页进入单位编辑页
      navKey.currentState!.pushNamed('/unit');
      await tester.pumpAndSettle(); // 3. 模拟在单位编辑页添加辅单位数据
      // 首先监听provider以防止其被AutoDispose
      final notifier = container.read(unitEditFormProvider.notifier);
      final subscription = container.listen(
        unitEditFormProvider,
        (previous, next) {},
      );

      try {
        notifier.addAuxiliaryUnit();
        expect(container.read(unitEditFormProvider).auxiliaryUnits, isNotEmpty);

        // 4. 返回添加产品页
        navKey.currentState!.pop();
        await tester.pumpAndSettle();
        // 此时数据仍然保留
        expect(
          container.read(unitEditFormProvider).auxiliaryUnits,
          isNotEmpty,
        ); // 5. 返回产品列表页
        navKey.currentState!.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 添加产品页 dispose 时会清除持久化的辅单位数据
        container.refresh(unitEditFormProvider);
        expect(container.read(unitEditFormProvider).auxiliaryUnits, isEmpty);

        // 6. 再次进入单位编辑页
        navKey.currentState!.pushNamed('/add');
        await tester.pumpAndSettle();
        navKey.currentState!.pushNamed('/unit');
        await tester.pumpAndSettle();

        // 验证之前的数据已被清除
        expect(container.read(unitEditFormProvider).auxiliaryUnits, isEmpty);
      } finally {
        subscription.close();
      }
    },
  );
}
