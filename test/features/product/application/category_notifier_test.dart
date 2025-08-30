import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/application/category_notifier.dart';
import 'package:stocko_app/features/product/application/category_service.dart';
import 'package:stocko_app/features/product/domain/model/category.dart';

class MockCategoryService extends Mock implements CategoryService {}

void main() {
  group('CategoryListNotifier', () {
    late ProviderContainer container;
    late MockCategoryService mockService;

    setUp(() {
      mockService = MockCategoryService();
      container = ProviderContainer(overrides: [
        categoryServiceProvider.overrideWithValue(mockService),
      ]);
    });

    tearDown(() => container.dispose());

    test('loadCategories 成功加载', () async {
      when(() => mockService.getAllCategories()).thenAnswer((_) async => [
            const CategoryModel(id: 1, name: '食品'),
          ]);

      final notifier = CategoryListNotifier(mockService);
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.categories.length, 1);
    });

    test('addCategory 调用后会刷新列表', () async {
      // initial load
      when(() => mockService.getAllCategories()).thenAnswer((_) async => []);
      when(() => mockService.addCategory(name: '饮料', parentId: null))
          .thenAnswer((_) async {});
      // reload
      when(() => mockService.getAllCategories())
          .thenAnswer((_) async => [const CategoryModel(id: 2, name: '饮料')]);

      final notifier = CategoryListNotifier(mockService);
      await notifier.addCategory(name: '饮料');

      expect(notifier.state.categories.map((e) => e.name), contains('饮料'));
    });

    test('updateCategory 失败时设置 error', () async {
      when(() => mockService.updateCategory(id: 1, name: '新', parentId: null))
          .thenThrow(Exception('更新失败'));

      final notifier = CategoryListNotifier(mockService);

      expect(
        () => notifier.updateCategory(id: 1, name: '新'),
        throwsException,
      );
      expect(notifier.state.error, contains('更新失败'));
    });

    test('deleteCategoryOnly 成功后刷新列表', () async {
      when(() => mockService.deleteCategoryOnly(3)).thenAnswer((_) async {});
      when(() => mockService.getAllCategories())
          .thenAnswer((_) async => [const CategoryModel(id: 4, name: '其它')]);

      final notifier = CategoryListNotifier(mockService);
      await notifier.deleteCategoryOnly(3);

      expect(notifier.state.categories.length, 1);
    });
  });
}
