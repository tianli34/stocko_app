import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../domain/model/product.dart';
import '../../domain/model/unit.dart';
import '../../application/provider/product_providers.dart';
import '../../application/category_notifier.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../widgets/sections/shelf_life_section.dart';
import '../widgets/sections/pricing_section.dart';
import '../widgets/inputs/app_text_field.dart';
// coordinator 逻辑已移动到 actions
import '../widgets/sections/basic_info_section.dart' show BasicInfoSection, ProductGroupOption;
import '../widgets/sections/unit_category_section.dart';
import '../widgets/product_form_action_bar.dart';
import '../widgets/multi_variant_input_section.dart';
import '../../application/provider/product_group_providers.dart';
import '../controllers/product_form_controllers.dart';
import '../state/product_form_ui_provider.dart';
import '../controllers/product_add_edit_actions.dart';
import '../../application/provider/unit_edit_form_providers.dart';

/// 货品添加/编辑页面
/// 表单页面，提交时调用 ref.read(productOperationsProvider.notifier).addProduct(...)
class ProductAddEditScreen extends ConsumerStatefulWidget {
  final ProductModel? product; // 如果传入货品则为编辑模式，否则为新增模式
  final String? initialBarcode; // 初始条码（从扫码进入时传入）

  const ProductAddEditScreen({super.key, this.product, this.initialBarcode});

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

  /// 清除表单验证错误
  void _clearValidationErrors() {
    // 保存当前所有控制器的值
    final savedValues = _c.saveAllValues();
    // 重置表单以清除验证错误
    _formKey.currentState?.reset();
    // 恢复所有控制器的值
    _c.restoreAllValues(savedValues);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // 新建模式下立即重置表单UI状态，避免沿用上一次未完成的选择
    if (widget.product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productFormUiProvider.notifier).reset();
      });
    }
    // 监听全局焦点变化，当焦点改变时清除验证错误
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(_onFocusChanged);
    });
    // 首帧后做必要的初始化（不要在这里重置 unitEditFormProvider，以便父页生命周期内多次进入子页可保留数据）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 每次打开父页即清空辅单位缓存，避免沿用上一次编辑的临时数据
      ref.read(unitEditFormProvider.notifier).resetUnitEditForm();
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

    // 监听单位输入框变化，当内容改变时检查是否需要清除选中状态
    _c.unitController.addListener(_onUnitTextChanged);

    // 如果有初始条码，填充到条码输入框并让名称输入框获得焦点
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _c.barcodeController.text = widget.initialBarcode!;
      // 延迟让名称输入框获得焦点，确保页面完全加载后再执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.nameFocusNode.requestFocus();
      });
    }

    // 条码监听将在 build 方法中处理，确保 ref.listen 在正确的上下文中使用
  }

  // 控制器初始化已移动到 ProductFormControllers

  /// 焦点变化回调
  void _onFocusChanged() {
    // 当焦点改变时清除验证错误
    _clearValidationErrors();
  }

  /// 单位输入框文本变化回调
  void _onUnitTextChanged() {
    final ui = ref.read(productFormUiProvider);
    final currentText = _c.unitController.text.trim();
    
    // 如果有选中的单位ID，检查输入框内容是否与选中单位匹配
    if (ui.selectedUnitId != null) {
      final unitsAsync = ref.read(allUnitsProvider);
      unitsAsync.whenData((units) {
        final selectedUnit = units.where((u) => u.id == ui.selectedUnitId).firstOrNull;
        // 如果输入框内容与选中单位不匹配，清除选中状态
        if (selectedUnit == null || selectedUnit.name != currentText) {
          ref.read(productFormUiProvider.notifier).setUnitId(null);
        }
      });
    }
  }

  @override
  void dispose() {
    // 移除焦点监听
    FocusManager.instance.removeListener(_onFocusChanged);
    // 移除单位输入框监听
    _c.unitController.removeListener(_onUnitTextChanged);
    // 在 dispose 前先获取 notifier 引用，确保能正确清理
    final unitNotifier = ref.read(unitEditFormProvider.notifier);
    final formNotifier = ref.read(productFormUiProvider.notifier);
    _c.dispose();
    super.dispose();
    // 异步清空辅单位临时状态和表单状态
    Future.microtask(() {
      unitNotifier.resetUnitEditForm();
      formNotifier.reset();
    });
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
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        // 清除验证错误
        _clearValidationErrors();
      },
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基础信息区（根据商品组开关状态切换名称输入模式）
                      _buildBasicInfoSection(ui, actions, isEdit),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      PricingSection(
                        retailPriceController: _c.retailPriceController,
                        promotionalPriceController:
                            _c.promotionalPriceController,
                        suggestedRetailPriceController:
                            _c.suggestedRetailPriceController,
                        retailPriceFocusNode: _c.retailPriceFocusNode,
                        onRetailPriceSubmitted: () =>
                            _c.shelfLifeFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _c.stockWarningValueController,
                        label: '库存预警值',
                        keyboardType: TextInputType.number,
                        focusNode: _c.stockWarningValueFocusNode,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      // 商品组功能
                      if (!isEdit) ...[
                        // 新增模式：商品组开关 + 变体列表
                        MultiVariantInputSection(
                          isProductGroupEnabled: ui.isProductGroupEnabled,
                          variants: ui.variants,
                          onProductGroupEnabledChanged: (enabled) {
                            ref
                                .read(productFormUiProvider.notifier)
                                .setProductGroupEnabled(enabled);
                            ref
                                .read(productFormUiProvider.notifier)
                                .setMultiVariantMode(enabled);
                            // 关闭时清除商品组选择
                            if (!enabled) {
                              ref
                                  .read(productFormUiProvider.notifier)
                                  .setGroupId(null);
                            }
                          },
                          onVariantsChanged: (variants) {
                            ref
                                .read(productFormUiProvider.notifier)
                                .setVariants(variants);
                          },
                          onScanBarcode: () async {
                            try {
                              final barcode = await BarcodeScannerService.scanForProduct(context);
                              return barcode;
                            } catch (e) {
                              ToastService.error('❌ 扫码失败: $e');
                              return null;
                            }
                          },
                        ),
                      ] else if (widget.product?.groupId != null) ...[
                        // 编辑模式：只读显示商品组信息（仅当商品属于某个组时显示）
                        _buildReadOnlyGroupInfo(context),
                      ],
                      const SizedBox(height: 16),
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
      // 注意：不要清空 unitController，保留用户输入的新单位名称
      // 用户可能输入了一个新单位名称，虽然没有对应的ID，但应该保留
    }
    // 允许用户不选择单位，不强制设置默认值
  }

  /// 构建基础信息区（根据商品组开关状态切换名称输入模式）
  Widget _buildBasicInfoSection(
    ProductFormUiState ui,
    ProductAddEditActions actions,
    bool isEdit,
  ) {
    final groupsAsync = ref.watch(allProductGroupsProvider);
    
    return groupsAsync.when(
      data: (groups) {
        // 转换为 ProductGroupOption 列表
        final groupOptions = groups
            .map((g) => ProductGroupOption(id: g.id, name: g.name))
            .toList();
        
        return BasicInfoSection(
          initialImagePath: ui.selectedImagePath,
          onImageChanged: (imagePath) {
            ref.read(productFormUiProvider.notifier).setImagePath(imagePath);
          },
          nameController: _c.nameController,
          nameFocusNode: _c.nameFocusNode,
          onNameSubmitted: () => _c.unitFocusNode.requestFocus(),
          barcodeController: _c.barcodeController,
          onScan: () => actions.scanBarcode(
            _c.barcodeController,
            nextFocus: _c.nameFocusNode,
          ),
          // 商品组模式（仅新增模式且开关开启时生效）
          isProductGroupEnabled: !isEdit && ui.isProductGroupEnabled,
          selectedGroupId: ui.selectedGroupId,
          productGroups: groupOptions,
          onGroupSelected: (groupId) {
            ref.read(productFormUiProvider.notifier).setGroupId(groupId);
          },
        );
      },
      loading: () => BasicInfoSection(
        initialImagePath: ui.selectedImagePath,
        onImageChanged: (imagePath) {
          ref.read(productFormUiProvider.notifier).setImagePath(imagePath);
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
      error: (e, _) => BasicInfoSection(
        initialImagePath: ui.selectedImagePath,
        onImageChanged: (imagePath) {
          ref.read(productFormUiProvider.notifier).setImagePath(imagePath);
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
    );
  }

  /// 构建只读商品组信息（编辑模式）
  Widget _buildReadOnlyGroupInfo(BuildContext context) {
    final groupsAsync = ref.watch(allProductGroupsProvider);
    
    return groupsAsync.when(
      data: (groups) {
        final group = groups.where((g) => g.id == widget.product?.groupId).firstOrNull;
        final groupName = group?.name ?? '未知商品组';
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '所属商品组',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.product?.variantName != null && 
                        widget.product!.variantName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '变体：${widget.product!.variantName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('加载商品组失败: $e'),
    );
  }

  /// 在编辑模式下回填单位和类别数据
  Future<void> _populateUnitAndCategoryData() async {
    if (widget.product == null || !mounted) return;

    // 设置图片路径
    if (widget.product!.image != null && widget.product!.image!.isNotEmpty) {
      ref
          .read(productFormUiProvider.notifier)
          .setImagePath(widget.product!.image);
    }

    // 设置单位ID和名称
    ref
        .read(productFormUiProvider.notifier)
        .setUnitId(widget.product!.baseUnitId);

    // 获取单位信息并设置控制器文本
    final unit = await ref
        .read(unitControllerProvider.notifier)
        .getUnitById(widget.product!.baseUnitId);
    if (unit != null && mounted) {
      setState(() {
        _c.unitController.text = unit.name.replaceAll(' ', '');
      });
    }

    // 设置类别ID和名称
    if (widget.product!.categoryId != null && mounted) {
      ref
          .read(productFormUiProvider.notifier)
          .setCategoryId(widget.product!.categoryId);

      // 确保类别列表是最新的
      await ref.read(categoryListProvider.notifier).loadCategories();

      // 从类别列表中获取类别名称
      final categories = ref.read(categoryListProvider).categories;
      final category = categories
          .where((c) => c.id == widget.product!.categoryId)
          .firstOrNull;

      if (category != null && mounted) {
        setState(() {
          _c.categoryController.text = category.name.replaceAll(' ', '');
        });
      } else if (mounted) {
        // 如果在类别列表中找不到对应的类别，可能是数据不一致的问题
        print('⚠️ [WARNING] 产品的类别ID ${widget.product!.categoryId} 在类别列表中不存在');
        setState(() {
          _c.categoryController.text = '未分类';
        });
      }
    } else if (mounted) {
      // 如果没有类别，设置为未分类
      setState(() {
        _c.categoryController.text = '未分类';
      });
    }

    // 设置商品组ID和变体名称
    if (widget.product!.groupId != null && mounted) {
      ref
          .read(productFormUiProvider.notifier)
          .setGroupId(widget.product!.groupId);
    }
    if (widget.product!.variantName != null && mounted) {
      ref
          .read(productFormUiProvider.notifier)
          .setVariantName(widget.product!.variantName);
    }
  }
}
