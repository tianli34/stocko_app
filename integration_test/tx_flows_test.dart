import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

import 'package:stocko_app/app.dart';
import 'package:stocko_app/core/initialization/app_initializer.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/core/database/database_providers.dart';

/// 在给定超时时间内轮询等待直到 [finder] 出现在树中。
Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      // 再次结算所有过渡动画，确保页面稳定
      await tester.pumpAndSettle();
      return;
    }
  }
  throw TestFailure('等待页面元素超时: $finder');
}

Future<void> _seedBasicData(AppDatabase db) async {
  // 开启外键约束
  await db.customStatement('PRAGMA foreign_keys = ON');

  // 默认客户（匿名散客，id=0）——用于销售单外键引用
  await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: const Value(0),
          name: '匿名散客',
        ),
      );

  // Unit
  final unitId = await db.into(db.unit).insert(
        UnitCompanion.insert(name: '件'),
      );

  // Shop (默认选择使用的名称)
  await db.into(db.shop).insert(
        ShopCompanion.insert(name: '长山的店', manager: '老板'),
      );

  // Product
  final productId = await db.into(db.product).insert(
        ProductCompanion.insert(
          name: '测试商品',
          baseUnitId: unitId,
          retailPrice: const Value(Money(1500)), // ¥15.00
        ),
      );

  // UnitProduct (conversionRate=1 且配置批发价供入库使用)
  await db.into(db.unitProduct).insert(
        UnitProductCompanion.insert(
          productId: productId,
          unitId: unitId,
          conversionRate: 1,
          wholesalePriceInCents: const Value(900), // ¥9.00
          sellingPriceInCents: const Value(1500),
        ),
      );
}

Future<void> _selectShopIfNeeded(WidgetTester tester) async {
  final shopDropdown = find.byKey(const Key('shop_dropdown'));
  if (shopDropdown.evaluate().isEmpty) return;
  // 若尚未选中，手动展开并选择
  await tester.tap(shopDropdown);
  await tester.pumpAndSettle();
  final shopItem = find.text('长山的店').last;
  if (shopItem.evaluate().isNotEmpty) {
    await tester.tap(shopItem);
    await tester.pumpAndSettle();
  }
}

Future<void> _addOneProductViaPicker(WidgetTester tester) async {
  // 打开商品选择器
  await tester.tap(find.text('添加货品'));
  await tester.pumpAndSettle();

  // 全选 -> 确定（确保至少一个商品被返回）
  await tester.tap(find.text('全选'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('确定'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完成一次销售（收银台 -> 结账 -> 销售记录）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seedBasicData(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          databaseInitializationProvider.overrideWith((ref) async {}),
        ],
        child: const AppInitializer(child: StockoApp()),
      ),
    );
    await tester.pumpAndSettle();

    // 进入收银台
    await tester.tap(find.text('收银台'));
    await tester.pumpAndSettle();

    // 选择店铺（如未自动选中）
    await _selectShopIfNeeded(tester);

    // 添加一个商品
    await _addOneProductViaPicker(tester);

    // 点击结账
    await tester.tap(find.text('结账'));
  // 等待跳转到“销售记录”完成
  await _waitForFinder(tester, find.text('销售记录'));
  expect(find.text('销售记录'), findsOneWidget);
  });

  testWidgets('完成一次入库（切换非采购 -> 添加货品 -> 一键入库 -> 入库记录）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seedBasicData(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          databaseInitializationProvider.overrideWith((ref) async {}),
        ],
        child: const AppInitializer(child: StockoApp()),
      ),
    );
    await tester.pumpAndSettle();

    // 进入新建入库单
    await tester.tap(find.text('新建入库单'));
    await tester.pumpAndSettle();

    // 切换为非采购模式，避免必须输入供应商和单价校验
    final switchMode = find.byTooltip('切换模式');
    if (switchMode.evaluate().isNotEmpty) {
      await tester.tap(switchMode);
      await tester.pumpAndSettle();
    }

    // 选择店铺（如未自动选中）
    await _selectShopIfNeeded(tester);

    // 添加一个商品
    await _addOneProductViaPicker(tester);

    // 一键入库
    await tester.tap(find.text('一键入库'));
  // 等待跳转到“入库记录”页面完成
  await _waitForFinder(tester, find.text('入库记录'));
  expect(find.text('入库记录'), findsOneWidget);
  });
}
