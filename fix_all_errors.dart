import 'dart:io';

void main() async {
  // Fix test files by adding totalValue parameter
  final filesToFix = [
    'test/features/inventory/presentation/widgets/simple_inventory_card_test.dart',
    'test/features/inventory/presentation/widgets/aggregated_inventory_card_test.dart',
    'test/features/inventory/presentation/screens/inventory_query_screen_test.dart',
    'test/features/inventory/presentation/providers/inventory_query_providers_test.dart',
  ];

  for (final filePath in filesToFix) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('File not found: $filePath');
      continue;
    }

    var content = await file.readAsString();
    
    // Add totalValue: 0.0, after categoryName parameter
    content = content.replaceAllMapped(
      RegExp(r"(categoryName:\s*'[^']*',)\s*\n(\s*)(details:)", multiLine: true),
      (match) => '${match.group(1)}\n${match.group(2)}totalValue: 0.0,\n${match.group(2)}${match.group(3)}',
    );

    await file.writeAsString(content);
    print('Fixed: $filePath');
  }

  print('All files fixed!');
}
