import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/application/category_service.dart';
import 'package:stocko_app/features/product/domain/model/category.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/domain/repository/i_category_repository.dart';
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';

class MockCategoryRepository extends Mock implements ICategoryRepository {}
class MockProductRepository extends Mock implements IProductRepository {}

class FakeCategoryModel extends Fake implements CategoryModel {}
class FakeProductModel extends Fake implements ProductModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCategoryModel());
    registerFallbackValue(FakeProductModel());
  });

  group('CategoryService', () {
    late MockCategoryRepository categoryRepo;
    late MockProductRepository productRepo;
    late CategoryService service;

    setUp(() {
      categoryRepo = MockCategoryRepository();
      productRepo = MockProductRepository();
      service = CategoryService(categoryRepo, productRepo);
    });

    test('addCategory 成功添加类别', () async {
      when(() => categoryRepo.isCategoryNameExists('水果', null))
          .thenAnswer((_) async => false);
      when(() => categoryRepo.addCategory(any())).thenAnswer((_) async => 1);

      await service.addCategory(name: '水果');

      verify(() => categoryRepo.isCategoryNameExists('水果', null)).called(1);
      verify(() => categoryRepo.addCategory(any())).called(1);
    });

    test('addCategory 名称重复抛出异常', () async {
      when(() => categoryRepo.isCategoryNameExists('水果', null))
          .thenAnswer((_) async => true);

      expect(
        () => service.addCategory(name: '水果'),
        throwsA(isA<Exception>()),
      );
      verify(() => categoryRepo.isCategoryNameExists('水果', null)).called(1);
      verifyNever(() => categoryRepo.addCategory(any()));
    });

    test('updateCategory 父子循环关系抛出异常', () async {
      // existing category
      when(() => categoryRepo.getCategoryById(10)).thenAnswer(
          (_) async => const CategoryModel(id: 10, name: '食品', parentId: null));
      // name not duplicate
      when(() => categoryRepo.isCategoryNameExists('休闲食品', 5, excludeId: 10))
          .thenAnswer((_) async => false);
      // parent exists
      when(() => categoryRepo.getCategoryById(5)).thenAnswer(
          (_) async => const CategoryModel(id: 5, name: '零食', parentId: null));
      // path of parent contains the id (cycle)
      when(() => categoryRepo.getCategoryPath(5)).thenAnswer((_) async => [
            const CategoryModel(id: 1, name: '根'),
            const CategoryModel(id: 10, name: '食品'),
          ]);

      expect(
        () => service.updateCategory(id: 10, name: '休闲食品', parentId: 5),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => categoryRepo.updateCategory(any()));
    });

    test('deleteCategoryOnly 处理产品与子类后删除自身', () async {
      // category 10 with parent 5
      const category = CategoryModel(id: 10, name: '零食', parentId: 5);
      when(() => categoryRepo.getCategoryById(10))
          .thenAnswer((_) async => category);

      // sub-categories under 10
      final subs = [
        const CategoryModel(id: 11, name: '薯片', parentId: 10),
        const CategoryModel(id: 12, name: '饼干', parentId: 10),
      ];
      when(() => categoryRepo.getAllCategories()).thenAnswer((_) async => [
            category,
            ...subs,
          ]);

      // products under category 10
      final products = [
        ProductModel(id: 100, name: '薯片A', baseUnitId: 1, categoryId: 10),
        ProductModel(id: 101, name: '饼干B', baseUnitId: 1, categoryId: 10),
      ];
      when(() => productRepo.getProductsByCondition(categoryId: 10))
          .thenAnswer((_) async => products);
      when(() => productRepo.updateProduct(any()))
          .thenAnswer((_) async => true);

      // update sub categories
      when(() => categoryRepo.updateCategory(any()))
          .thenAnswer((_) async => true);
      when(() => categoryRepo.deleteCategory(10)).thenAnswer((_) async => 1);

      await service.deleteCategoryOnly(10);

      // products moved to parent 5
      verify(() => productRepo.updateProduct(any())).called(products.length);
      // subs adopt parent 5
      verify(() => categoryRepo.updateCategory(any())).called(subs.length);
      // delete self
      verify(() => categoryRepo.deleteCategory(10)).called(1);
    });
  });
}
