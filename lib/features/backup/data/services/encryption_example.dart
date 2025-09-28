import 'dart:convert';
import 'encryption_service.dart';

/// Example demonstrating how to use the EncryptionService with backup data
/// This file shows practical usage patterns for the encryption functionality
class EncryptionExample {
  final EncryptionService _encryptionService = EncryptionService();

  /// Example: Encrypt backup data with password protection
  Future<String> encryptBackupData(Map<String, dynamic> backupData, String password) async {
    try {
      // Convert backup data to JSON string
      final jsonData = jsonEncode(backupData);
      
      // Encrypt the JSON data
      final encryptedData = await _encryptionService.encryptData(jsonData, password);
      
      print('✅ Backup data encrypted successfully');
      print('Original size: ${jsonData.length} bytes');
      print('Encrypted size: ${encryptedData.length} bytes');
      
      return encryptedData;
    } catch (e) {
      print('❌ Failed to encrypt backup data: $e');
      rethrow;
    }
  }

  /// Example: Decrypt backup data and restore
  Future<Map<String, dynamic>> decryptBackupData(String encryptedData, String password) async {
    try {
      // Decrypt the data
      final jsonData = await _encryptionService.decryptData(encryptedData, password);
      
      // Parse JSON back to Map
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      print('✅ Backup data decrypted successfully');
      print('Restored ${backupData['data']?.keys.length ?? 0} data tables');
      
      return backupData;
    } catch (e) {
      print('❌ Failed to decrypt backup data: $e');
      rethrow;
    }
  }

  /// Example: Validate password before attempting full decryption
  Future<bool> validateBackupPassword(String encryptedData, String password) async {
    try {
      final isValid = await _encryptionService.validatePassword(encryptedData, password);
      
      if (isValid) {
        print('✅ Password is valid');
      } else {
        print('❌ Invalid password');
      }
      
      return isValid;
    } catch (e) {
      print('❌ Password validation failed: $e');
      return false;
    }
  }

  /// Example: Create backup with integrity verification
  Future<Map<String, String>> createSecureBackup(
    Map<String, dynamic> backupData,
    String password,
    String integrityKey,
  ) async {
    try {
      // Encrypt the backup data
      final encryptedData = await encryptBackupData(backupData, password);
      
      // Generate HMAC for integrity verification
      final hmac = _encryptionService.generateHmac(encryptedData, integrityKey);
      
      print('✅ Secure backup created with integrity verification');
      print('HMAC: ${hmac.substring(0, 16)}...');
      
      return {
        'encryptedData': encryptedData,
        'hmac': hmac,
      };
    } catch (e) {
      print('❌ Failed to create secure backup: $e');
      rethrow;
    }
  }

  /// Example: Restore backup with integrity verification
  Future<Map<String, dynamic>> restoreSecureBackup(
    String encryptedData,
    String hmac,
    String password,
    String integrityKey,
  ) async {
    try {
      // Verify data integrity first
      final isIntegrityValid = _encryptionService.verifyHmac(encryptedData, integrityKey, hmac);
      
      if (!isIntegrityValid) {
        throw Exception('Backup data integrity verification failed - data may be corrupted');
      }
      
      print('✅ Backup integrity verified');
      
      // Decrypt the backup data
      final backupData = await decryptBackupData(encryptedData, password);
      
      print('✅ Secure backup restored successfully');
      
      return backupData;
    } catch (e) {
      print('❌ Failed to restore secure backup: $e');
      rethrow;
    }
  }

  /// Example: Generate secure password for backup encryption
  String generateBackupPassword([int length = 32]) {
    final password = _encryptionService.generateSecurePassword(length);
    
    print('✅ Generated secure password (length: $length)');
    print('Password preview: ${password.substring(0, 8)}...');
    
    return password;
  }

  /// Example: Complete backup workflow with encryption
  Future<void> demonstrateBackupWorkflow() async {
    print('\n🔐 Encryption Service Demo - Backup Workflow');
    print('=' * 50);
    
    try {
      // Sample backup data
      final backupData = {
        'metadata': {
          'id': 'demo_backup_${DateTime.now().millisecondsSinceEpoch}',
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
          'tableCounts': {'products': 5, 'categories': 2},
        },
        'data': {
          'products': [
            {'id': 1, 'name': '测试产品', 'price': 29.99},
            {'id': 2, 'name': 'Test Product', 'price': 15.50},
          ],
          'categories': [
            {'id': 1, 'name': '电子产品'},
            {'id': 2, 'name': 'Books'},
          ],
        },
      };

      // Step 1: Generate secure password
      print('\n1️⃣ Generating secure password...');
      final password = generateBackupPassword();

      // Step 2: Create secure backup
      print('\n2️⃣ Creating secure backup...');
      const integrityKey = 'backup_integrity_key_2024';
      final secureBackup = await createSecureBackup(backupData, password, integrityKey);

      // Step 3: Validate password
      print('\n3️⃣ Validating password...');
      await validateBackupPassword(secureBackup['encryptedData']!, password);

      // Step 4: Restore secure backup
      print('\n4️⃣ Restoring secure backup...');
      final restoredData = await restoreSecureBackup(
        secureBackup['encryptedData']!,
        secureBackup['hmac']!,
        password,
        integrityKey,
      );

      // Step 5: Verify restoration
      print('\n5️⃣ Verifying restoration...');
      final originalProducts = (backupData['data'] as Map<String, dynamic>)['products'] as List;
      final restoredProducts = (restoredData['data'] as Map<String, dynamic>)['products'] as List;
      final originalProductCount = originalProducts.length;
      final restoredProductCount = restoredProducts.length;
      
      if (originalProductCount == restoredProductCount) {
        print('✅ Backup and restore completed successfully!');
        print('Products: $originalProductCount → $restoredProductCount');
      } else {
        print('❌ Data mismatch detected!');
      }

    } catch (e) {
      print('❌ Demo failed: $e');
    }
    
    print('\n${'=' * 50}');
  }
}

/// Run the encryption example
Future<void> main() async {
  final example = EncryptionExample();
  await example.demonstrateBackupWorkflow();
}