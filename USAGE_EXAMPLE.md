# 如何判断用户是否进入过辅单位编辑页面

## 实现说明

已在 `UnitEditFormState` 中添加了 `hasEnteredAuxUnitPage` 标志位，用于追踪用户是否进入过辅单位编辑页面。

## 使用方法

### 1. 检查用户是否进入过辅单位编辑页面

```dart
// 在任何 ConsumerWidget 或 ConsumerStatefulWidget 中
final formState = ref.watch(unitEditFormProvider);
bool hasEntered = formState.hasEnteredAuxUnitPage;

if (hasEntered) {
  // 用户已经进入过辅单位编辑页面
  print('用户已访问过辅单位编辑页面');
} else {
  // 用户还没有进入过辅单位编辑页面
  print('用户尚未访问辅单位编辑页面');
}
```

### 2. 在产品添加/编辑页面中使用

```dart
// 在 product_add_edit_screen.dart 中
@override
Widget build(BuildContext context) {
  final formState = ref.watch(unitEditFormProvider);
  
  // 判断是否需要显示提示信息
  if (!formState.hasEnteredAuxUnitPage) {
    // 显示"点击添加辅单位"的提示
  }
  
  // 或者根据是否进入过来改变按钮样式
  final buttonText = formState.hasEnteredAuxUnitPage 
      ? '编辑辅单位' 
      : '添加辅单位';
  
  return YourWidget();
}
```

### 3. 在提交表单时检查

```dart
// 在 product_add_edit_controller.dart 中
Future<ProductOperationResult> submitForm(ProductFormData data) async {
  final formState = ref.read(unitEditFormProvider);
  
  if (formState.hasEnteredAuxUnitPage) {
    // 用户进入过辅单位编辑页面
    if (formState.auxiliaryUnits.isEmpty) {
      // 进入过但没有添加任何辅单位
      print('用户访问了辅单位页面但未添加辅单位');
    } else {
      // 进入过并且添加了辅单位
      print('用户添加了 ${formState.auxiliaryUnits.length} 个辅单位');
    }
  } else {
    // 用户从未进入过辅单位编辑页面
    print('用户未访问辅单位编辑页面');
  }
  
  // 继续处理表单提交...
}
```

### 4. 重置标志位

当需要重置状态时（例如创建新产品或编辑完成后）：

```dart
// 重置整个表单状态（包括标志位）
ref.read(unitEditFormProvider.notifier).resetUnitEditForm();
```

## 工作原理

1. **标志位添加**：在 `UnitEditFormState` 中添加了 `hasEnteredAuxUnitPage` 布尔字段
2. **自动标记**：当用户进入 `AuxiliaryUnitEditScreen` 时，在 `initState` 中自动调用 `markAsEnteredAuxUnitPage()` 方法
3. **状态持久化**：该标志位会在整个产品编辑流程中保持，直到调用 `resetUnitEditForm()` 重置
4. **区分场景**：
   - `hasEnteredAuxUnitPage = false` + `auxiliaryUnits.isEmpty`：用户未访问辅单位页面
   - `hasEnteredAuxUnitPage = true` + `auxiliaryUnits.isEmpty`：用户访问了但未添加辅单位
   - `hasEnteredAuxUnitPage = true` + `auxiliaryUnits.isNotEmpty`：用户访问并添加了辅单位

## 注意事项

- 该标志位在 `resetUnitEditForm()` 时会被重置为 `false`
- 在编辑模式下，如果需要区分"本次编辑是否访问过"和"历史是否有辅单位数据"，可以结合数据库查询结果一起判断
- 标志位只表示"在当前编辑会话中是否进入过页面"，不会持久化到数据库
