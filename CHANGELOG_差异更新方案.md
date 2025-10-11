# 产品单位更新方案优化

## 改动说明

将"更新货品"功能中的产品单位配置从"全删全插"方案改为"差异更新"方案。

## 修改文件

- `lib/features/product/data/repository/product_unit_repository.dart`

## 改动详情

### 原方案（全删全插）

```dart
Future<void> replaceProductUnits(int productId, List<UnitProduct> productUnits) async {
  await _productUnitDao.db.transaction(() async {
    // 1. 删除现有的产品单位配置
    await _productUnitDao.deleteProductUnitsByProductId(productId);
    
    // 2. 添加新的产品单位配置
    if (productUnits.isNotEmpty) {
      final companions = productUnits.map(_productUnitToCompanion).toList();
      await _productUnitDao.insertMultipleProductUnits(companions);
    }
  });
}
```

**问题：**
- 每次更新都会删除所有旧记录，再插入新记录
- 会导致产品单位的 ID 发生变化
- 如果有其他表（如条码表）引用了产品单位 ID，会导致关联关系断裂
- 性能较差，尤其是在单位数量较多时

### 新方案（差异更新）

```dart
Future<void> replaceProductUnits(int productId, List<UnitProduct> productUnits) async {
  await _productUnitDao.db.transaction(() async {
    // 1. 获取现有的产品单位配置
    final existingUnits = await _productUnitDao.getProductUnitsByProductId(productId);
    
    // 2. 构建映射表（使用 unitId + conversionRate 作为唯一标识）
    final existingMap = <String, UnitProductData>{};
    final newMap = <String, UnitProduct>{};
    
    // 3. 找出需要删除、更新和新增的记录
    final toDelete = <int>[];
    final toUpdate = <UnitProductCompanion>[];
    final toInsert = <UnitProductCompanion>[];
    
    // 4. 分别执行删除、更新和新增操作
    // ...
  });
}
```

**优势：**
- 只对变化的记录进行操作，保持未变化记录的 ID 不变
- 保持了与其他表的关联关系
- 性能更好，减少了不必要的数据库操作
- 更符合数据库最佳实践

## 差异识别逻辑

使用 `unitId` 作为产品单位的唯一标识（符合数据库表的唯一键约束 `{productId, unitId}`）：

1. **删除**：存在于旧列表但不在新列表中的记录
2. **更新**：同时存在于新旧列表中，但换算率、价格等字段发生变化的记录
3. **新增**：存在于新列表但不在旧列表中的记录
4. **保持不变**：同时存在于新旧列表中，且所有字段都相同的记录（跳过更新操作）

**注意**：根据数据库表定义，同一产品的同一单位只能有一个记录（唯一键约束：`{productId, unitId}`），因此使用 `unitId` 作为唯一标识是合理的。

## 测试建议

已创建测试用例文件：`test/features/product/data/repository/product_unit_repository_diff_update_test.dart`

测试场景包括：
1. ✅ 测试新增辅单位
2. ✅ 测试删除辅单位
3. ✅ 测试修改辅单位价格
4. ✅ 测试修改辅单位换算率
5. ✅ 测试同时新增、删除和修改辅单位（复杂场景）
6. ✅ 验证产品单位 ID 在更新后保持不变（对于未变化的记录）
7. 验证条码关联关系在更新后仍然有效（需要集成测试）

**手动测试步骤：**
1. 创建一个产品，添加辅单位和条码
2. 编辑该产品，修改辅单位价格，保存
3. 查看数据库，验证产品单位 ID 是否保持不变
4. 验证条码是否仍然关联到正确的产品单位

## 注意事项

- 该改动在事务中执行，保证了数据一致性
- 保留了详细的日志输出，便于调试
- 兼容现有的 API 接口，不需要修改调用方代码
