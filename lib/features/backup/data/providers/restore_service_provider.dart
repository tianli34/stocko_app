import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/services/i_restore_service.dart';
import '../services/optimized_restore_service.dart';
import 'encryption_service_provider.dart';
import 'validation_service_provider.dart';

/// 恢复服务提供者
final restoreServiceProvider = Provider<IRestoreService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  final validationService = ref.watch(validationServiceProvider);
  return OptimizedRestoreService(database, encryptionService, validationService);
});