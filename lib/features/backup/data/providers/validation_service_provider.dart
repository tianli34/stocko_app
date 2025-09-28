import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../domain/services/i_validation_service.dart';
import '../services/validation_service.dart';
import 'encryption_service_provider.dart';

part 'validation_service_provider.g.dart';

/// 验证服务提供者
@riverpod
IValidationService validationService(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  
  return ValidationService(database, encryptionService);
}