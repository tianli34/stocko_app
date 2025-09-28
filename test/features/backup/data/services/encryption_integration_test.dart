import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/services/encryption_service.dart';

void main() {
  group('EncryptionService Integration Tests', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('should encrypt and decrypt JSON backup data', () async {
      // Arrange - Simulate backup data structure
      final backupData = {
        'metadata': {
          'id': 'backup_20241227_143022',
          'version': '1.0.0',
          'createdAt': '2024-12-27T14:30:22.000Z',
          'tableCounts': {
            'products': 150,
            'categories': 12,
            'stock': 300,
          }
        },
        'data': {
          'products': [
            {
              'id': 1,
              'name': '测试产品',
              'barcode': '1234567890123',
              'price': 29.99,
              'category_id': 1,
            },
            {
              'id': 2,
              'name': 'Test Product 2',
              'barcode': '9876543210987',
              'price': 15.50,
              'category_id': 2,
            }
          ],
          'categories': [
            {'id': 1, 'name': '电子产品'},
            {'id': 2, 'name': 'Books & Media'},
          ],
          'stock': [
            {'product_id': 1, 'quantity': 100, 'location': 'A1'},
            {'product_id': 2, 'quantity': 50, 'location': 'B2'},
          ]
        }
      };

      final jsonData = jsonEncode(backupData);
      const password = 'secure_backup_password_2024!';

      // Act
      final encrypted = await encryptionService.encryptData(jsonData, password);
      final decrypted = await encryptionService.decryptData(encrypted, password);
      final restoredData = jsonDecode(decrypted);

      // Assert
      expect(restoredData, equals(backupData));
      expect(restoredData['metadata']['id'], equals('backup_20241227_143022'));
      expect(restoredData['data']['products'].length, equals(2));
      expect(restoredData['data']['products'][0]['name'], equals('测试产品'));
      expect(restoredData['data']['categories'][0]['name'], equals('电子产品'));
    });

    test('should handle large backup data with many records', () async {
      // Arrange - Generate large dataset
      final products = List.generate(1000, (index) => {
        'id': index + 1,
        'name': 'Product ${index + 1}',
        'barcode': '${1000000000000 + index}',
        'price': (index + 1) * 1.99,
        'category_id': (index % 10) + 1,
        'description': 'This is a test product with ID ${index + 1} and some additional text to make it larger.',
      });

      final categories = List.generate(10, (index) => {
        'id': index + 1,
        'name': 'Category ${index + 1}',
        'description': 'Description for category ${index + 1}',
      });

      final stock = List.generate(1000, (index) => {
        'product_id': index + 1,
        'quantity': (index + 1) * 10,
        'location': 'LOC-${String.fromCharCode(65 + (index % 26))}${(index % 100) + 1}',
        'last_updated': '2024-12-27T${(index % 24).toString().padLeft(2, '0')}:${(index % 60).toString().padLeft(2, '0')}:00.000Z',
      });

      final backupData = {
        'metadata': {
          'id': 'large_backup_test',
          'version': '1.0.0',
          'createdAt': '2024-12-27T14:30:22.000Z',
          'tableCounts': {
            'products': products.length,
            'categories': categories.length,
            'stock': stock.length,
          }
        },
        'data': {
          'products': products,
          'categories': categories,
          'stock': stock,
        }
      };

      final jsonData = jsonEncode(backupData);
      const password = 'large_data_test_password';

      // Act
      final stopwatch = Stopwatch()..start();
      final encrypted = await encryptionService.encryptData(jsonData, password);
      final encryptionTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.reset();
      final decrypted = await encryptionService.decryptData(encrypted, password);
      final decryptionTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      final restoredData = jsonDecode(decrypted);

      // Assert
      expect(restoredData['data']['products'].length, equals(1000));
      expect(restoredData['data']['categories'].length, equals(10));
      expect(restoredData['data']['stock'].length, equals(1000));
      expect(restoredData['data']['products'][999]['name'], equals('Product 1000'));
      
      // Performance assertions (should complete within reasonable time)
      expect(encryptionTime, lessThan(10000)); // Less than 10 seconds
      expect(decryptionTime, lessThan(10000)); // Less than 10 seconds
      
      print('Encryption time: ${encryptionTime}ms');
      print('Decryption time: ${decryptionTime}ms');
      print('Original size: ${jsonData.length} bytes');
      print('Encrypted size: ${encrypted.length} bytes');
    });

    test('should maintain data integrity with HMAC verification', () async {
      // Arrange
      final sensitiveData = {
        'customers': [
          {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'phone': '+1234567890',
            'address': '123 Main St, City, State 12345'
          },
          {
            'id': 2,
            'name': '张三',
            'email': 'zhang@example.com',
            'phone': '+8613800138000',
            'address': '北京市朝阳区某某街道123号'
          }
        ],
        'sales_transactions': [
          {
            'id': 1,
            'customer_id': 1,
            'total_amount': 299.99,
            'payment_method': 'credit_card',
            'transaction_date': '2024-12-27T10:30:00.000Z'
          }
        ]
      };

      final jsonData = jsonEncode(sensitiveData);
      const password = 'sensitive_data_password';
      const hmacKey = 'integrity_verification_key';

      // Act
      final encrypted = await encryptionService.encryptData(jsonData, password);
      final hmac = encryptionService.generateHmac(encrypted, hmacKey);
      
      // Simulate storage and retrieval
      final retrievedEncrypted = encrypted;
      final retrievedHmac = hmac;
      
      // Verify integrity
      final isIntegrityValid = encryptionService.verifyHmac(retrievedEncrypted, hmacKey, retrievedHmac);
      final decrypted = await encryptionService.decryptData(retrievedEncrypted, password);
      final restoredData = jsonDecode(decrypted);

      // Assert
      expect(isIntegrityValid, isTrue);
      expect(restoredData['customers'].length, equals(2));
      expect(restoredData['customers'][0]['name'], equals('John Doe'));
      expect(restoredData['customers'][1]['name'], equals('张三'));
      expect(restoredData['sales_transactions'][0]['total_amount'], equals(299.99));
    });

    test('should detect data tampering with HMAC verification', () async {
      // Arrange
      const testData = '{"important": "data", "value": 12345}';
      const password = 'test_password';
      const hmacKey = 'integrity_key';

      // Act
      final encrypted = await encryptionService.encryptData(testData, password);
      final originalHmac = encryptionService.generateHmac(encrypted, hmacKey);
      
      // Simulate data tampering
      final tamperedEncrypted = '${encrypted.substring(0, encrypted.length - 10)}tampered123';
      final isTamperedValid = encryptionService.verifyHmac(tamperedEncrypted, hmacKey, originalHmac);

      // Assert
      expect(isTamperedValid, isFalse);
    });

    test('should work with different password strengths', () async {
      // Arrange
      const testData = '{"test": "data"}';
      final passwords = [
        '123',                                    // Weak
        'password123',                           // Medium
        'StrongP@ssw0rd!2024',                  // Strong
        encryptionService.generateSecurePassword(64), // Very strong
      ];

      // Act & Assert
      for (final password in passwords) {
        final encrypted = await encryptionService.encryptData(testData, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);
        
        expect(decrypted, equals(testData));
        
        // Verify wrong password fails
        final wrongPassword = '${password}_wrong';
        expect(
          () => encryptionService.decryptData(encrypted, wrongPassword),
          throwsA(isA<EncryptionException>()),
        );
      }
    });

    test('should handle concurrent encryption operations', () async {
      // Arrange
      const testData = '{"concurrent": "test", "id": ';
      const password = 'concurrent_test_password';
      
      // Act - Perform multiple concurrent encryptions
      final futures = List.generate(10, (index) async {
        final data = '$testData$index}';
        final encrypted = await encryptionService.encryptData(data, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);
        return {'original': data, 'decrypted': decrypted};
      });
      
      final results = await Future.wait(futures);
      
      // Assert
      for (final result in results) {
        expect(result['decrypted'], equals(result['original']));
      }
    });
  });
}