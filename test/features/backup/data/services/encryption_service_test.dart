import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    group('encryptData and decryptData', () {
      test('should encrypt and decrypt data successfully', () async {
        // Arrange
        const testData = 'Hello, World! This is a test message.';
        const password = 'test_password_123';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);

        // Assert
        expect(decrypted, equals(testData));
        expect(encrypted, isNot(equals(testData)));
        expect(encrypted.length, greaterThan(testData.length));
      });

      test('should handle empty data', () async {
        // Arrange
        const testData = '';
        const password = 'test_password_123';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);

        // Assert
        expect(decrypted, equals(testData));
      });

      test('should handle large data', () async {
        // Arrange
        final testData = 'A' * 10000; // 10KB of data
        const password = 'test_password_123';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);

        // Assert
        expect(decrypted, equals(testData));
      });

      test('should handle special characters and unicode', () async {
        // Arrange
        const testData = '测试数据 🔐 Special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?';
        const password = 'test_password_123';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final decrypted = await encryptionService.decryptData(encrypted, password);

        // Assert
        expect(decrypted, equals(testData));
      });

      test('should produce different encrypted output for same data', () async {
        // Arrange
        const testData = 'Hello, World!';
        const password = 'test_password_123';

        // Act
        final encrypted1 = await encryptionService.encryptData(testData, password);
        final encrypted2 = await encryptionService.encryptData(testData, password);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2))); // Different due to random IV
        
        final decrypted1 = await encryptionService.decryptData(encrypted1, password);
        final decrypted2 = await encryptionService.decryptData(encrypted2, password);
        
        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));
      });

      test('should fail with wrong password', () async {
        // Arrange
        const testData = 'Hello, World!';
        const password = 'correct_password';
        const wrongPassword = 'wrong_password';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);

        // Assert
        expect(
          () => encryptionService.decryptData(encrypted, wrongPassword),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should fail with corrupted data', () async {
        // Arrange
        const testData = 'Hello, World!';
        const password = 'test_password_123';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final corruptedData = '${encrypted.substring(0, encrypted.length - 10)}corrupted';

        // Assert
        expect(
          () => encryptionService.decryptData(corruptedData, password),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should fail with invalid base64 data', () async {
        // Arrange
        const password = 'test_password_123';
        const invalidData = 'not_valid_base64!@#';

        // Assert
        expect(
          () => encryptionService.decryptData(invalidData, password),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('should fail with too short encrypted data', () async {
        // Arrange
        const password = 'test_password_123';
        const shortData = 'dGVzdA=='; // "test" in base64, too short

        // Assert
        expect(
          () => encryptionService.decryptData(shortData, password),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('validatePassword', () {
      test('should return true for correct password', () async {
        // Arrange
        const testData = 'Hello, World!';
        const password = 'correct_password';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final isValid = await encryptionService.validatePassword(encrypted, password);

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for incorrect password', () async {
        // Arrange
        const testData = 'Hello, World!';
        const password = 'correct_password';
        const wrongPassword = 'wrong_password';

        // Act
        final encrypted = await encryptionService.encryptData(testData, password);
        final isValid = await encryptionService.validatePassword(encrypted, wrongPassword);

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for corrupted data', () async {
        // Arrange
        const password = 'test_password_123';
        const corruptedData = 'corrupted_data';

        // Act
        final isValid = await encryptionService.validatePassword(corruptedData, password);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('generateHmac and verifyHmac', () {
      test('should generate and verify HMAC correctly', () {
        // Arrange
        const data = 'Hello, World!';
        const key = 'secret_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final isValid = encryptionService.verifyHmac(data, key, hmac);

        // Assert
        expect(hmac, isNotEmpty);
        expect(hmac.length, equals(64)); // SHA-256 hex string length
        expect(isValid, isTrue);
      });

      test('should fail verification with wrong key', () {
        // Arrange
        const data = 'Hello, World!';
        const key = 'secret_key';
        const wrongKey = 'wrong_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final isValid = encryptionService.verifyHmac(data, wrongKey, hmac);

        // Assert
        expect(isValid, isFalse);
      });

      test('should fail verification with wrong data', () {
        // Arrange
        const data = 'Hello, World!';
        const wrongData = 'Hello, Universe!';
        const key = 'secret_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final isValid = encryptionService.verifyHmac(wrongData, key, hmac);

        // Assert
        expect(isValid, isFalse);
      });

      test('should fail verification with corrupted HMAC', () {
        // Arrange
        const data = 'Hello, World!';
        const key = 'secret_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final corruptedHmac = '${hmac.substring(0, hmac.length - 2)}xx';
        final isValid = encryptionService.verifyHmac(data, key, corruptedHmac);

        // Assert
        expect(isValid, isFalse);
      });

      test('should handle case insensitive HMAC verification', () {
        // Arrange
        const data = 'Hello, World!';
        const key = 'secret_key';

        // Act
        final hmac = encryptionService.generateHmac(data, key);
        final upperHmac = hmac.toUpperCase();
        final isValid = encryptionService.verifyHmac(data, key, upperHmac);

        // Assert
        expect(isValid, isTrue);
      });

      test('should generate consistent HMAC for same input', () {
        // Arrange
        const data = 'Hello, World!';
        const key = 'secret_key';

        // Act
        final hmac1 = encryptionService.generateHmac(data, key);
        final hmac2 = encryptionService.generateHmac(data, key);

        // Assert
        expect(hmac1, equals(hmac2));
      });
    });

    group('generateSecurePassword', () {
      test('should generate password with default length', () {
        // Act
        final password = encryptionService.generateSecurePassword();

        // Assert
        expect(password.length, equals(32));
        expect(password, isNotEmpty);
      });

      test('should generate password with custom length', () {
        // Arrange
        const customLength = 16;

        // Act
        final password = encryptionService.generateSecurePassword(customLength);

        // Assert
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
        const validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
        for (final char in password.split('')) {
          expect(validChars.contains(char), isTrue, reason: 'Invalid character: $char');
        }
      });

      test('should handle zero length', () {
        // Act
        final password = encryptionService.generateSecurePassword(0);

        // Assert
        expect(password, isEmpty);
      });
    });

    group('EncryptionException', () {
      test('should have correct message', () {
        // Arrange
        const message = 'Test error message';

        // Act
        final exception = EncryptionException(message);

        // Assert
        expect(exception.message, equals(message));
        expect(exception.toString(), equals('EncryptionException: $message'));
      });
    });
  });
}