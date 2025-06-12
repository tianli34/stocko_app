# 单位选择屏幕使用指南

## 概述

`UnitSelectionScreen` 是一个功能完整的单位管理界面，支持选择单位、新增单位及删除单位操作。该屏幕设计遵循了项目中类别选择屏幕的模式，保持了一致的用户体验。

## 功能特性

### 1. 单位选择模式
- **单选功能**：支持从现有单位中选择一个单位
- **选择指示器**：通过颜色、字体粗细和选中图标清楚地显示当前选择
- **确认选择**：提供浮动操作按钮快速确认选择

### 2. 单位管理模式
- **完整的增删改功能**：支持新增、编辑、删除单位
- **表单验证**：输入验证确保数据有效性
- **重复检查**：防止添加重复的单位名称
- **确认对话框**：删除操作需要用户确认

### 3. 数据实时更新
- **Stream数据源**：使用 `allUnitsProvider` 实时监听数据变化
- **自动刷新**：数据变更后自动更新UI
- **下拉刷新**：支持手动刷新数据
- **状态管理**：集成操作状态指示和错误处理

## 使用方法

### 基本使用（选择模式）

```dart
import 'package:flutter/material.dart';
import '../screens/unit_selection_screen.dart';

class ProductForm extends StatefulWidget {
  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  Unit? selectedUnit;

  Future<void> _selectUnit() async {
    final result = await Navigator.of(context).push<Unit>(
      MaterialPageRoute(
        builder: (context) => const UnitSelectionScreen(
          isSelectionMode: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedUnit = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(selectedUnit?.name ?? '请选择单位'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _selectUnit,
        ),
      ],
    );
  }
}
```

### 管理模式使用

```dart
// 直接进入管理模式，不返回选择结果
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const UnitSelectionScreen(
      isSelectionMode: false,
    ),
  ),
);
```

### 带预选项的选择模式

```dart
Navigator.of(context).push<Unit>(
  MaterialPageRoute(
    builder: (context) => UnitSelectionScreen(
      selectedUnitId: currentUnit?.id, // 传入当前选中的单位ID
      isSelectionMode: true,
    ),
  ),
);
```

## 组件参数

### UnitSelectionScreen 参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| selectedUnitId | String? | ✗ | null | 初始选中的单位ID |
| isSelectionMode | bool | ✗ | true | 是否为选择模式，false为管理模式 |

## 界面元素

### 应用栏（AppBar）
- **标题**：根据模式显示"选择单位"或"单位管理"
- **返回按钮**：返回上一页面
- **添加按钮**：打开新增单位对话框

### 状态指示器
- **加载指示器**：操作进行时显示线性进度条
- **成功提示**：操作成功时显示绿色SnackBar
- **错误提示**：操作失败时显示红色SnackBar

### 单位列表
- **空状态**：无单位时显示友好的空状态界面
- **刷新功能**：支持下拉刷新
- **选择指示**：清楚地显示当前选择状态

### 浮动操作按钮
- **确认选择**：仅在选择模式且有选择时显示
- **快速操作**：点击直接返回选择结果

## 对话框

### 新增单位对话框
- **表单验证**：确保单位名称不为空
- **重复检查**：防止添加已存在的单位名称
- **自动聚焦**：输入框自动获得焦点

### 编辑单位对话框
- **预填数据**：显示当前单位名称
- **排除检查**：检查重复时排除当前单位
- **即时保存**：修改后立即保存

### 删除确认对话框
- **明确提示**：显示即将删除的单位名称
- **不可恢复警告**：提醒用户操作不可恢复
- **双重确认**：需要用户明确确认

## 状态管理

### Provider集成
```dart
// 监听单位列表
final unitsAsyncValue = ref.watch(allUnitsProvider);

// 监听操作状态
final controllerState = ref.watch(unitControllerProvider);

// 执行操作
final controller = ref.read(unitControllerProvider.notifier);
```

### 错误处理
- **网络错误**：显示重试按钮
- **验证错误**：即时显示验证消息
- **操作错误**：通过SnackBar显示错误信息

## 相关组件

- `UnitListTile`：单位列表项组件
- `SimpleUnitListTile`：简化的单位列表项组件
- `UnitController`：单位操作控制器
- `Unit`：单位数据模型
- `CustomErrorWidget`：错误提示组件
- `LoadingWidget`：加载状态组件

## 样式定制

组件使用 Material Design 规范，并遵循当前主题的颜色和字体设置。主要样式特点：

- **卡片样式**：使用 Card 组件，提供阴影效果
- **响应式设计**：适配不同屏幕尺寸
- **选择状态**：选中时使用主题色高亮显示
- **一致性**：与其他选择屏幕保持视觉一致性

## 注意事项

1. **权限控制**：删除操作会显示确认对话框
2. **数据验证**：所有输入都会进行验证
3. **状态同步**：操作后会自动刷新数据
4. **错误恢复**：提供重试机制处理临时错误
5. **用户体验**：提供丰富的视觉反馈和状态提示

## 示例场景

### 1. 产品表单中选择单位
在产品添加/编辑表单中集成单位选择功能

### 2. 独立的单位管理界面
作为系统设置的一部分，提供完整的单位管理功能

### 3. 库存管理中的单位选择
在库存相关功能中选择商品单位

### 4. 报表配置中的单位选择
在生成报表时选择显示单位
