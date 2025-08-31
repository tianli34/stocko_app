import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/utils/snackbar_helper.dart';

void main() {
  testWidgets('showAppSnackBar shows success snackbar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    showAppSnackBar(context, message: 'Hello');

    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.green);
  });

  testWidgets('showAppSnackBar shows error snackbar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    showAppSnackBar(context, message: 'Oops', isError: true);
    await tester.pump();
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.redAccent);
  });
}
