import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/core/services/image_cache_service.dart';
import 'package:stocko_app/core/services/image_service.dart';
import 'package:path/path.dart' as p;

// Mocks
class MockImagePicker extends Mock implements ImagePicker {}
class MockImageCacheService extends Mock implements ImageCacheService {}
// A fake XFile for testing purposes.
class FakeXFile extends Fake implements XFile {
  @override
  final String path;

  FakeXFile(this.path);
}

void main() {
  late ImageService imageService;
  late MockImagePicker mockImagePicker;
  late MockImageCacheService mockImageCacheService;
  late Directory tempDir;

  setUpAll(() async {
    // This is required to mock platform channels.
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create a temporary directory for file system operations
    tempDir = await Directory.systemTemp.createTemp('image_service_test_');

    // Mock path_provider
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  setUp(() {
    mockImagePicker = MockImagePicker();
    mockImageCacheService = MockImageCacheService();
    imageService = ImageService.forTest(
      picker: mockImagePicker,
      cacheService: mockImageCacheService,
    );
  });

  tearDownAll(() async {
    // Clean up the temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageService', () {
    group('pickImageFromCamera', () {
      test('should return image path when an image is picked', () async {
        // Arrange
        // 1. Create a temporary file to simulate a picked image.
        final fakeSourceFile = File(p.join(tempDir.path, 'fake_source.jpg'));
        await fakeSourceFile.writeAsString('fake image data');

        // 2. Create a fake XFile that points to our temporary file.
        final fakeXFile = FakeXFile(fakeSourceFile.path);

        // 3. Stub the picker to return our fake XFile.
        when(() => mockImagePicker.pickImage(
              source: ImageSource.camera,
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => fakeXFile);

        // 4. Stub the cache service.
        when(() => mockImageCacheService.preloadImage(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await imageService.pickImageFromCamera();

        // Assert
        expect(result, isNotNull);
        expect(result, contains(p.join('product_images', 'product_')));
        verify(() => mockImageCacheService.preloadImage(any(that: contains('product_images')))).called(1);
      });

      test('should return null when no image is picked', () async {
        // Arrange
        when(() => mockImagePicker.pickImage(source: ImageSource.camera, maxWidth: any(named: 'maxWidth'), maxHeight: any(named: 'maxHeight'), imageQuality: any(named: 'imageQuality'))).thenAnswer((_) async => null);

        // Act
        final result = await imageService.pickImageFromCamera();

        // Assert
        expect(result, isNull);
      });
    });

    test('deleteImage should delete the file if it exists', () async {
        // Arrange
        final testFile = File(p.join(tempDir.path, 'test_to_delete.jpg'));
        await testFile.writeAsString('deletable');
        expect(await testFile.exists(), isTrue);

        // Act
        final result = await imageService.deleteImage(testFile.path);

        // Assert
        expect(result, isTrue);
        expect(await testFile.exists(), isFalse);
    });

    test('clearAllProductImages should delete the entire image directory', () async {
      // Arrange
      final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
      final testFile = File(p.join(imagesDir.path, 'test.jpg'));
      await testFile.create(recursive: true);
      await testFile.writeAsString('data');
      expect(await imagesDir.exists(), isTrue);
      
      // Act
      await imageService.clearAllProductImages();

      // Assert
      expect(await imagesDir.exists(), isFalse);
    });

  });
}
