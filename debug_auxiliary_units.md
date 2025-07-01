# 辅单位问题排查步骤

## 1. 检查辅单位数据构建
在 `add_auxiliary_unit_screen.dart` 的 `_buildProductUnits()` 方法中添加详细日志：

```dart
List<ProductUnit> _buildProductUnits() {
  print('🔍 [DEBUG] 开始构建产品单位列表...');
  print('🔍 [DEBUG] 基本单位ID: ${widget.baseUnitId}');
  print('🔍 [DEBUG] 辅单位数量: ${_auxiliaryUnits.length}');
  
  final List<ProductUnit> productUnits = [];

  // 添加基本单位
  if (widget.baseUnitId != null) {
    final baseUnit = ProductUnit(
      productUnitId: '${widget.productId ?? 'new'}_${widget.baseUnitId!}',
      productId: widget.productId ?? 'new',
      unitId: widget.baseUnitId!,
      conversionRate: 1.0,
    );
    productUnits.add(baseUnit);
    print('🔍 [DEBUG] 添加基本单位: ${baseUnit.toJson()}');
  }

  // 添加辅单位
  for (int i = 0; i < _auxiliaryUnits.length; i++) {
    final aux = _auxiliaryUnits[i];
    print('🔍 [DEBUG] 处理辅单位 $i:');
    print('  - 单位对象: ${aux.unit?.toJson()}');
    print('  - 换算率: ${aux.conversionRate}');
    print('  - 单位名称: ${aux.unitController.text}');
    
    if (aux.unit != null && aux.conversionRate > 0) {
      final auxUnit = ProductUnit(
        productUnitId: '${widget.productId ?? 'new'}_${aux.unit!.id}',
        productId: widget.productId ?? 'new',
        unitId: aux.unit!.id,
        conversionRate: aux.conversionRate,
        sellingPrice: aux.retailPriceController.text.trim().isNotEmpty
            ? double.tryParse(aux.retailPriceController.text.trim())
            : null,
        lastUpdated: DateTime.now(),
      );
      productUnits.add(auxUnit);
      print('🔍 [DEBUG] 添加辅单位: ${auxUnit.toJson()}');
    } else {
      print('🔍 [DEBUG] 跳过无效辅单位 $i: unit=${aux.unit?.name}, rate=${aux.conversionRate}');
    }
  }
  
  print('🔍 [DEBUG] 构建完成，总计 ${productUnits.length} 个产品单位');
  return productUnits;
}
```

## 2. 检查产品编辑页面接收数据
在 `product_add_edit_screen.dart` 的 `_navigateToUnitSelection` 方法中：

```dart
// 在处理返回结果的地方添加日志
if (result != null) {
  print('🔍 [DEBUG] 从辅单位页面返回的原始数据: $result');
  
  List<ProductUnit>? productUnits;
  List<Map<String, String>>? auxiliaryBarcodes;

  if (result is Map<String, dynamic>) {
    productUnits = result['productUnits'] as List<ProductUnit>?;
    auxiliaryBarcodes = result['auxiliaryBarcodes'] as List<Map<String, String>>?;
    
    print('🔍 [DEBUG] 解析后的产品单位数量: ${productUnits?.length ?? 0}');
    print('🔍 [DEBUG] 解析后的条码数量: ${auxiliaryBarcodes?.length ?? 0}');
    
    if (productUnits != null) {
      for (int i = 0; i < productUnits.length; i++) {
        print('🔍 [DEBUG] 产品单位 $i: ${productUnits[i].toJson()}');
      }
    }
  }
}
```

## 3. 检查控制器处理
在 `product_add_edit_controller.dart` 的 `_saveProductUnits` 方法中：

```dart
Future<void> _saveProductUnits(Product product, List<ProductUnit>? units) async {
  print('🔍 [DEBUG] 开始保存产品单位配置');
  print('🔍 [DEBUG] 产品ID: ${product.id}');
  print('🔍 [DEBUG] 传入的单位数量: ${units?.length ?? 0}');
  
  final ctrl = ref.read(productUnitControllerProvider.notifier);
  final list = (units != null && units.isNotEmpty)
      ? units
      : [
          ProductUnit(
            productUnitId: 'pu_${product.id}_${product.unitId!}',
            productId: product.id,
            unitId: product.unitId!,
            conversionRate: 1.0,
          ),
        ];
        
  print('🔍 [DEBUG] 最终要保存的单位数量: ${list.length}');
  for (int i = 0; i < list.length; i++) {
    print('🔍 [DEBUG] 单位 $i: ${list[i].toJson()}');
  }
  
  await ctrl.replaceProductUnits(product.id, list);
  print('🔍 [DEBUG] 产品单位配置保存完成');
}
```

## 4. 检查仓储层执行
在 `product_unit_repository.dart` 的 `replaceProductUnits` 方法中已有日志，确保查看控制台输出。

## 5. 检查数据库表结构
确认产品单位表是否存在且结构正确：

```sql
-- 检查表是否存在
SELECT name FROM sqlite_master WHERE type='table' AND name='product_units_table';

-- 检查表结构
PRAGMA table_info(product_units_table);

-- 检查数据是否写入
SELECT * FROM product_units_table WHERE product_id = 'your_product_id';
```

## 6. 常见问题及解决方案

### 问题1: 辅单位对象为null
**原因**: 在 `_onAuxiliaryUnitNameChanged` 方法中，新单位创建失败
**解决**: 检查单位创建逻辑，确保新单位正确保存到数据库

### 问题2: 换算率为0或负数
**原因**: 用户输入验证不当或数据转换错误
**解决**: 加强输入验证，确保换算率大于0

### 问题3: 产品单位ID重复
**原因**: ID生成逻辑有问题
**解决**: 使用更可靠的ID生成策略

### 问题4: 事务回滚
**原因**: 数据库操作中某个步骤失败导致整个事务回滚
**解决**: 检查所有数据库操作的错误处理

## 7. 快速验证方法

1. **在辅单位编辑页面**：
   - 添加一个辅单位
   - 设置换算率
   - 点击返回按钮
   - 查看控制台日志，确认数据构建正确

2. **在产品编辑页面**：
   - 查看是否收到辅单位数据
   - 提交表单
   - 查看控制台日志，确认数据传递正确

3. **检查数据库**：
   - 使用数据库查看工具检查 `product_units_table` 表
   - 确认辅单位记录是否存在

## 8. 临时解决方案

如果问题紧急，可以在 `_saveProductUnits` 方法中添加强制保存逻辑：

```dart
// 临时调试：强制保存辅单位数据
if (units != null && units.isNotEmpty) {
  for (final unit in units) {
    try {
      await ctrl.addProductUnit(unit);
      print('🔍 [DEBUG] 强制保存单位成功: ${unit.productUnitId}');
    } catch (e) {
      print('🔍 [DEBUG] 强制保存单位失败: $e');
    }
  }
}
```