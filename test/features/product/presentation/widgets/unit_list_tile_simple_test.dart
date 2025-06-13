import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/application/provider/unit_providers.dart';
import 'package:stocko_app/features/product/presentation/widgets/unit_list_tile.dart';

// Mock classes
class MockUnitController extends StateNotifier<UnitControllerState>
    with Mock
    implements UnitController {
  MockUnitController() : super(const UnitControllerState());
}

void main() {
  group('UnitListTile Simple Tests', () {
    late Unit testUnit;
    late MockUnitController mockController;
    setUp(() {
      mockController = MockUnitController();
      testUnit = Unit(id: 'unit_test_123', name: '测试单位');
    });
    Widget createTestWidget({Unit? unit}) {
      return ProviderScope(
        overrides: [
          unitControllerProvider.overrideWith((ref) {
            return mockController;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UnitListTile(
              unit: unit ?? testUnit,
              showActions: false, // 简化测试，不显示操作按钮
            ),
          ),
        ),
      );
    }

    testWidgets('应该正确显示单位基本信息', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 验证单位名称
      expect(find.text('测试单位'), findsOneWidget);

      // 验证单位ID
      expect(find.textContaining('ID: unit_test_123'), findsOneWidget);

      // 验证单位图标
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });
  });
}
