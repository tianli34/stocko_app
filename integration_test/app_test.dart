import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stocko_app/app.dart';
import 'package:stocko_app/core/initialization/app_initializer.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:stocko_app/core/database/database_providers.dart';

void main() {
  // Enable integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('应用可以启动并显示首页标题', (WidgetTester tester) async {
    // Build app with provider overrides to avoid real DB IO
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

    // Let frames settle
    await tester.pumpAndSettle();

    // Assert the home app bar/title exists
    expect(find.text('铺得清 - 首页'), findsOneWidget);
    expect(find.text('欢迎使用 铺得清 库存管理系统'), findsOneWidget);
  });
}
