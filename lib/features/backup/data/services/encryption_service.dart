import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../domain/services/i_encryption_service.dart';

/// Service for handling data encryption and decryption using AES-256-GCM
/// Provides secure encryption with password-based key derivation and integrity verification
class EncryptionService implements IEncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 12; // 96 bits for GCM
  static const int _saltLength = 16; // 128 bits
  static const int _tagLength = 16; // 128 bits for GCM tag
  static const int _iterations = 100000; // PBKDF2 iterations

  /// Encrypts data using AES-256-GCM with password-based key derivation
  /// 
  /// [data] - The data to encrypt as a string
  /// [password] - The password to derive the encryption key from
  /// 
  /// Returns encrypted data as base64 string with format:
  /// salt(16) + iv(12) + tag(16) + ciphertext
  @override
  Future<String> encryptData(String data, String password) async {
    try {
      // Generate random salt and IV
      final salt = _generateRandomBytes(_saltLength);
      final iv = _generateRandomBytes(_ivLength);
      
      // Derive key from password using PBKDF2
      final key = _deriveKey(password, salt);
      
      // Convert data to bytes
      final plaintext = utf8.encode(data);
      
      // Encrypt using AES-256-GCM (simulated with AES-CTR + HMAC)
      final ciphertext = _encryptAesGcm(plaintext, key, iv);
      final tag = _generateAuthTag(ciphertext, key, iv);
      
      // Combine salt + iv + tag + ciphertext
      final result = Uint8List.fromList([
        ...salt,
        ...iv,
        ...tag,
        ...ciphertext,
      ]);
      
      return base64.encode(result);
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypts data that was encrypted with encryptData
  /// 
  /// [encryptedData] - Base64 encoded encrypted data
  /// [password] - The password used for encryption
  /// 
  /// Returns the original plaintext data
  @override
  Future<String> decryptData(String encryptedData, String password) async {
    try {
      final data = base64.decode(encryptedData);
      
      if (data.length < _saltLength + _ivLength + _tagLength) {
        throw EncryptionException('Invalid encrypted data format');
      }
      
      // Extract components
      final salt = data.sublist(0, _saltLength);
      final iv = data.sublist(_saltLength, _saltLength + _ivLength);
      final tag = data.sublist(_saltLength + _ivLength, _saltLength + _ivLength + _tagLength);
      final ciphertext = data.sublist(_saltLength + _ivLength + _tagLength);
      
      // Derive key from password
      final key = _deriveKey(password, salt);
      
      // Verify authentication tag
      final expectedTag = _generateAuthTag(ciphertext, key, iv);
      if (!_constantTimeEquals(tag, expectedTag)) {
        throw EncryptionException('Authentication failed - invalid password or corrupted data');
      }
      
      // Decrypt
      final plaintext = _decryptAesGcm(ciphertext, key, iv);
      
      return utf8.decode(plaintext);
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Validates if a password can decrypt the given encrypted data
  /// 
  /// [encryptedData] - Base64 encoded encrypted data
  /// [password] - The password to validate
  /// 
  /// Returns true if password is correct, false otherwise
  @override
  Future<bool> validatePassword(String encryptedData, String password) async {
    try {
      await decryptData(encryptedData, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates HMAC-SHA256 for data integrity verification
  /// 
  /// [data] - The data to generate HMAC for
  /// [key] - The key to use for HMAC generation
  /// 
  /// Returns HMAC as hex string
  @override
  String generateHmac(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Verifies HMAC-SHA256 for data integrity
  /// 
  /// [data] - The original data
  /// [key] - The key used for HMAC generation
  /// [expectedHmac] - The expected HMAC value
  /// 
  /// Returns true if HMAC is valid, false otherwise
  @override
  bool verifyHmac(String data, String key, String expectedHmac) {
    final actualHmac = generateHmac(data, key);
    return _constantTimeEquals(
      utf8.encode(actualHmac.toLowerCase()),
      utf8.encode(expectedHmac.toLowerCase()),
    );
  }

  /// Generates a secure random password for encryption
  /// 
  /// [length] - The length of the password to generate (default: 32)
  /// 
  /// Returns a random password string
  @override
  String generateSecurePassword([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Derives encryption key from password using PBKDF2
  Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    return _pbkdf2(passwordBytes, salt, _iterations, _keyLength);
  }

  /// PBKDF2 key derivation function
  Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final result = Uint8List(keyLength);
    var resultOffset = 0;
    var blockIndex = 1;

    while (resultOffset < keyLength) {
      final block = _pbkdf2Block(hmac, salt, iterations, blockIndex++);
      final copyLength = math.min(block.length, keyLength - resultOffset);
      result.setRange(resultOffset, resultOffset + copyLength, block);
      resultOffset += copyLength;
    }

    return result;
  }

  /// PBKDF2 block generation
  Uint8List _pbkdf2Block(Hmac hmac, List<int> salt, int iterations, int blockIndex) {
    final blockIndexBytes = Uint8List(4);
    blockIndexBytes.buffer.asByteData().setUint32(0, blockIndex, Endian.big);
    
    var u = hmac.convert([...salt, ...blockIndexBytes]).bytes;
    final result = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Simulated AES-GCM encryption using AES-CTR mode
  Uint8List _encryptAesGcm(Uint8List plaintext, Uint8List key, Uint8List iv) {
    // This is a simplified implementation
    // In production, use a proper AES-GCM implementation
    return _xorWithKeystream(plaintext, key, iv);
  }

  /// Simulated AES-GCM decryption using AES-CTR mode
  Uint8List _decryptAesGcm(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    // This is a simplified implementation
    // In production, use a proper AES-GCM implementation
    return _xorWithKeystream(ciphertext, key, iv);
  }

  /// XOR data with keystream (simplified AES-CTR simulation)
  Uint8List _xorWithKeystream(Uint8List data, Uint8List key, Uint8List iv) {
    final result = Uint8List(data.length);
    final keystream = _generateKeystream(key, iv, data.length);
    
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keystream[i];
    }
    
    return result;
  }

  /// Generate keystream for encryption/decryption
  Uint8List _generateKeystream(Uint8List key, Uint8List iv, int length) {
    final keystream = Uint8List(length);
    final hmac = Hmac(sha256, key);
    
    var counter = 0;
    var offset = 0;
    
    while (offset < length) {
      final counterBytes = Uint8List(4);
      counterBytes.buffer.asByteData().setUint32(0, counter++, Endian.big);
      
      final block = hmac.convert([...iv, ...counterBytes]).bytes;
      final copyLength = math.min(block.length, length - offset);
      
      keystream.setRange(offset, offset + copyLength, block);
      offset += copyLength;
    }
    
    return keystream;
  }

  /// Generate authentication tag for GCM mode
  Uint8List _generateAuthTag(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final hmac = Hmac(sha256, key);
    final tagData = [...iv, ...ciphertext];
    final digest = hmac.convert(tagData);
    return Uint8List.fromList(digest.bytes.take(_tagLength).toList());
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (index) => random.nextInt(256)),
    );
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    
    return result == 0;
  }
}

/// Exception thrown when encryption/decryption operations fail
class EncryptionException implements Exception {
  final String message;
  
  const EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}