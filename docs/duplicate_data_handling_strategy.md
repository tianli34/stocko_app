# 重复数据处理策略文档

## 概述

在产品添加/编辑功能中，用户可以通过输入框直接输入新的类别和单位。为了防止数据库中出现重复记录，我们实现了完整的重复检查和处理机制。

## 处理策略

### 1. 类别重复处理

#### 检查机制
- **前端检查**：在用户输入时，实时检查现有类别列表
- **业务层检查**：`CategoryService.addCategory()` 调用 `isCategoryNameExists()` 检查
- **数据库约束**：添加复合唯一约束 `(name, parent_id)`

#### 处理流程
```dart
// 1. 首先检查内存中的类别列表
final existingCategory = categories.firstWhere(
  (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
  orElse: () => null,
);

if (existingCategory != null) {
  // 2. 找到现有类别，直接使用
  _selectedCategoryId = existingCategory.id;
  // 显示"使用现有类别"提示
} else {
  // 3. 不存在，尝试创建新类别
  try {
    await categoryService.addCategory(id: newId, name: categoryName);
    // 显示"新类别已创建"提示
  } catch (e) {
    // 4. 创建失败时的容错处理
    if (errorMessage.contains('类别名称已存在')) {
      // 再次查找现有类别并使用
      // 显示"类别已存在，使用现有类别"提示
    }
  }
}
```

### 2. 单位重复处理

#### 检查机制
- **前端检查**：在用户输入时，实时检查现有单位列表
- **业务层检查**：`UnitController.addUnit()` 调用 `getUnitByName()` 检查
- **数据库约束**：添加唯一约束 `name UNIQUE`

#### 处理流程
```dart
// 1. 首先检查内存中的单位列表
final existingUnit = units.firstWhere(
  (unit) => unit.name.toLowerCase() == unitName.toLowerCase(),
  orElse: () => null,
);

if (existingUnit != null) {
  // 2. 找到现有单位，直接使用
  _selectedUnitId = existingUnit.id;
  // 显示"使用现有单位"提示
} else {
  // 3. 不存在，尝试创建新单位
  try {
    await unitController.addUnit(newUnit);
    // 显示"新单位已创建"提示
  } catch (e) {
    // 4. 创建失败时的容错处理
    if (errorMessage.contains('单位名称已存在') || 
        errorMessage.contains('UNIQUE constraint failed')) {
      // 再次查找现有单位并使用
      // 显示"单位已存在，使用现有单位"提示
    }
  }
}
```

## 用户体验设计

### 1. 视觉提示
- **绿色提示**：创建新记录成功
- **蓝色提示**：使用现有记录
- **红色提示**：操作失败
- **Helper文本**：输入框下方显示"将创建新类别/单位"

### 2. 错误处理
- **优雅降级**：即使出现意外错误，也尝试查找并使用现有记录
- **清晰反馈**：明确告知用户当前操作的结果
- **防止中断**：重复数据不应阻止产品保存流程

### 3. 性能优化
- **内存优先**：优先检查已加载的数据列表
- **异步处理**：数据库操作不阻塞UI
- **批量更新**：操作完成后统一刷新相关provider

## 数据库设计

### 1. 约束设置
```sql
-- 单位表：单位名称全局唯一
CREATE UNIQUE INDEX idx_units_name_unique ON units(name);

-- 类别表：同一父级下类别名称唯一
CREATE UNIQUE INDEX idx_categories_name_parent_unique 
ON categories(name, COALESCE(parent_id, 'null'));
```

### 2. 迁移策略
- 清理现有重复数据
- 添加唯一约束
- 验证数据完整性

## 测试场景

### 1. 正常场景
- [x] 输入新类别名称，成功创建
- [x] 输入新单位名称，成功创建
- [x] 产品保存成功，关联新创建的类别和单位

### 2. 重复场景
- [x] 输入已存在的类别名称，自动使用现有类别
- [x] 输入已存在的单位名称，自动使用现有单位
- [x] 显示相应的用户提示信息

### 3. 异常场景
- [x] 数据库约束冲突时的容错处理
- [x] 网络错误时的重试机制
- [x] 并发创建时的冲突解决

## 最佳实践

1. **双重检查**：内存检查 + 数据库检查
2. **用户友好**：清晰的提示信息和视觉反馈
3. **数据安全**：数据库约束确保数据完整性
4. **性能优化**：减少不必要的数据库查询
5. **错误恢复**：即使出错也要尽可能完成用户的操作意图

## 维护建议

1. **定期清理**：监控并清理可能的重复数据
2. **日志记录**：记录重复处理的详细日志便于调试
3. **用户教育**：在UI中提供使用指导
4. **数据监控**：设置重复数据的监控告警

这种设计确保了系统的健壮性，同时为用户提供了流畅的使用体验。
