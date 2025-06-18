# 单位编辑功能改进 - 草稿自动保存

## 改进内容

### 问题分析
用户在单位编辑页面编辑后，再次进入该页面时无法看到之前的编辑内容，需要重新配置。

### 解决方案
实现了**草稿自动保存**功能，无需额外的保存草稿按钮，使用原有的提交按钮即可实现草稿保存。

## 功能特性

### 1. 自动草稿保存
- **实时保存**：用户在编辑基本单位、辅单位、换算率、条码、零售价时自动保存草稿
- **提交保存**：点击保存按钮时自动保存当前编辑状态
- **状态保持**：用户再次进入该页面时会显示上次的编辑内容

### 2. 智能加载逻辑
```dart
// 优先级：草稿数据 > 数据库数据 > 空状态
if (widget.productId != null) {
  final draftData = ref.read(unitEditDraftProvider.notifier).getDraft(widget.productId!);
  if (draftData != null && draftData.isNotEmpty) {
    // 使用草稿数据
    dataToLoad = draftData;
  } else {
    // 使用初始数据
    dataToLoad = widget.initialProductUnits;
  }
}
```

### 3. 用户体验优化
- **可视化提示**：有草稿数据时在页面顶部显示蓝色提示条
- **一键操作**：只需一个保存按钮，既保存数据又保留编辑状态
- **无感知存储**：草稿保存在内存中，应用重启前一直有效

## 技术实现

### 核心组件

#### 1. 草稿状态管理 (`unit_draft_providers.dart`)
```dart
class UnitEditDraftNotifier extends StateNotifier<UnitEditDraftState> {
  // 保存草稿
  void saveDraft(String productId, List<ProductUnit> units);
  
  // 获取草稿
  List<ProductUnit>? getDraft(String productId);
  
  // 清除草稿
  void clearDraft(String productId);
}
```

#### 2. 自动保存触发点
- 选择基本单位时
- 选择辅单位时
- 添加/删除辅单位时
- 修改换算率时
- 修改条码时（通过监听器）
- 修改零售价时（通过监听器）
- 点击保存按钮时

#### 3. 数据持久化策略
- **内存存储**：使用 Riverpod StateNotifier 在应用运行期间保持数据
- **按产品ID隔离**：不同产品的草稿数据互不干扰
- **覆盖更新**：新的编辑会覆盖旧的草稿

## 使用方式

### 对用户
1. **正常编辑**：在单位编辑页面进行任何编辑操作
2. **随时退出**：可以随时返回上级页面
3. **恢复编辑**：再次进入时会看到上次的编辑内容
4. **完成编辑**：点击保存按钮完成配置

### 对开发者
```dart
// 初始化时检查草稿
final draftData = ref.read(unitEditDraftProvider.notifier).getDraft(productId);

// 保存草稿
ref.read(unitEditDraftProvider.notifier).saveDraft(productId, units);

// 清除草稿（如需要）
ref.read(unitEditDraftProvider.notifier).clearDraft(productId);
```

## 优势对比

### 改进前
- ❌ 编辑内容丢失
- ❌ 需要重复配置
- ❌ 用户体验差

### 改进后  
- ✅ 自动保存编辑状态
- ✅ 再次进入恢复内容
- ✅ 无需额外操作
- ✅ 单按钮设计简洁

## 注意事项

1. **内存存储**：草稿数据存储在内存中，应用重启后会丢失
2. **产品范围**：只对有productId的产品有效，新产品创建时无效
3. **数据优先级**：草稿数据优先级高于数据库中的初始数据
4. **自动触发**：大部分编辑操作都会自动触发草稿保存

## 未来可扩展

- 可以将草稿数据持久化到本地存储（SharedPreferences）
- 可以添加草稿过期时间
- 可以为草稿添加时间戳显示
- 可以支持多个草稿版本的回退功能
