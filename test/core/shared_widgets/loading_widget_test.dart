import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/shared_widgets/loading_widget.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('renders CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not render message when showMessage is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(
              message: 'Loading...',
              showMessage: false,
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsNothing);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows overlay when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            child: Container(),
          ),
        ),
      );

      expect(find.byType(LoadingWidget), findsOneWidget);
    });

    testWidgets('does not show overlay when isLoading is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            isLoading: false,
            child: Container(),
          ),
        ),
      );

      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets('shows custom loading message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            loadingMessage: 'Please wait...',
            child: Container(),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsOneWidget);
    });
  });
}