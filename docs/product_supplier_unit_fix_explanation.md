# 货品供应商关联表单位支持 - 重要修复说明

## 问题背景

在原始设计中，货品供应商关联表只考虑了商品ID和供应商ID的关联，忽略了一个重要的业务场景：**同一商品可能有多种包装单位，不同单位可能有不同的供应商和价格**。

## 实际业务场景

### 问题场景举例：可口可乐的供应

假设有商品"可口可乐"（product_id: "coke_001"），它有以下单位：

1. **瓶装** (unit_id: "bottle")
2. **箱装** (unit_id: "box") - 12瓶/箱  
3. **件装** (unit_id: "case") - 4箱/件

现实中的供应情况：

| 单位 | 供应商 | 价格 | 最小订购量 | 备注 |
|------|--------|------|------------|------|
| 瓶装 | 供应商A | 3.5元/瓶 | 100瓶 | 零散采购 |
| 箱装 | 供应商B | 42元/箱 | 10箱 | 批量采购，含包装 |
| 件装 | 供应商C | 168元/件 | 5件 | 大批量采购，托盘包装 |

### 原设计的问题

在原来的设计中，唯一约束是 `(product_id, supplier_id)`，这意味着：

❌ **无法区分单位**：无法记录供应商A按瓶供货3.5元，同时供应商B按箱供货42元  
❌ **数据冲突**：尝试为同一商品添加多个供应商的不同单位会违反唯一约束  
❌ **业务逻辑错误**：无法正确反映真实的供应关系  

## 解决方案

### 修复内容

1. **添加unit_id字段**：在表中新增`unit_id`字段，指定供货单位
2. **更新唯一约束**：改为 `(product_id, supplier_id, unit_id)` 三元组唯一
3. **扩展DAO方法**：支持按单位查询和管理供应商关系
4. **更新业务逻辑**：支持为每个单位设置独立的主要供应商

### 修复后的表结构

```sql
CREATE TABLE product_suppliers (
    id TEXT PRIMARY KEY,
    product_id TEXT NOT NULL,
    supplier_id TEXT NOT NULL,
    unit_id TEXT NOT NULL,        -- 新增字段
    supplier_product_code TEXT,
    supplier_product_name TEXT,
    supply_price REAL,
    minimum_order_quantity INTEGER,
    lead_time_days INTEGER,
    is_primary BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'active',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, supplier_id, unit_id)  -- 更新唯一约束
);
```

### 现在可以支持的场景

✅ **按单位区分供应商**：可口可乐瓶装由供应商A供应，箱装由供应商B供应  
✅ **不同单位不同价格**：瓶装3.5元/瓶，箱装42元/箱  
✅ **独立的主要供应商**：瓶装的主要供应商是A，箱装的主要供应商是B  
✅ **灵活的采购选择**：根据采购量选择最合适的单位和供应商  

## 数据迁移

由于这是一个结构性的重大变更，升级时会：

1. 删除旧的`product_suppliers`表
2. 创建新的表结构（包含`unit_id`字段）
3. 数据库schema版本升级到10

⚠️ **注意**：这会清空现有的货品供应商关联数据，升级后需要重新录入。

## API变更

### 新增方法

```dart
// 获取商品指定单位的供应商
getSuppliersByProductIdAndUnitId(String productId, String unitId)

// 获取商品指定单位的主要供应商
getPrimarySupplierByProductIdAndUnitId(String productId, String unitId)

// 设置商品指定单位的主要供应商
setPrimarySupplierForUnit(String productId, String unitId, String supplierId)

// 检查指定单位的供应商关联是否存在
existsProductSupplierWithUnit(String productId, String supplierId, String unitId)
```

### 方法签名变更

```dart
// 添加供应商关联时现在需要指定单位
addProductSupplier({
  required String productId,
  required String supplierId,
  required String unitId,     // 新增必需参数
  // ... 其他参数
})
```

## 最佳实践

1. **按业务需求选择单位**：根据实际采购场景选择合适的单位
2. **设置合理的主要供应商**：为常用单位设置主要供应商，方便快速采购
3. **定期维护价格信息**：不同单位的价格可能变化频率不同，需要分别维护
4. **利用单位换算**：结合`ProductUnitsTable`的换算率，可以比较不同单位的实际成本

## 影响范围

- ✅ 数据库表结构
- ✅ DAO层方法
- ✅ 示例代码
- ✅ 文档更新
- ⚠️ 需要更新使用该功能的UI层代码

这个修复确保了货品供应商关联表能够正确处理现实业务中的复杂供应关系，为采购管理提供了更准确和灵活的数据支持。
