import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../application/provider/product_providers.dart';
import '../../application/category_notifier.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import '../../application/provider/barcode_providers.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import 'category_selection_screen.dart';
import 'add_auxiliary_unit_screen.dart';
import 'unit_selection_screen.dart';
import '../widgets/product_image_picker.dart';
import '../controllers/product_add_edit_controller.dart';

/// 货品添加/编辑页面
/// 表单页面，提交时调用 ref.read(productOperationsProvider.notifier).addProduct(...)
class ProductAddEditScreen extends ConsumerStatefulWidget {
  final Product? product; // 如果传入货品则为编辑模式，否则为新增模式

  const ProductAddEditScreen({super.key, this.product});

  @override
  ConsumerState<ProductAddEditScreen> createState() =>
      _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends ConsumerState<ProductAddEditScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单控制器
  // 类别和单位输入控制器，声明时初始化避免未赋值错误
  final TextEditingController _categoryController =
      TextEditingController(); // 类别输入控制器
  final TextEditingController _unitController =
      TextEditingController(); // 单位输入控制器
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _retailPriceController;
  late TextEditingController _promotionalPriceController;
  late TextEditingController _suggestedRetailPriceController; // 添加缺失的字段控制器
  late TextEditingController _stockWarningValueController;
  late TextEditingController _shelfLifeController;
  late TextEditingController _remarksController;

  // 表单状态
  String? _selectedCategoryId; // 添加类别选择状态
  String? _selectedUnitId; // 添加单位选择状态
  String? _selectedImagePath; // 添加图片路径状态
  List<ProductUnit>? _productUnits; // 存储单位配置数据
  List<Map<String, String>>? _auxiliaryUnitBarcodes; // 存储辅单位条码数据
  // 保质期单位相关
  String _shelfLifeUnit = 'months'; // 保质期单位：days, months, years
  final List<String> _shelfLifeUnitOptions = [
    'days',
    'months',
    'years',
  ]; // 批次管理开关
  bool _enableBatchManagement = false;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      ref.invalidate(unitEditFormProvider);
      _isInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // 如果是编辑模式，加载现有的主条码
    if (widget.product != null) {
      _loadExistingMainBarcode();
    }
  }

  void _initializeControllers() {
    final product = widget.product;
    // 其他文本控制器初始化
    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(text: ''); // 条码将在异步方法中加载
    _retailPriceController = TextEditingController(
      text: product?.retailPrice?.toString() ?? '',
    );
    _promotionalPriceController = TextEditingController(
      text: product?.promotionalPrice?.toString() ?? '',
    );
    _suggestedRetailPriceController = TextEditingController(
      text: product?.suggestedRetailPrice?.toString() ?? '',
    );
    // 初始化新增的控制器
    _stockWarningValueController = TextEditingController(
      text: product?.stockWarningValue?.toString() ?? '',
    );
    _shelfLifeController = TextEditingController(
      text: product?.shelfLife?.toString() ?? '',
    );
    _remarksController = TextEditingController(text: product?.remarks ?? '');
    _selectedCategoryId = product?.categoryId; // 初始化类别选择    // 初始化单位选择
    _selectedUnitId = product?.unitId; // 不设置默认值，允许为空
    _selectedImagePath = product?.image; // 初始化图片路径
    _shelfLifeUnit = product?.shelfLifeUnit ?? 'months'; // 正确初始化保质期单位
    _enableBatchManagement =
        product?.enableBatchManagement ?? false; // 初始化批次管理开关
  }

  /// 加载现有货品的主条码
  void _loadExistingMainBarcode() async {
    if (widget.product?.id == null) return;

    try {
      // 获取货品的所有单位配置
      final productUnitController = ref.read(
        productUnitControllerProvider.notifier,
      );
      final productUnits = await productUnitController
          .getProductUnitsByProductId(widget.product!.id);

      if (productUnits.isNotEmpty) {
        // 找到基础单位（换算率为1.0的单位）
        final baseProductUnit = productUnits.firstWhere(
          (unit) => unit.conversionRate == 1.0,
          orElse: () => productUnits.first,
        );

        // 获取基础单位的条码
        final barcodeController = ref.read(barcodeControllerProvider.notifier);
        final barcodes = await barcodeController.getBarcodesByProductUnitId(
          baseProductUnit.productUnitId,
        );

        if (barcodes.isNotEmpty && mounted) {
          // 使用第一个条码作为主条码
          setState(() {
            _barcodeController.text = barcodes.first.barcode;
          });
          print('🔧 ProductAddEditScreen: 加载现有主条码: ${barcodes.first.barcode}');
        }
      }
    } catch (e) {
      print('🔧 ProductAddEditScreen: 加载现有主条码失败: $e');
      // 加载失败不影响页面显示，只是条码字段保持空
    }
  }

  @override
  void dispose() {
    // 在 dispose 之前清除辅单位数据
    try {
      // 使用 mounted 检查确保 widget 仍然可用
      if (mounted) {
        ref.invalidate(unitEditFormProvider);
      }
    } catch (e) {
      print('🔧 ProductAddEditScreen: 清除辅单位数据失败: $e');
    }

    _nameController.dispose();
    _barcodeController.dispose();
    _retailPriceController.dispose();
    _promotionalPriceController.dispose();
    _suggestedRetailPriceController.dispose(); // 释放新增的控制器
    _stockWarningValueController.dispose();
    _shelfLifeController.dispose();
    _remarksController.dispose();
    _categoryController.dispose(); // 释放类别控制器
    _unitController.dispose(); // 释放单位控制器
    super.dispose();
  }

  /// 在页面即将销毁时清除辅单位数据
  void clearAuxiliaryUnitDataBeforeDispose() {
    try {
      // 在dispose之前调用，此时ref仍然可用
      ref.read(unitEditFormProvider.notifier).resetUnitEditForm();
      print('🔧 ProductAddEditScreen: 已清除保存的辅单位数据');
    } catch (e) {
      print('🔧 ProductAddEditScreen: 清除辅单位数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = ref.watch(productOperationsProvider);
    final categories = ref.watch(categoriesProvider); // 获取类别列表
    final unitsAsyncValue = ref.watch(allUnitsProvider); // 获取单位列表
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑货品' : '添加货品'),
        elevation: 0,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color.fromARGB(255, 95, 54, 244),
              ),
              onPressed: operationsState.isLoading
                  ? null
                  : _showDeleteConfirmation,
              tooltip: '删除货品',
            ),
        ],
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 货品图片选择器
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ProductImagePicker(
                              initialImagePath: _selectedImagePath,
                              onImageChanged: (imagePath) {
                                setState(() {
                                  _selectedImagePath = imagePath;
                                });
                              },
                              size: 120,
                              enabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      label: '名称',
                      hint: '请输入货品名称',
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _barcodeController,
                            label: '条码',
                            hint: '请输入货品条码',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: () => _scanBarcode(),
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            label: const Text('扫码'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 类别选择
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown(categories)),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _navigateToCategorySelection(context),
                          icon: const Icon(Icons.arrow_forward_ios),
                          tooltip: '管理类别',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // 单位选择
                    unitsAsyncValue.when(
                      data: (units) {
                        // 确保单位选择有效性
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _ensureValidUnitSelection(units);
                        });
                        return Row(
                          children: [
                            Expanded(child: _buildUnitTypeAhead(units)),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () =>
                                  _navigateToUnitSelection(context),
                              icon: const Icon(Icons.add),
                              tooltip: '添加辅单位',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _navigateToUnitList(),
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                              ),
                              tooltip: '选择单位',
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('加载单位中...')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _navigateToUnitSelection(context),
                            icon: const Icon(Icons.add),
                            tooltip: '添加辅单位',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      error: (error, stackTrace) => Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.shade300),
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
                            onPressed: () => _navigateToUnitSelection(context),
                            icon: const Icon(Icons.add),
                            tooltip: '添加辅单位',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _retailPriceController,
                      label: '零售价',
                      hint: '请输入零售价',
                      keyboardType: TextInputType.number,
                      prefixText: '¥ ',
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _promotionalPriceController,
                            label: '促销价',
                            hint: '请输入促销价',
                            keyboardType: TextInputType.number,
                            prefixText: '¥ ',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _suggestedRetailPriceController,
                            label: '建议零售价',
                            hint: '请输入建议零售价',
                            keyboardType: TextInputType.number,
                            prefixText: '¥ ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _stockWarningValueController,
                      label: '库存预警值',
                      hint: '请输入库存预警值',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // 保质期字段单独一行
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _shelfLifeController,
                            label: '保质期',
                            hint: '请输入保质期',
                            keyboardType: TextInputType.number,
                            icon: Icons.schedule,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: _buildShelfLifeUnitDropdown()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 备注
                    _buildTextField(
                      controller: _remarksController,
                      label: '备注',
                      hint: '请输入备注信息',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 80), // 为底部按钮留出空间
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: operationsState.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: operationsState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEdit ? '更新货品' : '添加货品',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    IconData? icon,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label不能为空';
              }
              return null;
            }
          : null,
    );
  }

  /// 构建类别TypeAhead输入框
  Widget _buildCategoryDropdown(List<Category> categories) {
    // 确保控制器在第一次构建时有正确的文本
    if (_categoryController.text.isEmpty && _selectedCategoryId != null) {
      final category = categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => const Category(id: '', name: ''),
      );
      if (category.id.isNotEmpty) {
        // 只需要在从外部数据源赋值时处理一次即可
        _categoryController.text = category.name.replaceAll(' ', '');
      }
    }

    return TypeAheadField<Category>(
      controller: _categoryController,
      suggestionsCallback: (pattern) {
        // pattern 来自控制器，已经被 formatter 处理过，所以不含空格
        if (pattern.isEmpty) {
          return Future.value([
            const Category(id: 'null', name: '未分类'),
            ...categories,
          ]);
        }

        final filtered = categories
            .where(
              (category) =>
                  // 为了匹配更准确，建议对数据源的 name 也做处理
                  category.name
                      .replaceAll(' ', '')
                      .toLowerCase()
                      .contains(pattern.toLowerCase()),
            )
            .toList();

        if (filtered.isEmpty || pattern == '未分类') {
          filtered.insert(0, const Category(id: 'null', name: '未分类'));
        }

        return Future.value(filtered);
      },
      itemBuilder: (context, Category suggestion) {
        return ListTile(title: Text(suggestion.name));
      },
      onSelected: (Category suggestion) {
        setState(() {
          if (suggestion.id == 'null') {
            _selectedCategoryId = null;
            _categoryController.text = '未分类';
          } else {
            _selectedCategoryId = suggestion.id;
            // 从建议赋值时，处理一次，以防数据源本身含空格
            _categoryController.text = suggestion.name.replaceAll(' ', '');
          }
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          // ⭐ 核心修改点在这里！⭐
          inputFormatters: [
            // 使用内置的 formatter，禁止输入任何空白字符
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          onChanged: (value) {
            // 此处的 value 已经不包含空格了
            if (_selectedCategoryId != null) {
              final categories = ref.read(categoriesProvider);
              final selectedCategory = categories.firstWhere(
                (cat) => cat.id == _selectedCategoryId,
                orElse: () => const Category(id: '', name: ''),
              );
              // 比较时，只需处理数据源的空格即可
              if (value != selectedCategory.name.replaceAll(' ', '') &&
                  value != '未分类') {
                setState(() {
                  _selectedCategoryId = null;
                });
              }
            }
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: '类别',
            hintText: '请输入或选择货品类别（可直接输入新类别）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            // 现在可以非常干净地直接使用 .text
            suffixIcon: _categoryController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _categoryController.clear();
                      });
                    },
                  )
                : null,
            helperText:
                _selectedCategoryId == null &&
                    _categoryController.text.isNotEmpty && // .trim() 也不需要了
                    _categoryController.text != '未分类'
                ? '将创建新类别: "${_categoryController.text}"'
                : null,
            helperStyle: TextStyle(color: Colors.green.shade600, fontSize: 12),
          ),
        );
      },
      emptyBuilder: (context) =>
          const Padding(padding: EdgeInsets.all(16.0), child: Text('未找到匹配的类别')),
    );
  }

  /// 构建单位TypeAhead输入框

  Widget _buildUnitTypeAhead(List<Unit> units) {
    // 确保控制器在第一次构建时有正确的文本
    if (_unitController.text.isEmpty && _selectedUnitId != null) {
      final unit = units.firstWhere(
        (u) => u.id == _selectedUnitId,
        orElse: () => Unit(id: '', name: ''),
      );
      if (unit.id.isNotEmpty) {
        // 在从外部数据源赋值时，处理一次空格
        _unitController.text = unit.name.replaceAll(' ', '');
      }
    }

    return TypeAheadField<Unit>(
      controller: _unitController,
      suggestionsCallback: (pattern) {
        // pattern 来自控制器，已经被 formatter 处理过，所以不含空格
        if (pattern.isEmpty) {
          return Future.value(units);
        }

        final filtered = units
            .where(
              (unit) =>
                  // 对数据源的 name 也做去空格处理，以实现更可靠的匹配
                  unit.name
                      .replaceAll(' ', '')
                      .toLowerCase()
                      .contains(pattern.toLowerCase()),
            )
            .toList();

        return Future.value(filtered);
      },
      itemBuilder: (context, Unit suggestion) {
        return ListTile(title: Text(suggestion.name));
      },
      onSelected: (Unit suggestion) {
        setState(() {
          _selectedUnitId = suggestion.id;
          // 从建议列表赋值时，处理一次，以防数据源本身含空格
          _unitController.text = suggestion.name.replaceAll(' ', '');
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          // ⭐ 核心优化：使用 Formatter 从源头禁止输入空格 ⭐
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          onChanged: (value) {
            // 此处的 value 已经不包含空格了，之前的 .trim() 不再需要

            // 如果输入为空，清除选择
            if (value.isEmpty) {
              if (_selectedUnitId != null) {
                setState(() {
                  _selectedUnitId = null;
                });
              }
              return;
            }

            // 查找完全匹配的单位
            final exactMatch = units.cast<Unit?>().firstWhere(
              // 比较时，对数据源也去空格，保证比较的公平性
              (unit) =>
                  unit!.name.replaceAll(' ', '').toLowerCase() ==
                  value.toLowerCase(),
              orElse: () => null,
            );

            if (exactMatch != null) {
              // 找到完全匹配的单位，自动选中
              if (_selectedUnitId != exactMatch.id) {
                setState(() {
                  _selectedUnitId = exactMatch.id;
                });
              }
            } else {
              // 没有找到匹配的单位，清除选择（允许创建新单位）
              if (_selectedUnitId != null) {
                setState(() {
                  _selectedUnitId = null;
                });
              }
            }
            // 触发UI更新（如helperText），无论逻辑如何，都调用一次setState
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: '基本单位 *',
            hintText: '请输入或选择基本单位（可直接输入新单位）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            // 注意：_getUnitValidationError 现在会接收一个不含空格的文本
            errorText: _getUnitValidationError(units),
            // helperText 的逻辑也变得更简洁
            helperText:
                _selectedUnitId == null && _unitController.text.isNotEmpty
                ? '将创建新单位: "${_unitController.text}"'
                : null,
            helperStyle: TextStyle(color: Colors.green.shade600, fontSize: 12),
            // suffixIcon 的判断也更直接
            suffixIcon: _unitController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedUnitId = null;
                        _unitController.clear();
                      });
                    },
                  )
                : null,
          ),
        );
      },
      emptyBuilder: (context) =>
          const Padding(padding: EdgeInsets.all(16.0), child: Text('未找到匹配的单位')),
    );
  } // 单位验证函数 - 只在表单提交时验证，不在输入时显示错误

  String? _getUnitValidationError(List<Unit> units) {
    // 不在输入时显示错误，只在表单提交时验证
    return null;
  }

  /// 构建保质期单位下拉选择器
  Widget _buildShelfLifeUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _shelfLifeUnit,
      decoration: InputDecoration(
        labelText: '单位',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _shelfLifeUnitOptions.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(_getShelfLifeUnitDisplayName(unit)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _shelfLifeUnit = value;
          });
        }
      },
    );
  }

  /// 获取保质期单位显示名称
  String _getShelfLifeUnitDisplayName(String unit) {
    switch (unit) {
      case 'days':
        return '天';
      case 'months':
        return '个月';
      case 'years':
        return '年';
      default:
        return unit;
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation() {
    if (widget.product?.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除货品 "${widget.product!.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final operations = ref.read(productOperationsProvider.notifier);

              // 执行删除操作
              await operations.deleteProduct(widget.product!.id);

              // 强制刷新列表确保UI立即更新
              ref.invalidate(allProductsProvider);

              // 添加短暂延迟后再次刷新，确保数据完全同步
              await Future.delayed(const Duration(milliseconds: 150));
              ref.invalidate(allProductsProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 导航到类别选择屏幕
  void _navigateToCategorySelection(BuildContext context) async {
    // 在导航前刷新类别数据，确保显示最新的类别列表
    await ref.read(categoryListProvider.notifier).loadCategories();

    final Category? selectedCategory = await Navigator.of(context)
        .push<Category>(
          MaterialPageRoute(
            builder: (context) => CategorySelectionScreen(
              selectedCategoryId: _selectedCategoryId,
              isSelectionMode: true,
            ),
          ),
        );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategoryId = selectedCategory.id;
      });
    }
  }

  /// 导航到单位列表页
  void _navigateToUnitList() async {
    final Unit? selectedUnit = await Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          selectedUnitId: _selectedUnitId,
          isSelectionMode: true,
        ),
      ),
    );

    if (selectedUnit != null) {
      setState(() {
        _selectedUnitId = selectedUnit.id;
        _unitController.text = selectedUnit.name;
      });
    }
  }

  /// 导航到单位编辑屏幕
  void _navigateToUnitSelection(BuildContext context) async {
    print('🔧 ProductAddEditScreen: 开始导航到单位编辑屏幕');
    print('🔧 ProductAddEditScreen: 货品ID = ${widget.product?.id}');
    print('🔧 ProductAddEditScreen: 当前选中的单位ID = $_selectedUnitId');
    print(
      '🔧 ProductAddEditScreen: 当前单位控制器文本 = ${_unitController.text}',
    ); // 获取基本单位信息（从前端输入框获取）
    String? baseUnitId = _selectedUnitId;
    String baseUnitName = _unitController.text.trim(); // 修改为非null类型

    // 如果没有选择单位，但输入了单位名称，需要先创建或查找单位
    if (baseUnitId == null && baseUnitName.isNotEmpty) {
      try {
        final allUnits = await ref.read(allUnitsProvider.future);
        final existingUnit = allUnits.firstWhere(
          (unit) => unit.name.toLowerCase() == baseUnitName.toLowerCase(),
          orElse: () => Unit(id: '', name: ''),
        );

        if (existingUnit.id.isNotEmpty) {
          baseUnitId = existingUnit.id;
          print('🔧 ProductAddEditScreen: 找到现有单位: ${existingUnit.name}');
        } else {
          // 创建新单位
          baseUnitId = 'unit_${DateTime.now().millisecondsSinceEpoch}';
          print('🔧 ProductAddEditScreen: 将创建新单位: $baseUnitName');
        }
      } catch (e) {
        print('🔧 ProductAddEditScreen: 处理单位信息失败: $e');
      }
    } // 如果没有输入单位名称，使用空的基础单位信息进入单位管理
    // 用户可以在单位管理页面中创建和配置单位
    if (baseUnitName.isEmpty) {
      baseUnitName = ''; // 空的基础单位名称，允许用户在单位管理页面中创建
      baseUnitId = null; // 没有预设的单位ID
      print('🔧 ProductAddEditScreen: 没有预设单位，进入单位管理页面创建');
    }

    print('🔧 ProductAddEditScreen: 传递给UnitEditScreen的基本单位信息:');
    print('🔧 ProductAddEditScreen: - 单位ID: $baseUnitId');
    print('🔧 ProductAddEditScreen: - 单位名称: $baseUnitName');

    final dynamic result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => UnitEditScreen(
          productId: widget.product?.id,
          baseUnitId: baseUnitId,
          baseUnitName: baseUnitName,
        ),
      ),
    );

    print('🔧 ProductAddEditScreen: 从UnitEditScreen返回的结果: $result');

    // 处理返回的单位配置结果
    if (result != null) {
      List<ProductUnit>? productUnits;
      List<Map<String, String>>? auxiliaryBarcodes;

      if (result is Map<String, dynamic>) {
        // 新格式：包含货品单位和条码信息
        productUnits = result['productUnits'] as List<ProductUnit>?;
        auxiliaryBarcodes =
            result['auxiliaryBarcodes'] as List<Map<String, String>>?;
      } else if (result is List<ProductUnit>) {
        // 旧格式：只有货品单位
        productUnits = result;
      }

      if (productUnits != null && productUnits.isNotEmpty) {
        print('🔧 ProductAddEditScreen: 接收到货品单位配置数据');

        // 保存单位配置数据到内存，等待提交时统一处理
        _productUnits = productUnits;
        _auxiliaryUnitBarcodes = auxiliaryBarcodes;

        // 找到基础单位（换算率为1.0的单位）
        final baseProductUnit = productUnits.firstWhere(
          (unit) => unit.conversionRate == 1.0,
          orElse: () => productUnits!.first, // 如果没有基础单位，使用第一个单位
        );

        print(
          '🔧 ProductAddEditScreen: 更新表单中的单位选择为: ${baseProductUnit.unitId}',
        );
        print(
          '🔧 ProductAddEditScreen: 辅单位条码数量: ${auxiliaryBarcodes?.length ?? 0}',
        );

        // 更新货品表单中的单位选择
        setState(() {
          _selectedUnitId = baseProductUnit.unitId;
        });

        // 显示成功提示
        ToastService.success('✅ 单位配置完成');
      }
    }
  }

  /// 扫描条码
  void _scanBarcode() async {
    try {
      // 使用通用扫码服务
      final String? barcode = await BarcodeScannerService.scanForProduct(
        context,
      );

      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _barcodeController.text = barcode;
        });

        // 显示成功提示
        ToastService.success('✅ 条码扫描成功: $barcode');
      }
    } catch (e) {
      // 显示错误提示
      ToastService.error('❌ 扫码失败: $e');
    }
  }

  /// 提交表单
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // 表单验证失败
    }

    // 单位验证 - 只在提交时验证
    if (_unitController.text.trim().isEmpty) {
      ToastService.error('❌ 基本单位不能为空');
      return;
    }

    // 辅单位换算率验证 - 检查用户在辅单位编辑页面中输入的原始数据
    final formState = ref.read(unitEditFormProvider);
    if (formState.auxiliaryUnits.isNotEmpty) {
      for (final auxUnit in formState.auxiliaryUnits) {
        // 检查辅单位名称不为空但换算率为空或无效的情况
        // 默认换算率为0
        if (auxUnit.unitName.trim().isNotEmpty && auxUnit.conversionRate <= 0) {
          ToastService.error('❌ 辅单位换算率不能为空');
          return;
        }
      }
    }

    try {
      // 根据保质期控制批次管理开关
      final shelfLife = int.tryParse(_shelfLifeController.text.trim());
      if (shelfLife != null && shelfLife > 0) {
        _enableBatchManagement = true;
      } else {
        _enableBatchManagement = false;
      }

      // 构建辅单位条码数据
      List<AuxiliaryUnitBarcodeData>? auxiliaryBarcodeData;
      if (_auxiliaryUnitBarcodes != null &&
          _auxiliaryUnitBarcodes!.isNotEmpty) {
        auxiliaryBarcodeData = _auxiliaryUnitBarcodes!
            .map(
              (item) => AuxiliaryUnitBarcodeData(
                productUnitId: item['productUnitId']!,
                barcode: item['barcode']!,
              ),
            )
            .toList();
      }

      // 构建表单数据
      final formData = ProductFormData(
        productId: widget.product?.id,
        name: _nameController.text.trim(),
        selectedCategoryId: _selectedCategoryId,
        newCategoryName: _categoryController.text.trim(),
        selectedUnitId: _selectedUnitId,
        newUnitName: _unitController.text.trim(),
        imagePath: _selectedImagePath,
        barcode: _barcodeController.text.trim(),
        retailPrice: double.tryParse(_retailPriceController.text.trim()),
        promotionalPrice: double.tryParse(
          _promotionalPriceController.text.trim(),
        ),
        suggestedRetailPrice: double.tryParse(
          _suggestedRetailPriceController.text.trim(),
        ),
        stockWarningValue: int.tryParse(
          _stockWarningValueController.text.trim(),
        ),
        shelfLife: int.tryParse(_shelfLifeController.text.trim()),
        shelfLifeUnit: _shelfLifeUnit,
        enableBatchManagement: _enableBatchManagement,
        remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
        productUnits: _productUnits,
        auxiliaryUnitBarcodes: auxiliaryBarcodeData,
      );

      // 使用控制器提交表单
      final controller = ref.read(productAddEditControllerProvider);
      final result = await controller.submitForm(formData);

      if (mounted) {
        if (result.success) {
          // 显示成功消息
          ToastService.success('✅ ${result.message ?? '操作成功'}');
          // 返回上一页
          context.pop();
        } else {
          // 显示错误消息
          ToastService.error('❌ ${result.message ?? '操作失败'}');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error('❌ 操作失败: $e');
      }
    }
  }

  /// 验证并确保单位选择的有效性
  void _ensureValidUnitSelection(List<Unit> units) {
    // 如果当前选择的单位ID不在单位列表中，清除选择
    if (_selectedUnitId != null &&
        !units.any((unit) => unit.id == _selectedUnitId)) {
      setState(() {
        _selectedUnitId = null;
        _unitController.clear();
      });
    }
    // 允许用户不选择单位，不强制设置默认值
  }
}
