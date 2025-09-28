/// Interface for encryption and security services
/// Defines the contract for data encryption, decryption, and integrity verification
abstract class IEncryptionService {
  /// Encrypts data using AES-256-GCM with password-based key derivation
  /// 
  /// [data] - The data to encrypt as a string
  /// [password] - The password to derive the encryption key from
  /// 
  /// Returns encrypted data as base64 string
  Future<String> encryptData(String data, String password);

  /// Decrypts data that was encrypted with encryptData
  /// 
  /// [encryptedData] - Base64 encoded encrypted data
  /// [password] - The password used for encryption
  /// 
  /// Returns the original plaintext data
  Future<String> decryptData(String encryptedData, String password);

  /// Validates if a password can decrypt the given encrypted data
  /// 
  /// [encryptedData] - Base64 encoded encrypted data
  /// [password] - The password to validate
  /// 
  /// Returns true if password is correct, false otherwise
  Future<bool> validatePassword(String encryptedData, String password);

  /// Generates HMAC-SHA256 for data integrity verification
  /// 
  /// [data] - The data to generate HMAC for
  /// [key] - The key to use for HMAC generation
  /// 
  /// Returns HMAC as hex string
  String generateHmac(String data, String key);

  /// Verifies HMAC-SHA256 for data integrity
  /// 
  /// [data] - The original data
  /// [key] - The key used for HMAC generation
  /// [expectedHmac] - The expected HMAC value
  /// 
  /// Returns true if HMAC is valid, false otherwise
  bool verifyHmac(String data, String key, String expectedHmac);

  /// Generates a secure random password for encryption
  /// 
  /// [length] - The length of the password to generate (default: 32)
  /// 
  /// Returns a random password string
  String generateSecurePassword([int length = 32]);
}