import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/category.dart';
import 'package:stocko_app/features/product/application/provider/category_providers.dart';

void main() {
  group('CategoryNotifier Tests', () {
    late CategoryNotifier notifier;

    setUp(() {
      notifier = CategoryNotifier();
    });

    group('初始状态', () {
      test('应该有预定义的初始类别', () {
        expect(notifier.state.length, 8);
        expect(notifier.state.first.name, '食品饮料');
        expect(notifier.state.last.name, '运动户外');
      });
    });

    group('addCategory', () {
      test('应该成功添加新类别', () {
        const categoryName = '新类别';
        final initialCount = notifier.state.length;

        notifier.addCategory(categoryName);

        expect(notifier.state.length, initialCount + 1);
        expect(notifier.state.last.name, categoryName);
        expect(notifier.state.last.parentId, isNull);
      });
    });

    group('addSubCategory', () {
      test('应该成功添加子类别', () {
        const parentId = '1';
        const subCategoryName = '子类别';
        final initialCount = notifier.state.length;

        notifier.addSubCategory(subCategoryName, parentId);

        expect(notifier.state.length, initialCount + 1);
        final addedSubCategory = notifier.state.last;
        expect(addedSubCategory.name, subCategoryName);
        expect(addedSubCategory.parentId, parentId);
      });

      test('应该为子类别生成唯一ID', () {
        const parentId = '1';
        const subCategoryName1 = '子类别1';
        const subCategoryName2 = '子类别2';

        notifier.addSubCategory(subCategoryName1, parentId);
        final firstSubCategory = notifier.state.last;

        notifier.addSubCategory(subCategoryName2, parentId);
        final secondSubCategory = notifier.state.last;

        expect(firstSubCategory.id, isNot(secondSubCategory.id));
        expect(firstSubCategory.parentId, parentId);
        expect(secondSubCategory.parentId, parentId);
      });
    });

    group('updateCategory', () {
      test('应该成功更新类别名称', () {
        const categoryId = '1';
        const newName = '更新后的类别';

        notifier.updateCategory(categoryId, newName);

        final updatedCategory = notifier.state.firstWhere(
          (category) => category.id == categoryId,
        );
        expect(updatedCategory.name, newName);
      });

      test('应该保持其他属性不变', () {
        const categoryId = '1';
        const newName = '更新后的类别';

        final originalCategory = notifier.state.firstWhere(
          (category) => category.id == categoryId,
        );

        notifier.updateCategory(categoryId, newName);

        final updatedCategory = notifier.state.firstWhere(
          (category) => category.id == categoryId,
        );

        expect(updatedCategory.id, originalCategory.id);
        expect(updatedCategory.parentId, originalCategory.parentId);
        expect(updatedCategory.name, newName);
      });
    });

    group('deleteCategory', () {
      test('应该成功删除类别', () {
        const categoryId = '1';
        final initialCount = notifier.state.length;

        notifier.deleteCategory(categoryId);

        expect(notifier.state.length, initialCount - 1);
        expect(
          notifier.state.any((category) => category.id == categoryId),
          isFalse,
        );
      });
      test('删除父类别时应该同时删除所有子类别', () {
        // 首先添加一个子类别
        const parentId = '1';
        const subCategoryName = '子类别';
        notifier.addSubCategory(subCategoryName, parentId);

        final initialCount = notifier.state.length;
        final subCategory = notifier.state.firstWhere(
          (category) => category.parentId == parentId,
        );

        // 删除父类别
        notifier.deleteCategory(parentId);

        // 父类别和子类别都应该被删除
        expect(notifier.state.length, initialCount - 2);
        expect(
          notifier.state.any((category) => category.id == parentId),
          isFalse,
        );
        expect(
          notifier.state.any((category) => category.id == subCategory.id),
          isFalse,
        );
      });
    });

    group('层级结构测试', () {
      test('应该能够创建多层级的类别结构', () {
        const parentId = '1';
        const subCategory1Name = '子类别1';
        const subCategory2Name = '子类别2';

        notifier.addSubCategory(subCategory1Name, parentId);
        notifier.addSubCategory(subCategory2Name, parentId);

        final parentCategory = notifier.state.firstWhere(
          (category) => category.id == parentId,
        );

        final subCategories = notifier.state
            .where((category) => category.parentId == parentId)
            .toList();

        expect(parentCategory.parentId, isNull);
        expect(subCategories.length, 2);
        expect(subCategories.every((sub) => sub.parentId == parentId), isTrue);
      });
    });
  });
}
