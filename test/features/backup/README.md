# Backup System Unit Tests

This directory contains comprehensive unit tests for the backup and restore functionality of the 铺得清 app.

## Test Coverage

### Services Tests
- **BackupService** (`backup_service_test.dart`)
  - Instance creation and configuration
  - Backup options validation and serialization
  - Cancel token handling
  - Backup file validation and metadata extraction
  - Local backup management
  - Error handling for various scenarios
  - Progress callback functionality
  - Edge cases and boundary conditions

- **RestoreService** (`restore_service_test.dart`)
  - Instance creation and restore mode validation
  - Backup file validation with encryption support
  - Restore preview generation with compatibility checks
  - Full restore operations in merge and replace modes
  - Restore cancellation handling
  - Selected table restoration
  - Compatibility checking
  - Restore time estimation
  - Comprehensive error handling

- **EncryptionService** (`encryption_service_comprehensive_test.dart`)
  - Data encryption and decryption with AES-256-GCM
  - Password validation and authentication
  - HMAC generation and verification for data integrity
  - Secure password generation
  - Error handling for invalid data and wrong passwords
  - Performance testing with concurrent operations
  - Edge cases with special characters and large data

- **ValidationService** (`validation_service_comprehensive_test.dart`)
  - Backup format validation
  - Version compatibility checking
  - Data integrity validation with checksum verification
  - Duplicate record detection
  - Missing relationship detection
  - Orphaned record identification

### Repository Tests
- **DataExportRepository** (`data_export_repository_comprehensive_test.dart`)
  - Data serialization to JSON with pretty printing
  - Checksum generation for data integrity
  - Mock database operations
  - Error handling for serialization failures
  - Performance testing with large datasets
  - Edge cases with various data types

- **DataImportRepository** (`data_import_repository_comprehensive_test.dart`)
  - Data validation for import operations
  - Conflict detection and resolution
  - Import time estimation
  - Full import operations with progress tracking
  - Health check operations
  - Error handling and transaction rollback
  - Performance and scalability testing
  - Edge cases and boundary conditions

## Test Features

### Mock Database and File System
- Comprehensive mocking of database operations
- File system simulation for backup/restore operations
- Temporary directory management for test isolation

### Error Scenarios Testing
- Database connection failures
- File system errors and permissions
- Data corruption and invalid formats
- Network timeouts and cancellation
- Memory limitations and large datasets

### Edge Cases and Boundary Conditions
- Empty data and null values
- Special characters and Unicode support
- Very large datasets and memory optimization
- Numeric edge cases and date/time handling
- Boolean type variations

### Performance Testing
- Concurrent operations
- Large dataset handling
- Memory usage optimization
- Progress reporting accuracy

## Running Tests

### Run All Backup Tests
```bash
flutter test test/features/backup/run_all_backup_tests.dart
```

### Run Individual Test Files
```bash
# Backup Service Tests
flutter test test/features/backup/data/services/backup_service_test.dart

# Restore Service Tests
flutter test test/features/backup/data/services/restore_service_test.dart

# Encryption Service Tests
flutter test test/features/backup/data/services/encryption_service_comprehensive_test.dart

# Validation Service Tests
flutter test test/features/backup/data/services/validation_service_comprehensive_test.dart

# Export Repository Tests
flutter test test/features/backup/data/repository/data_export_repository_comprehensive_test.dart

# Import Repository Tests
flutter test test/features/backup/data/repository/data_import_repository_comprehensive_test.dart
```

### Run with Coverage
```bash
flutter test --coverage test/features/backup/
genhtml coverage/lcov.info -o coverage/html
```

## Test Requirements Coverage

The tests cover all requirements specified in the backup and restore specification:

- **Data Serialization**: JSON serialization with checksum validation
- **Encryption/Decryption**: AES-256-GCM encryption with password protection
- **Error Handling**: Comprehensive error scenarios and graceful degradation
- **Mock Testing**: Database and file system mocking for isolated testing
- **Performance**: Large dataset handling and concurrent operations
- **Validation**: Data integrity, format validation, and compatibility checking
- **Progress Tracking**: Real-time progress reporting during operations
- **Cancellation**: Operation cancellation with proper cleanup

## Test Statistics

- **Total Test Files**: 6
- **Total Test Cases**: 150+
- **Coverage Areas**: Services, Repositories, Models, Error Handling
- **Mock Objects**: Database, File System, Encryption Services
- **Test Data Scenarios**: Valid, Invalid, Edge Cases, Performance

## Notes

- All tests use Flutter's `TestWidgetsFlutterBinding.ensureInitialized()` for proper initialization
- Temporary directories are created and cleaned up for each test
- Mock objects are properly configured with fallback values
- Tests are designed to be independent and can run in any order
- Error messages are in Chinese to match the application's localization