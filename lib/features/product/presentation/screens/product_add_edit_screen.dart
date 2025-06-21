import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../application/provider/product_providers.dart';
import '../../application/category_notifier.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/product_unit_providers.dart';
import 'category_selection_screen.dart';
import 'unit_edit_screen.dart';
import '../widgets/product_image_picker.dart';
import '../../application/category_service.dart';

/// 产品添加/编辑页面
/// 表单页面，提交时调用 ref.read(productControllerProvider.notifier).addProduct(...)
class ProductAddEditScreen extends ConsumerStatefulWidget {
  final Product? product; // 如果传入产品则为编辑模式，否则为新增模式

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
  // 保质期单位相关
  String _shelfLifeUnit = 'months'; // 保质期单位：days, months, years
  final List<String> _shelfLifeUnitOptions = ['days', 'months', 'years'];
  // 批次管理开关
  bool _enableBatchManagement = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final product = widget.product;
    // 其他文本控制器初始化
    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(productControllerProvider);
    final categories = ref.watch(categoriesProvider); // 获取类别列表
    final unitsAsyncValue = ref.watch(allUnitsProvider); // 获取单位列表
    final isEdit = widget.product != null;

    // 监听操作结果
    ref.listen<ProductControllerState>(productControllerProvider, (
      previous,
      next,
    ) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? '产品更新成功' : '产品添加成功'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // 操作成功后返回
      } else if (next.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? '操作失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑产品' : '添加产品'),
        elevation: 0,

        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: controllerState.isLoading
                  ? null
                  : _showDeleteConfirmation,
              tooltip: '删除产品',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 显示加载状态
            if (controllerState.isLoading) const LinearProgressIndicator(),

            // 表单内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 产品图片选择器
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
                      label: '产品名称',
                      hint: '请输入产品名称',
                      required: true,
                      icon: Icons.inventory_2,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _barcodeController,
                            label: '条码',
                            hint: '请输入产品条码',
                            icon: Icons.qr_code,
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
                          icon: const Icon(Icons.settings),
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
                              icon: const Icon(Icons.settings),
                              tooltip: '管理单位',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
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
                            icon: const Icon(Icons.settings),
                            tooltip: '管理单位',
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
                            icon: const Icon(Icons.settings),
                            tooltip: '管理单位',
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
                      icon: Icons.attach_money,
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
                            icon: Icons.local_offer,
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
                            icon: Icons.sell,
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
                      icon: Icons.warning_amber,
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

                    // 批次管理开关
                    Card(
                      child: SwitchListTile(
                        title: const Text('启用批次管理'),
                        value: _enableBatchManagement,
                        onChanged: (bool value) {
                          setState(() {
                            _enableBatchManagement = value;
                          });
                        },
                        secondary: const Icon(Icons.inventory_2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 备注
                    _buildTextField(
                      controller: _remarksController,
                      label: '备注',
                      hint: '请输入备注信息',
                      icon: Icons.note,
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
              onPressed: controllerState.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controllerState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEdit ? '更新产品' : '添加产品',
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
        _categoryController.text = category.name;
      }
    }

    return TypeAheadField<Category>(
      controller: _categoryController,
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) {
          return Future.value([
            const Category(id: 'null', name: '未分类'),
            ...categories,
          ]);
        }

        final filtered = categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(pattern.toLowerCase()),
            )
            .toList();

        // 如果输入的文本不匹配任何现有类别，添加"未分类"选项
        if (filtered.isEmpty || pattern == '未分类') {
          filtered.insert(0, const Category(id: 'null', name: '未分类'));
        }

        return Future.value(filtered);
      },
      itemBuilder: (context, Category suggestion) {
        return ListTile(
          leading: Icon(
            suggestion.id == 'null'
                ? Icons.not_listed_location
                : Icons.category,
            color: suggestion.id == 'null' ? Colors.grey : null,
          ),
          title: Text(suggestion.name),
        );
      },
      onSelected: (Category suggestion) {
        setState(() {
          if (suggestion.id == 'null') {
            _selectedCategoryId = null;
            _categoryController.text = '未分类';
          } else {
            _selectedCategoryId = suggestion.id;
            _categoryController.text = suggestion.name;
          }
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            // 如果用户修改了文本，清除已选择的类别
            if (_selectedCategoryId != null) {
              final categories = ref.read(categoriesProvider);
              final selectedCategory = categories.firstWhere(
                (cat) => cat.id == _selectedCategoryId,
                orElse: () => const Category(id: '', name: ''),
              );
              if (value != selectedCategory.name && value != '未分类') {
                setState(() {
                  _selectedCategoryId = null;
                });
              }
            }
            // 触发重建以更新suffixIcon的显示状态
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: '产品类别',
            hintText: '请输入或选择产品类别',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
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
                : const Icon(Icons.arrow_drop_down),
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
        _unitController.text = unit.name;
      }
    }

    return TypeAheadField<Unit>(
      controller: _unitController,
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) {
          return Future.value(units);
        }

        final filtered = units
            .where(
              (unit) => unit.name.toLowerCase().contains(pattern.toLowerCase()),
            )
            .toList();

        return Future.value(filtered);
      },
      itemBuilder: (context, Unit suggestion) {
        return ListTile(
          leading: const Icon(Icons.straighten),
          title: Text(suggestion.name),
        );
      },
      onSelected: (Unit suggestion) {
        setState(() {
          _selectedUnitId = suggestion.id;
          _unitController.text = suggestion.name;
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            final trimmedValue = value.trim();

            // 如果输入为空，清除选择
            if (trimmedValue.isEmpty) {
              if (_selectedUnitId != null) {
                setState(() {
                  _selectedUnitId = null;
                });
              }
              return;
            }
            // 查找完全匹配的单位
            final exactMatch = units.cast<Unit?>().firstWhere(
              (unit) => unit!.name.toLowerCase() == trimmedValue.toLowerCase(),
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
          },
          decoration: InputDecoration(
            labelText: '计量单位 *',
            hintText: '请输入或选择计量单位',
            prefixIcon: const Icon(Icons.straighten),
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
            errorText: _getUnitValidationError(units),
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
                : const Icon(Icons.arrow_drop_down),
          ),
        );
      },
      emptyBuilder: (context) =>
          const Padding(padding: EdgeInsets.all(16.0), child: Text('未找到匹配的单位')),
    );
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

  /// 提交表单
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 处理并保存新类别
    if (_selectedCategoryId == null &&
        _categoryController.text.trim().isNotEmpty &&
        _categoryController.text.trim() != '未分类') {
      final categoryService = ref.read(categoryServiceProvider);
      final newCategoryId = categoryService.generateCategoryId();
      await categoryService.addCategory(
        id: newCategoryId,
        name: _categoryController.text.trim(),
      );
      _selectedCategoryId = newCategoryId;
    }

    // 验证并处理单位选择
    if (_selectedUnitId == null || _selectedUnitId!.isEmpty) {
      if (_unitController.text.trim().isNotEmpty) {
        // 创建新单位
        final unitController = ref.read(unitControllerProvider.notifier);
        // 使用当前时间戳生成新单位ID
        final newUnitId = 'unit_${DateTime.now().millisecondsSinceEpoch}';
        final unitName = _unitController.text.trim();
        final newUnit = Unit(id: newUnitId, name: unitName);
        await unitController.addUnit(newUnit);
        _selectedUnitId = newUnitId;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择计量单位'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final controller = ref.read(productControllerProvider.notifier);
    final product = Product(
      id:
          widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(), // 为新产品生成ID
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim().isNotEmpty
          ? _barcodeController.text.trim()
          : null,
      sku: null,
      image: _selectedImagePath, // 添加图片路径
      specification: null,
      brand: null,
      categoryId: _selectedCategoryId, // 添加类别ID
      unitId: _selectedUnitId, // 添加单位ID
      retailPrice: _retailPriceController.text.trim().isNotEmpty
          ? double.tryParse(_retailPriceController.text.trim())
          : null,
      promotionalPrice: _promotionalPriceController.text.trim().isNotEmpty
          ? double.tryParse(_promotionalPriceController.text.trim())
          : null,
      suggestedRetailPrice:
          _suggestedRetailPriceController.text.trim().isNotEmpty
          ? double.tryParse(_suggestedRetailPriceController.text.trim())
          : null,
      // 添加缺失的字段
      stockWarningValue: _stockWarningValueController.text.trim().isNotEmpty
          ? int.tryParse(_stockWarningValueController.text.trim())
          : null,
      shelfLife: _shelfLifeController.text.trim().isNotEmpty
          ? int.tryParse(_shelfLifeController.text.trim())
          : null,
      shelfLifeUnit: _shelfLifeUnit, // 添加保质期单位
      enableBatchManagement: _enableBatchManagement, // 添加批次管理开关
      status: 'active', // 默认状态为active
      remarks: _remarksController.text.trim().isNotEmpty
          ? _remarksController.text.trim()
          : null,
      lastUpdated: DateTime.now(),
    );

    try {
      if (widget.product == null) {
        // 新增模式 - 调用 addProduct
        await controller.addProduct(product);
      } else {
        // 编辑模式 - 调用 updateProduct
        await controller.updateProduct(product);
      } // 产品保存成功后，保存单位配置
      await _saveProductUnits(product);
    } catch (e) {
      // 产品保存失败的处理由 ProductController 的监听器处理
      print('🔧 ProductAddEditScreen: 产品保存失败: $e');
    }
  }

  /// 保存产品单位配置
  /// 如果有单位配置数据则使用，否则为选中的单位创建基础配置
  Future<void> _saveProductUnits(Product product) async {
    try {
      final productUnitController = ref.read(
        productUnitControllerProvider.notifier,
      );

      List<ProductUnit> unitsToSave = [];

      if (_productUnits != null && _productUnits!.isNotEmpty) {
        // 如果有通过单位编辑屏幕配置的单位数据，使用这些数据
        print('🔧 ProductAddEditScreen: 使用已配置的单位数据');
        unitsToSave = _productUnits!
            .map(
              (unit) => ProductUnit(
                productUnitId: '${product.id}_${unit.unitId}',
                productId: product.id,
                unitId: unit.unitId,
                conversionRate: unit.conversionRate,
                barcode: unit.barcode, // 保留条码信息
                sellingPrice: unit.sellingPrice, // 保留建议零售价信息
                lastUpdated: DateTime.now(),
              ),
            )
            .toList();
      } else if (_selectedUnitId != null) {
        // 如果没有配置单位数据，但选择了单位，为选中的单位创建基础配置
        print('🔧 ProductAddEditScreen: 为选中单位创建基础配置');
        unitsToSave = [
          ProductUnit(
            productUnitId: '${product.id}_$_selectedUnitId',
            productId: product.id,
            unitId: _selectedUnitId!,
            conversionRate: 1.0, // 基础单位换算率为1.0
            barcode: null,
            sellingPrice: null,
            lastUpdated: DateTime.now(),
          ),
        ];
      }

      if (unitsToSave.isNotEmpty) {
        print('🔧 ProductAddEditScreen: 开始保存 ${unitsToSave.length} 个单位配置');
        await productUnitController.replaceProductUnits(
          product.id,
          unitsToSave,
        );
        print('🔧 ProductAddEditScreen: 单位配置保存成功');
      } else {
        print('🔧 ProductAddEditScreen: 没有单位配置需要保存');
      }
    } catch (e) {
      print('🔧 ProductAddEditScreen: 单位配置保存失败: $e');
      // 单位配置保存失败不应该影响产品保存的成功状态
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('产品保存成功，但单位配置保存失败: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation() {
    if (widget.product?.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除产品 "${widget.product!.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final controller = ref.read(productControllerProvider.notifier);

              // 执行删除操作
              await controller.deleteProduct(widget.product!.id);

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

  /// 导航到单位编辑屏幕
  void _navigateToUnitSelection(BuildContext context) async {
    print('🔧 ProductAddEditScreen: 开始导航到单位编辑屏幕');
    print('🔧 ProductAddEditScreen: 产品ID = ${widget.product?.id}');

    // 如果是编辑现有产品，获取产品的单位信息
    List<ProductUnit>? initialProductUnits;
    if (widget.product?.id != null) {
      print('🔧 ProductAddEditScreen: 尝试获取产品单位信息');
      try {
        final productUnitController = ref.read(
          productUnitControllerProvider.notifier,
        );
        initialProductUnits = await productUnitController
            .getProductUnitsByProductId(widget.product!.id);
        print(
          '🔧 ProductAddEditScreen: 获取到 ${initialProductUnits.length} 个产品单位',
        );
        for (final pu in initialProductUnits) {
          print(
            '🔧 ProductAddEditScreen: - 单位ID: ${pu.unitId}, 换算率: ${pu.conversionRate}',
          );
        }
      } catch (e) {
        print('🔧 ProductAddEditScreen: 获取产品单位信息失败: $e');
        // 如果获取失败，使用空列表
        initialProductUnits = null;
      }
    } else {
      print('🔧 ProductAddEditScreen: 新产品，跳过获取单位信息');
    }

    print(
      '🔧 ProductAddEditScreen: 传递给UnitEditScreen的初始数据: $initialProductUnits',
    );

    final List<ProductUnit>? result = await Navigator.of(context)
        .push<List<ProductUnit>>(
          MaterialPageRoute(
            builder: (context) => UnitEditScreen(
              productId: widget.product?.id,
              initialProductUnits: initialProductUnits,
            ),
          ),
        );

    print(
      '🔧 ProductAddEditScreen: 从UnitEditScreen返回的结果: $result',
    ); // 处理返回的单位配置结果
    if (result != null && result.isNotEmpty) {
      // 保存单位配置数据
      _productUnits = result;

      // 找到基础单位（换算率为1.0的单位）
      final baseProductUnit = result.firstWhere(
        (unit) => unit.conversionRate == 1.0,
        orElse: () => result.first, // 如果没有基础单位，使用第一个单位
      );

      print('🔧 ProductAddEditScreen: 更新表单中的单位选择为: ${baseProductUnit.unitId}');

      // 更新产品表单中的单位选择
      setState(() {
        _selectedUnitId = baseProductUnit.unitId;
      });

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单位配置完成'), backgroundColor: Colors.green),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('条码扫描成功: $barcode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫码失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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

  /// 获取单位输入框的验证错误信息
  String? _getUnitValidationError(List<Unit> units) {
    final inputText = _unitController.text.trim();

    // 如果输入为空，不显示错误
    if (inputText.isEmpty) {
      return null;
    }

    // 如果已选择有效单位，不显示错误
    if (_selectedUnitId != null &&
        units.any((unit) => unit.id == _selectedUnitId)) {
      return null;
    }
    // 如果输入的文本与现有单位名称完全匹配，不显示错误（允许创建新单位）
    final matchingUnit = units.cast<Unit?>().firstWhere(
      (unit) => unit!.name.toLowerCase() == inputText.toLowerCase(),
      orElse: () => null,
    );

    if (matchingUnit != null) {
      // 找到匹配的单位，但没有选中，自动选中它
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedUnitId != matchingUnit.id) {
          setState(() {
            _selectedUnitId = matchingUnit.id;
          });
        }
      });
      return null;
    }

    // 如果是新输入的单位名称，不显示错误（允许创建新单位）
    return null;
  }
}
