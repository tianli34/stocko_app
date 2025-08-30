import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/product/application/product_import_service.dart';
import 'package:drift/drift.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('ProductImportService', () {
    late ProductImportService service;
    late MockAppDatabase mockDb;

    setUp(() {
      mockDb = MockAppDatabase();
      service = ProductImportService(mockDb);
    });

    group('bulkInsertProducts', () {
      test('空数据返回错误信息', () async {
        // Act
        final result = await service.bulkInsertProducts([]);

        // Assert
        expect(result, equals('没有需要导入的数据。'));
      });

      test('文件中重复条码返回错误', () async {
        // Arrange
        final duplicateData = [
          {
            '货品名称': '产品1',
            '品牌': '品牌A',
            '包条码': '1234567890',
            '条条码': '0987654321',
            '建议零售价': '10.00',
            '批发价': '8.00',
          },
          {
            '货品名称': '产品2',
            '品牌': '品牌B',
            '包条码': '1234567890', // 重复条码
            '条条码': '1111111111',
            '建议零售价': '15.00',
            '批发价': '12.00',
          },
        ];

        // Act
        final result = await service.bulkInsertProducts(duplicateData);

        // Assert
        expect(result, contains('导入失败：文件中发现重复条码'));
        expect(result, contains('1234567890'));
      });
    });
  });
}