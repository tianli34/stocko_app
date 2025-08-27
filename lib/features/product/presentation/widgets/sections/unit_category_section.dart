import 'package:flutter/material.dart';
import '../../../domain/model/unit.dart';
import '../../../domain/model/category.dart';
import '../inputs/unit_typeahead_field.dart';
import '../inputs/category_typeahead_field.dart';

/// 单位 + 类别组合区域
class UnitCategorySection extends StatelessWidget {
  final TextEditingController unitController;
  final FocusNode unitFocusNode;
  final List<Unit> units;
  final int? selectedUnitId;
  final ValueChanged<Unit> onUnitSelected;
  final VoidCallback onTapAddAuxiliary;
  final VoidCallback onTapChooseUnit;
  final String? Function() errorTextBuilder;
  final String? helperText;
  final VoidCallback onUnitClear;
  final VoidCallback onUnitSubmitted;

  final TextEditingController categoryController;
  final FocusNode categoryFocusNode;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<CategoryModel> onCategorySelected;
  final VoidCallback onTapChooseCategory;
  final VoidCallback onCategoryClear;
  final VoidCallback onCategorySubmitted;

  const UnitCategorySection({
    super.key,
    required this.unitController,
    required this.unitFocusNode,
    required this.units,
    required this.selectedUnitId,
    required this.onUnitSelected,
    required this.onTapAddAuxiliary,
    required this.onTapChooseUnit,
    required this.errorTextBuilder,
    required this.helperText,
    required this.onUnitClear,
    required this.onUnitSubmitted,
    required this.categoryController,
    required this.categoryFocusNode,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onTapChooseCategory,
    required this.onCategoryClear,
    required this.onCategorySubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnitTypeAheadField(
          controller: unitController,
          focusNode: unitFocusNode,
          units: units,
          selectedUnitId: selectedUnitId,
          onSelected: onUnitSelected,
          onTapAddAuxiliary: onTapAddAuxiliary,
          onTapChooseUnit: onTapChooseUnit,
          errorTextBuilder: errorTextBuilder,
          helperText: helperText,
          onClear: onUnitClear,
          onSubmitted: onUnitSubmitted,
        ),
        const SizedBox(height: 16),
        CategoryTypeAheadField(
          controller: categoryController,
          focusNode: categoryFocusNode,
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          onSelected: onCategorySelected,
          onTapChooseCategory: onTapChooseCategory,
          onClear: onCategoryClear,
          onSubmitted: onCategorySubmitted,
        ),
      ],
    );
  }
}
