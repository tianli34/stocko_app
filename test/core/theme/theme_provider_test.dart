import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    test('lightTheme basic color scheme', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      // AppBarTheme
      expect(theme.appBarTheme.toolbarHeight, 37);
      expect(theme.appBarTheme.elevation, 8);
      // InputDecorationTheme
      final input = theme.inputDecorationTheme;
      expect(input.isDense, true);
      expect(input.floatingLabelBehavior, FloatingLabelBehavior.never);
      expect(input.focusedBorder, isA<UnderlineInputBorder>());
    });

    test('darkTheme basic color scheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      // InputDecorationTheme
      final input = theme.inputDecorationTheme;
      expect(input.isDense, true);
      expect(input.floatingLabelBehavior, FloatingLabelBehavior.never);
      expect(input.focusedBorder, isA<UnderlineInputBorder>());
    });
  });
}
