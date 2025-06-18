# 主页按钮渐进式实现指南

## 概述

本指南描述了如何在 Stocko 库存管理系统中渐进式地添加主页按钮功能，而不影响现有的代码结构和功能。

## 渐进式实现策略

### 阶段1：基础组件创建 ✅

1. **创建主页按钮组件** (`/core/widgets/home_button.dart`)
   - 支持多种样式：elevated, floating, bottom, compact
   - 支持自定义文字和图标
   - 自动检测当前页面状态

2. **创建页面包装器** (`/core/widgets/page_with_home_button.dart`)
   - 可选择性地为页面添加主页按钮
   - 支持不同的按钮位置
   - 与现有浮动按钮兼容

### 阶段2：逐步在页面中添加 🔄

#### 2.1 最小侵入方式（推荐首先使用）

在现有页面中添加主页按钮的最简单方式：

```dart
// 1. 添加导入
import '../../../../core/widgets/home_button.dart';

// 2. 在页面底部添加按钮
// 在 Scaffold 的 body 的 Column 最后添加：
const HomeButton.compact(
  width: double.infinity,
  customLabel: '返回主页',
),
```

**优点：**
- 几乎不改变现有代码结构
- 每个页面可以选择不同的样式
- 出现问题容易回滚

**适用页面：**
- ✅ `/features/inbound/presentation/screens/create_inbound_screen.dart`（已完成）
- 🔄 `/features/product/presentation/screens/product_list_screen.dart`
- 🔄 `/features/inventory/presentation/screens/inventory_query_screen.dart`
- 🔄 `/features/database/presentation/screens/database_viewer_screen.dart`

#### 2.2 页面包装器方式（适合新页面或重构时使用）

```dart
// 替换现有的 Scaffold 结构
return PageWithHomeButton(
  appBar: AppBar(title: const Text('页面标题')),
  position: HomeButtonPosition.bottom,
  buttonStyle: HomeButtonStyle.bottom,
  child: YourPageContent(),
);
```

**优点：**
- 统一的样式管理
- 零侵入页面内容
- 易于全局调整

**适用场景：**
- 新建页面
- 大幅重构的页面
- 需要统一样式的页面组

### 阶段3：样式统一和优化 📋

#### 3.1 定义全局样式主题

```dart
// 在 theme_provider.dart 中添加主页按钮主题
class AppTheme {
  static const homeButtonTheme = HomeButtonTheme(
    primaryStyle: HomeButtonStyle.bottom,
    secondaryStyle: HomeButtonStyle.compact,
    // ... 其他样式配置
  );
}
```

#### 3.2 创建页面类型映射

```dart
// 不同类型的页面使用不同的主页按钮样式
enum PageType {
  form,      // 表单页面 - 使用 compact 样式
  list,      // 列表页面 - 使用 bottom 样式
  detail,    // 详情页面 - 使用 floating 样式
  settings,  // 设置页面 - 不显示主页按钮
}
```

### 阶段4：高级功能（可选） 🚀

#### 4.1 智能显示逻辑

```dart
// 根据导航栈深度决定是否显示主页按钮
class SmartHomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    // 如果在主页或只有一层导航，不显示主页按钮
    if (currentRoute == '/' || !canPop) {
      return const SizedBox.shrink();
    }
    
    return const HomeButton.compact();
  }
}
```

#### 4.2 用户偏好设置

```dart
// 让用户自定义主页按钮的显示方式
class HomeButtonPreferences {
  final bool showHomeButton;
  final HomeButtonStyle preferredStyle;
  final HomeButtonPosition preferredPosition;
  
  // 保存到 SharedPreferences
}
```

## 实施计划

### 第1周：核心组件
- [x] 创建 `HomeButton` 组件
- [x] 创建 `PageWithHomeButton` 包装器
- [x] 创建示例页面

### 第2周：主要页面添加
- [x] 入库创建页面（`create_inbound_screen.dart`）
- [ ] 产品列表页面（`product_list_screen.dart`）
- [ ] 库存查询页面（`inventory_query_screen.dart`）

### 第3周：次要页面添加
- [ ] 产品编辑页面（`product_add_edit_screen.dart`）
- [ ] 类别选择页面（`category_selection_screen.dart`）
- [ ] 数据库查看器（`database_viewer_screen.dart`）

### 第4周：优化和统一
- [ ] 样式统一
- [ ] 用户偏好设置
- [ ] 性能优化

## 回滚策略

如果需要移除主页按钮功能：

1. **移除导入语句**
2. **删除主页按钮相关代码**
3. **恢复原始的页面结构**

每个阶段都是独立的，可以单独回滚而不影响其他功能。

## 测试策略

### 单元测试
- 主页按钮组件的各种样式
- 导航逻辑的正确性
- 页面包装器的兼容性

### 集成测试
- 各页面间的导航流程
- 主页按钮在不同页面的表现
- 与现有功能的兼容性

### 用户测试
- 用户体验评估
- 按钮位置和样式的可用性
- 导航流程的直观性

## 优势总结

1. **渐进式**：可以逐个页面添加，不影响整体稳定性
2. **可逆性**：每个步骤都可以单独回滚
3. **灵活性**：不同页面可以使用不同的样式
4. **兼容性**：不破坏现有的代码结构
5. **可扩展**：未来可以轻松添加更多功能
