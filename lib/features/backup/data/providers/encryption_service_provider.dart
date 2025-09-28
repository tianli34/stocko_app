import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/encryption_service.dart';
import '../../domain/services/i_encryption_service.dart';

part 'encryption_service_provider.g.dart';

/// Provider for the encryption service
/// Provides a singleton instance of the encryption service
@riverpod
IEncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService();
}