import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/services/barcode_scanner_service.dart';
import 'package:stocko_app/core/widgets/universal_barcode_scanner.dart';

// A fake scanner widget that immediately calls onBarcodeScanned and pops.
class _FakeScanner extends StatelessWidget {
  final OnBarcodeScanned onBarcodeScanned;
  const _FakeScanner({required this.onBarcodeScanned});

  @override
  Widget build(BuildContext context) {
    // Defer to next frame to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onBarcodeScanned('ABC123');
    });
    return const Scaffold(body: SizedBox());
  }
}

void main() {
  testWidgets('quickScan returns scanned code', (tester) async {
    // Use scannerBuilder injection to avoid real camera widget
    final originalBuilder = BarcodeScannerService.scannerBuilder;
    addTearDown(() => BarcodeScannerService.scannerBuilder = originalBuilder);
    BarcodeScannerService.scannerBuilder = ({
      required BarcodeScannerConfig config,
      required OnBarcodeScanned onBarcodeScanned,
      Widget? loadingWidget,
      bool isLoading = false,
    }) => _FakeScanner(onBarcodeScanned: (code) {
          onBarcodeScanned(code);
        });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );

  final context = tester.element(find.byType(SizedBox));

  // Don't await immediately to avoid deadlock; let the frame lifecycle run.
  final future = BarcodeScannerService.quickScan(context, title: 'Test');

  // Pump frames so that:
  // 1) Navigator pushes the route
  // 2) Fake scanner's post-frame callback fires
  // 3) Navigator pops with result
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();

  final result = await future;
  expect(result, 'ABC123');
  });
}
