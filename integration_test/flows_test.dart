import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:stocko_app/app.dart';
import 'package:stocko_app/core/initialization/app_initializer.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/core/database/database_providers.dart';

void main() {
  Future<void> _pumpApp(WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          databaseInitializationProvider.overrideWith((ref) async {}),
        ],
        child: const AppInitializer(child: StockoApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('收银台页面可以打开并显示标题', (tester) async {
    await _pumpApp(tester);

    // 点击首页“收银台”按钮
    final cashierButton = find.text('收银台');
    expect(cashierButton, findsOneWidget);
    await tester.tap(cashierButton);
    await tester.pumpAndSettle();

    // 断言收银台标题
    expect(find.text('收银台'), findsWidgets);
  });

  testWidgets('新建入库单页面可以打开并显示标题', (tester) async {
    await _pumpApp(tester);

    // 点击首页“新建入库单”
    final inboundButton = find.text('新建入库单');
    expect(inboundButton, findsOneWidget);
    await tester.tap(inboundButton);
    await tester.pumpAndSettle();

    // 断言入库标题（采购入库/非采购入库之一）
    expect(find.text('采购入库'), findsOneWidget);
  });
}
