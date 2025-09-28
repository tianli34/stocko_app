import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/router/router_provider.dart';
import 'package:stocko_app/config/flavor_config.dart';

void main() {
  testWidgets('routerProvider can be created and initial route builds', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    final container = ProviderContainer(
      overrides: [
        flavorConfigProvider.overrideWithValue(
          FlavorConfig(
            flavor: AppFlavor.generic,
            appTitle: 'Test App',
            featureFlags: {},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(ProviderScope(
      parent: container,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ));

    // 首屏构建不抛异常即可
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.byType(Scaffold), findsWidgets);
  });
}
