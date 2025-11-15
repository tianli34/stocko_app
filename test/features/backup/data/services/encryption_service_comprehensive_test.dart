import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/services/encryption_service.dart';
import 'package:stocko_app/features/backup/domain/services/i_encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late IEncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    group('Instance Creation', () {
      test('should create encryption service instance', () {
        expect(encryptionService, isA<EncryptionService>());
        expect(encryptionService, isA<IEncryptionService>());
      });
    });

    group('Data Encryption and Decryption', () {
      test('should encrypt and decrypt data successfully', () async {
        // Arrange
        const originalData = 'This is test data for encryption';
        const password = 'test_password_123';

        // Act
        final encryptedData = await encryptionService.encryptData(originalData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(encryptedData, isNotEmpty);
        expect(encryptedData, isNot(equals(originalData)));
        expect(decryptedData, equals(originalData));
      });

      test('should encrypt same data differently each time', () async {
        // Arrange
        const originalData = 'Same data for multiple encryptions';
        const password = 'same_password';

        // Act
        final encrypted1 = await encryptionService.encryptData(originalData, password);
        final encrypted2 = await encryptionService.encryptData(originalData, password);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2)));
        
        // But both should decrypt to the same original data
        final decrypted1 = await encryptionService.decryptData(encrypted1, password);
        final decrypted2 = await encryptionService.decryptData(encrypted2, password);
        expect(decrypted1, equals(originalData));
        expect(decrypted2, equals(originalData));
      });

      test('should handle empty data encryption', () async {
        // Arrange
        const emptyData = '';
        const password = 'password_for_empty';

        // Act
        final encryptedData = await encryptionService.encryptData(emptyData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(encryptedData, isNotEmpty);
        expect(decryptedData, equals(emptyData));
      });

      test('should handle large data encryption', () async {
        // Arrange
        final largeData = 'A' * 10000; // 10KB of data
        const password = 'password_for_large_data';

        // Act
        final encryptedData = await encryptionService.encryptData(largeData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(encryptedData, isNotEmpty);
        expect(decryptedData, equals(largeData));
        expect(decryptedData.length, equals(10000));
      });

      test('should handle special characters in data', () async {
        // Arrange
        const specialData = '特殊字符测试 🚀 @#\$%^&*()_+ 中文测试 العربية русский';
        const password = 'password_special_chars';

        // Act
        final encryptedData = await encryptionService.encryptData(specialData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(decryptedData, equals(specialData));
      });

      test('should handle JSON data encryption', () async {
        // Arrange
        final jsonData = jsonEncode({
          'name': 'Test Product',
          'price': 99.99,
          'categories': ['electronics', 'gadgets'],
          'metadata': {
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-02T00:00:00Z',
          },
        });
        const password = 'json_encryption_password';

        // Act
        final encryptedData = await encryptionService.encryptData(jsonData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(decryptedData, equals(jsonData));
        
        // Verify JSON can be parsed
        final parsedJson = jsonDecode(decryptedData);
        expect(parsedJson['name'], equals('Test Product'));
        expect(parsedJson['price'], equals(99.99));
      });
    });

    group('Password Validation', () {
      test('should validate correct password', () async {
        // Arrange
        const originalData = 'Data for password validation';
        const correctPassword = 'correct_password';

        final encryptedData = await encryptionService.encryptData(originalData, correctPassword);

        // Act
        final isValid = await encryptionService.validatePassword(encryptedData, correctPassword);

        // Assert
        expect(isValid, isTrue);
      });

      test('should reject incorrect password', () async {
        // Arrange
        const originalData = 'Data for password validation';
        const correctPassword = 'correct_password';
        const wrongPassword = 'wrong_password';

        final encryptedData = await encryptionService.encryptData(originalData, correctPassword);

        // Act
        final isValid = await encryptionService.validatePassword(encryptedData, wrongPassword);

        // Assert
        expect(isValid, isFalse);
      });

      test('should handle empty password validation', () async {
        // Arrange
        const originalData = 'Data with empty password';
        const emptyPassword = '';

        final encryptedData = await encryptionService.encryptData(originalData, emptyPassword);

        // Act
        final isValidCorrect = await encryptionService.validatePassword(encryptedData, emptyPassword);
        final isValidWrong = await encryptionService.validatePassword(encryptedData, 'not_empty');

        // Assert
        expect(isValidCorrect, isTrue);
        expect(isValidWrong, isFalse);
      });
    });

    group('HMAC Generation and Verification', () {
      test('should generate and verify HMAC correctly', () {
        // Arrange
        const data = 'Data for HMAC testing';
        const key = 'hmac_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final isValid = encryptionService.verifyHmac(data, key, hmac);

        // Assert
        expect(hmac, isNotEmpty);
        expect(hmac.length, equals(64)); // SHA-256 hex string length
        expect(isValid, isTrue);
      });

      test('should reject invalid HMAC', () {
        // Arrange
        const data = 'Data for HMAC testing';
        const key = 'hmac_key';
        const invalidHmac = 'invalid_hmac_value';

        // Act
        final isValid = encryptionService.verifyHmac(data, key, invalidHmac);

        // Assert
        expect(isValid, isFalse);
      });

      test('should generate different HMAC for different data', () {
        // Arrange
        const data1 = 'First data';
        const data2 = 'Second data';
        const key = 'same_key';

        // Act
        final hmac1 = encryptionService.generateHmac(data1, key);
        final hmac2 = encryptionService.generateHmac(data2, key);

        // Assert
        expect(hmac1, isNot(equals(hmac2)));
      });

      test('should generate different HMAC for different keys', () {
        // Arrange
        const data = 'Same data';
        const key1 = 'first_key';
        const key2 = 'second_key';

        // Act
        final hmac1 = encryptionService.generateHmac(data, key1);
        final hmac2 = encryptionService.generateHmac(data, key2);

        // Assert
        expect(hmac1, isNot(equals(hmac2)));
      });

      test('should be case insensitive for HMAC verification', () {
        // Arrange
        const data = 'Data for case test';
        const key = 'test_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final isValidLower = encryptionService.verifyHmac(data, key, hmac.toLowerCase());
        final isValidUpper = encryptionService.verifyHmac(data, key, hmac.toUpperCase());

        // Assert
        expect(isValidLower, isTrue);
        expect(isValidUpper, isTrue);
      });
    });

    group('Secure Password Generation', () {
      test('should generate password with default length', () {
        // Act
        final password = encryptionService.generateSecurePassword();

        // Assert
        expect(password, isNotEmpty);
        expect(password.length, equals(32)); // Default length
      });

      test('should generate password with custom length', () {
        // Arrange
        const customLength = 16;

        // Act
        final password = encryptionService.generateSecurePassword(customLength);

        // Assert
        expect(password, isNotEmpty);
        expect(password.length, equals(customLength));
      });

      test('should generate different passwords each time', () {
        // Act
        final password1 = encryptionService.generateSecurePassword();
        final password2 = encryptionService.generateSecurePassword();

        // Assert
        expect(password1, isNot(equals(password2)));
      });

      test('should generate password with valid characters', () {
        // Act
        final password = encryptionService.generateSecurePassword(100);

        // Assert
        expect(password, isNotEmpty);
        
        // Check that password contains only valid characters
        const validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
        for (final char in password.split('')) {
          expect(validChars.contains(char), isTrue, reason: 'Invalid character: $char');
        }
      });

      test('should handle edge case lengths', () {
        // Act & Assert
        final shortPassword = encryptionService.generateSecurePassword(1);
        expect(shortPassword.length, equals(1));

        final longPassword = encryptionService.generateSecurePassword(1000);
        expect(longPassword.length, equals(1000));
      });
    });

    group('Error Handling', () {
      test('should throw exception for decryption with wrong password', () async {
        // Arrange
        const originalData = 'Data for wrong password test';
        const correctPassword = 'correct_password';
        const wrongPassword = 'wrong_password';

        final encryptedData = await encryptionService.encryptData(originalData, correctPassword);

        // Act & Assert
        expect(
          () => encryptionService.decryptData(encryptedData, wrongPassword),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should throw exception for invalid encrypted data format', () async {
        // Arrange
        const invalidEncryptedData = 'invalid_base64_data';
        const password = 'test_password';

        // Act & Assert
        expect(
          () => encryptionService.decryptData(invalidEncryptedData, password),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should throw exception for corrupted encrypted data', () async {
        // Arrange
        const originalData = 'Data for corruption test';
        const password = 'test_password';

        final encryptedData = await encryptionService.encryptData(originalData, password);
        
        // Corrupt the encrypted data by changing a character
        final corruptedData = '${encryptedData.substring(0, encryptedData.length - 5)}XXXXX';

        // Act & Assert
        expect(
          () => encryptionService.decryptData(corruptedData, password),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should throw exception for truncated encrypted data', () async {
        // Arrange
        const originalData = 'Data for truncation test';
        const password = 'test_password';

        final encryptedData = await encryptionService.encryptData(originalData, password);
        
        // Truncate the encrypted data
        final truncatedData = encryptedData.substring(0, encryptedData.length ~/ 2);

        // Act & Assert
        expect(
          () => encryptionService.decryptData(truncatedData, password),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should handle encryption exception details', () {
        // Arrange
        const message = 'Test encryption error';
        final exception = EncryptionException(message);

        // Assert
        expect(exception.message, equals(message));
        expect(exception.toString(), contains('EncryptionException'));
        expect(exception.toString(), contains(message));
      });
    });

    group('Performance and Security', () {
      test('should handle multiple concurrent encryptions', () async {
        // Arrange
        const dataList = [
          'First concurrent data',
          'Second concurrent data',
          'Third concurrent data',
          'Fourth concurrent data',
          'Fifth concurrent data',
        ];
        const password = 'concurrent_password';

        // Act
        final futures = dataList.map((data) => 
          encryptionService.encryptData(data, password)
        ).toList();
        
        final encryptedResults = await Future.wait(futures);

        // Assert
        expect(encryptedResults, hasLength(5));
        for (int i = 0; i < encryptedResults.length; i++) {
          expect(encryptedResults[i], isNotEmpty);
          
          // Verify each can be decrypted correctly
          final decrypted = await encryptionService.decryptData(encryptedResults[i], password);
          expect(decrypted, equals(dataList[i]));
        }

        // All encrypted results should be different (due to random IV/salt)
        final uniqueResults = encryptedResults.toSet();
        expect(uniqueResults.length, equals(5));
      });

      test('should use different salt and IV for each encryption', () async {
        // Arrange
        const data = 'Same data for salt/IV test';
        const password = 'same_password';

        // Act
        final encrypted1 = await encryptionService.encryptData(data, password);
        final encrypted2 = await encryptionService.encryptData(data, password);

        // Decode base64 to check salt and IV
        final bytes1 = base64.decode(encrypted1);
        final bytes2 = base64.decode(encrypted2);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2)));
        
        // Extract salt (first 16 bytes) and IV (next 12 bytes)
        final salt1 = bytes1.sublist(0, 16);
        final salt2 = bytes2.sublist(0, 16);
        final iv1 = bytes1.sublist(16, 28);
        final iv2 = bytes2.sublist(16, 28);

        expect(salt1, isNot(equals(salt2)));
        expect(iv1, isNot(equals(iv2)));
      });

      test('should maintain data integrity with authentication tag', () async {
        // Arrange
        const originalData = 'Data for integrity test';
        const password = 'integrity_password';

        final encryptedData = await encryptionService.encryptData(originalData, password);
        final encryptedBytes = base64.decode(encryptedData);

        // Tamper with the authentication tag (bytes 28-44)
        final tamperedBytes = Uint8List.fromList(encryptedBytes);
        tamperedBytes[30] = tamperedBytes[30] ^ 0xFF; // Flip bits in auth tag
        final tamperedData = base64.encode(tamperedBytes);

        // Act & Assert
        expect(
          () => encryptionService.decryptData(tamperedData, password),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle very long passwords', () async {
        // Arrange
        const data = 'Data for long password test';
        final longPassword = 'A' * 1000; // 1000 character password

        // Act
        final encryptedData = await encryptionService.encryptData(data, longPassword);
        final decryptedData = await encryptionService.decryptData(encryptedData, longPassword);

        // Assert
        expect(decryptedData, equals(data));
      });

      test('should handle passwords with special characters', () async {
        // Arrange
        const data = 'Data for special password test';
        const specialPassword = '密码测试!@#\$%^&*()_+{}|:"<>?[]\\;\',./ 🔐🚀';

        // Act
        final encryptedData = await encryptionService.encryptData(data, specialPassword);
        final decryptedData = await encryptionService.decryptData(encryptedData, specialPassword);

        // Assert
        expect(decryptedData, equals(data));
      });

      test('should handle data with null bytes', () async {
        // Arrange
        final dataWithNulls = 'Data\x00with\x00null\x00bytes';
        const password = 'null_bytes_password';

        // Act
        final encryptedData = await encryptionService.encryptData(dataWithNulls, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(decryptedData, equals(dataWithNulls));
      });

      test('should handle maximum practical data size', () async {
        // Arrange - 1MB of data
        final largeData = 'X' * (1024 * 1024);
        const password = 'large_data_password';

        // Act
        final encryptedData = await encryptionService.encryptData(largeData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(decryptedData, equals(largeData));
        expect(decryptedData.length, equals(1024 * 1024));
      });

      test('should handle binary data encoded as string', () async {
        // Arrange
        final binaryData = List.generate(256, (i) => i).map((i) => String.fromCharCode(i)).join();
        const password = 'binary_data_password';

        // Act
        final encryptedData = await encryptionService.encryptData(binaryData, password);
        final decryptedData = await encryptionService.decryptData(encryptedData, password);

        // Assert
        expect(decryptedData, equals(binaryData));
        expect(decryptedData.length, equals(256));
      });
    });
  });
}