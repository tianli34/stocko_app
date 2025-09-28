import 'package:flutter_test/flutter_test.dart';

// Import all backup test files
import 'data/services/backup_service_test.dart' as backup_service_test;
import 'data/services/restore_service_test.dart' as restore_service_test;
import 'data/services/encryption_service_comprehensive_test.dart' as encryption_service_test;
import 'data/services/validation_service_comprehensive_test.dart' as validation_service_test;
import 'data/repository/data_export_repository_comprehensive_test.dart' as export_repository_test;
import 'data/repository/data_import_repository_comprehensive_test.dart' as import_repository_test;

void main() {
  group('Backup System Comprehensive Tests', () {
    group('Services', () {
      backup_service_test.main();
      restore_service_test.main();
      encryption_service_test.main();
      validation_service_test.main();
    });

    group('Repositories', () {
      export_repository_test.main();
      import_repository_test.main();
    });
  });
}