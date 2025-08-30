import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../domain/model/product.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/category.dart';
import '../../application/provider/product_providers.dart';
import '../../application/category_notifier.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import '../widgets/sections/shelf_life_section.dart';
import '../widgets/sections/pricing_section.dart';
import '../widgets/inputs/app_text_field.dart';
// coordinator 逻辑已移动到 actions
import '../widgets/sections/basic_info_section.dart';
import '../widgets/sections/unit_category_section.dart';
import '../widgets/product_form_action_bar.dart';
import '../controllers/product_form_controllers.dart';
import '../state/product_form_ui_provider.dart';
import '../controllers/product_add_edit_actions.dart';

/// 货品添加/编辑页面
/// 表单页面，提交时调用 ref.read(productOperationsProvider.notifier).addProduct(...)
class ProductAddEditScreen extends ConsumerStatefulWidget {
  final ProductModel? product; // 如果传入货品则为编辑模式，否则为新增模式

  const ProductAddEditScreen({super.key, this.product});

  @override
  ConsumerState<ProductAddEditScreen> createState() =>
      _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends ConsumerState<ProductAddEditScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单控制器
  // 控制器与焦点统一抽离管理
  late final ProductFormControllers _c;

  // UI 常量（可放置于组件内，不进 provider）
  final List<String> _shelfLifeUnitOptions = ['days', 'months', 'years'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.product?.id != null) {
        ref.invalidate(mainBarcodeProvider(widget.product!.id!));
      }
      // 在编辑模式下，回填单位和类别信息
      if (widget.product != null) {
        _populateUnitAndCategoryData();
      }
    });
    // 初始化表单控制器
    _c = ProductFormControllers()..init(widget.product);

    // 条码监听将在 build 方法中处理，确保 ref.listen 在正确的上下文中使用
  }

  // 控制器初始化已移动到 ProductFormControllers

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = ref.watch(productOperationsProvider);
    
    // 条码监听必须在 build 方法中处理
    if (widget.product?.id != null) {
      ref.listen<AsyncValue<String?>>(
        mainBarcodeProvider(widget.product!.id!),
        (previous, next) {
          next.whenData((barcode) {
            if (barcode != null && _c.barcodeController.text != barcode) {
              _c.barcodeController.text = barcode;
            } else if (barcode == null &&
                _c.barcodeController.text.isNotEmpty) {
              _c.barcodeController.clear();
            }
          });
        },
      );
    }
    final categoryState = ref.watch(categoryListProvider);
    final categories = categoryState.categories;
    final unitsAsyncValue = ref.watch(allUnitsProvider); // 获取单位列表
    final ui = ref.watch(productFormUiProvider);
    final isEdit = widget.product != null;
    final actions = ProductAddEditActions(
      ref: ref,
      context: context,
      productId: widget.product?.id,
    );
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? '编辑货品' : '添加货品'),
          elevation: 0,
          actions: [],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // 显示加载状态
              if (operationsState.isLoading) const LinearProgressIndicator(),

              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BasicInfoSection(
                        initialImagePath: ui.selectedImagePath,
                        onImageChanged: (imagePath) {
                          ref
                              .read(productFormUiProvider.notifier)
                              .setImagePath(imagePath);
                        },
                        nameController: _c.nameController,
                        nameFocusNode: _c.nameFocusNode,
                        onNameSubmitted: () => _c.unitFocusNode.requestFocus(),
                        barcodeController: _c.barcodeController,
                        onScan: () => actions.scanBarcode(
                          _c.barcodeController,
                          nextFocus: _c.nameFocusNode,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 单位 + 类别组合
                      unitsAsyncValue.when(
                        data: (units) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _ensureValidUnitSelection(units);
                          });
                          return UnitCategorySection(
                            unitController: _c.unitController,
                            unitFocusNode: _c.unitFocusNode,
                            units: units,
                            selectedUnitId: ui.selectedUnitId,
                            onUnitSelected: (u) {
                              ref
                                  .read(productFormUiProvider.notifier)
                                  .setUnitId(u.id);
                              _c.unitController.text = u.name.replaceAll(
                                ' ',
                                '',
                              );
                            },
                            onTapAddAuxiliary: () => actions.editAuxUnits(
                              currentUnitId: ui.selectedUnitId,
                              currentUnitName: _c.unitController.text,
                            ),
                            onTapChooseUnit: _navigateToUnitList,
                            errorTextBuilder: () =>
                                _getUnitValidationError(units),
                            helperText:
                                ui.selectedUnitId == null &&
                                    _c.unitController.text.isNotEmpty
                                ? '将创建新单位: "${_c.unitController.text}"'
                                : null,
                            onUnitClear: () {
                              ref
                                  .read(productFormUiProvider.notifier)
                                  .setUnitId(null);
                              _c.unitController.clear();
                            },
                            onUnitSubmitted: () =>
                                _c.categoryFocusNode.requestFocus(),
                            categoryController: _c.categoryController,
                            categoryFocusNode: _c.categoryFocusNode,
                            categories: categories,
                            selectedCategoryId: ui.selectedCategoryId,
                            onCategorySelected: (c) {
                              if (c.id == null) {
                                ref
                                    .read(productFormUiProvider.notifier)
                                    .setCategoryId(null);
                                _c.categoryController.text = '未分类';
                              } else {
                                ref
                                    .read(productFormUiProvider.notifier)
                                    .setCategoryId(c.id);
                                _c.categoryController.text = c.name.replaceAll(
                                  ' ',
                                  '',
                                );
                              }
                            },
                            onTapChooseCategory: () =>
                                _navigateToCategorySelection(context),
                            onCategoryClear: () {
                              ref
                                  .read(productFormUiProvider.notifier)
                                  .setCategoryId(null);
                              _c.categoryController.clear();
                            },
                            onCategorySubmitted: () =>
                                _c.retailPriceFocusNode.requestFocus(),
                          );
                        },
                        loading: () => Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(child: Text('加载单位中...')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => actions.editAuxUnits(
                                currentUnitId: ui.selectedUnitId,
                                currentUnitName: _c.unitController.text,
                              ),
                              icon: const Icon(Icons.add),
                              tooltip: '添加辅单位',
                            ),
                          ],
                        ),
                        error: (error, stackTrace) => Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    '加载失败',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => actions.editAuxUnits(
                                currentUnitId: ui.selectedUnitId,
                                currentUnitName: _c.unitController.text,
                              ),
                              icon: const Icon(Icons.add),
                              tooltip: '添加辅单位',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _c.retailPriceController,
                        label: '零售价',
                        keyboardType: TextInputType.number,
                        prefixText: '¥ ',
                        focusNode: _c.retailPriceFocusNode,
                        onFieldSubmitted: (_) =>
                            _c.shelfLifeFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: 44),
                      PricingSection(
                        promotionalPriceController:
                            _c.promotionalPriceController,
                        suggestedRetailPriceController:
                            _c.suggestedRetailPriceController,
                      ),
                      const SizedBox(height: 44),
                      AppTextField(
                        controller: _c.stockWarningValueController,
                        label: '库存预警值（默认值5）',
                        keyboardType: TextInputType.number,
                        focusNode: _c.stockWarningValueFocusNode,
                      ),
                      const SizedBox(height: 44),
                      // 保质期
                      ShelfLifeSection(
                        shelfLifeController: _c.shelfLifeController,
                        shelfLifeFocusNode: _c.shelfLifeFocusNode,
                        shelfLifeUnit: ui.shelfLifeUnit,
                        shelfLifeUnitOptions: _shelfLifeUnitOptions,
                        onShelfLifeUnitChanged: (val) {
                          ref
                              .read(productFormUiProvider.notifier)
                              .setShelfLifeUnit(val);
                        },
                        onSubmitted: _submitForm,
                      ),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ProductFormActionBar(
          isLoading: operationsState.isLoading,
          isEdit: isEdit,
          onSubmit: _submitForm,
        ),
      ),
    );
  }

  // 移除本地输入构建方法，改为使用 AppTextField 组件

  // 单位验证函数 - 只在表单提交时验证，不在输入时显示错误
  String? _getUnitValidationError(List<Unit> units) {
    return null;
  }

  /// 导航到类别选择屏幕
  void _navigateToCategorySelection(BuildContext context) async {
    final ui = ref.read(productFormUiProvider);
    final actions = ProductAddEditActions(
      ref: ref,
      context: context,
      productId: widget.product?.id,
    );
    await actions.chooseCategory(
      selectedCategoryId: ui.selectedCategoryId,
      onPicked: (c) {
        ref.read(productFormUiProvider.notifier).setCategoryId(c.id);
        _c.categoryController.text = c.name.replaceAll(' ', '');
        _c.retailPriceFocusNode.requestFocus();
      },
    );
  }

  /// 导航到单位列表页
  void _navigateToUnitList() async {
    final ui = ref.read(productFormUiProvider);
    final actions = ProductAddEditActions(
      ref: ref,
      context: context,
      productId: widget.product?.id,
    );
    await actions.chooseUnit(
      selectedUnitId: ui.selectedUnitId,
      onPicked: (u) {
        ref.read(productFormUiProvider.notifier).setUnitId(u.id);
        _c.unitController.text = u.name;
        _c.categoryFocusNode.requestFocus();
      },
    );
  }

  // 辅单位编辑已移至 actions.editAuxUnits，UI 侧直接调用

  // 扫码逻辑已移至 actions.scanBarcode

  /// 提交表单
  void _submitForm() async {
    final actions = ProductAddEditActions(
      ref: ref,
      context: context,
      productId: widget.product?.id,
    );
    await actions.submitForm(
      formKey: _formKey,
      nameController: _c.nameController,
      categoryController: _c.categoryController,
      unitController: _c.unitController,
      barcodeController: _c.barcodeController,
      retailPriceController: _c.retailPriceController,
      promotionalPriceController: _c.promotionalPriceController,
      suggestedRetailPriceController: _c.suggestedRetailPriceController,
      stockWarningValueController: _c.stockWarningValueController,
      shelfLifeController: _c.shelfLifeController,
      // remarksController: _c.remarksController,
      onSuccess: () {
        if (mounted) context.pop();
      },
      onError: (msg) {
        if (mounted) ToastService.error(msg);
      },
    );
  }

  /// 验证并确保单位选择的有效性
  void _ensureValidUnitSelection(List<Unit> units) {
    // 如果当前选择的单位ID不在单位列表中，清除选择
    final ui = ref.read(productFormUiProvider);
    final selectedUnitId = ui.selectedUnitId;
    if (selectedUnitId != null &&
        !units.any((unit) => unit.id == selectedUnitId)) {
      ref.read(productFormUiProvider.notifier).setUnitId(null);
      _c.unitController.clear();
    }
    // 允许用户不选择单位，不强制设置默认值
  }

  /// 在编辑模式下回填单位和类别数据
  Future<void> _populateUnitAndCategoryData() async {
    if (widget.product == null || !mounted) return;

    // 设置单位ID和名称
    if (widget.product!.baseUnitId != null) {
      ref.read(productFormUiProvider.notifier).setUnitId(widget.product!.baseUnitId);

      // 获取单位信息并设置控制器文本
      final unit = await ref.read(unitControllerProvider.notifier).getUnitById(widget.product!.baseUnitId!);
      if (unit != null && mounted) {
        setState(() {
          _c.unitController.text = unit.name.replaceAll(' ', '');
        });
      }
    }

    // 设置类别ID和名称
    if (widget.product!.categoryId != null && mounted) {
      ref.read(productFormUiProvider.notifier).setCategoryId(widget.product!.categoryId);

      // 从类别列表中获取类别名称
      final categories = ref.read(categoryListProvider).categories;
      final category = categories.where((c) => c.id == widget.product!.categoryId).firstOrNull ?? 
          const CategoryModel(name: '未分类');

      setState(() {
        _c.categoryController.text = category.name.replaceAll(' ', '');
      });
    } else if (mounted) {
      // 如果没有类别，设置为未分类
      setState(() {
        _c.categoryController.text = '未分类';
      });
    }
  }
}
