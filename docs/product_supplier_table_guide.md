# 货品供应商关联表功能说明

## 概述

货品供应商关联表（`ProductSuppliersTable`）是一个用于建立商品和供应商之间多对多关系的数据库表。**重要特性：支持按单位区分供应商关系**，解决了同一商品不同包装单位可能有不同供应商和价格的业务需求。

通过这个表，您可以：

- 为一个商品的不同单位配置不同的供应商
- 为一个供应商配置多种商品的多种单位
- 为每个商品的每个单位设置主要供应商
- 管理不同单位的供货价格和供货信息

## 业务场景举例

以"可口可乐"商品为例：
- **按瓶供货**：供应商A，价格3.5元/瓶，最小订购100瓶
- **按箱供货**：供应商B，价格42元/箱（12瓶装），最小订购10箱
- **按件供货**：供应商C，价格168元/件（4箱装），最小订购5件

每种单位都可以有不同的供应商、价格和条件。

## 数据库表结构

### ProductSuppliersTable

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | TEXT | 主键，关联ID |
| product_id | TEXT | 商品ID，外键关联到products表 |
| supplier_id | TEXT | 供应商ID，外键关联到suppliers表 |
| unit_id | TEXT | **单位ID，外键关联到units表，指定供货单位** |
| supplier_product_code | TEXT | 供应商商品编号/型号（可空） |
| supplier_product_name | TEXT | 供应商商品名称（可空） |
| supply_price | REAL | 供货价格（可空） |
| minimum_order_quantity | INTEGER | 最小订购量（可空） |
| lead_time_days | INTEGER | 供货周期天数（可空） |
| is_primary | BOOLEAN | 是否为主要供应商，默认false |
| status | TEXT | 状态：active-有效，inactive-无效，默认active |
| remarks | TEXT | 备注（可空） |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 最后更新时间 |

### 特殊约束

- **联合唯一索引**：`(product_id, supplier_id, unit_id)` - 同一商品的同一供应商的同一单位只能有一条记录
- 主键：使用id字段作为主键

## 核心功能

### 1. ProductSupplierDao

数据访问对象，提供以下核心方法：

#### 查询方法
- `getAllProductSuppliers()` - 获取所有货品供应商关联记录
- `getSuppliersByProductId(String productId)` - 根据商品ID获取供应商
- `getProductsBySupplierId(String supplierId)` - 根据供应商ID获取商品
- `getPrimarySupplierByProductId(String productId)` - 获取商品的主要供应商
- `getActiveProductSuppliers()` - 获取有效的货品供应商关联

#### 修改方法
- `insertProductSupplier(ProductSuppliersTableCompanion entry)` - 添加货品供应商关联
- `updateProductSupplier(ProductSuppliersTableData entry)` - 更新货品供应商关联
- `deleteProductSupplier(String id)` - 删除货品供应商关联
- `setPrimarySupplier(String productId, String supplierId)` - 设置商品的主要供应商

#### 工具方法
- `existsProductSupplier(String productId, String supplierId)` - 检查关联是否存在
- `getProductSupplierById(String id)` - 根据ID获取关联记录

## 使用示例

### 1. 基本操作

```dart
// 获取数据库实例
final database = ref.read(databaseProvider);
final dao = database.productSupplierDao;

// 添加商品供应商关联
final companion = ProductSuppliersTableCompanion.insert(
  id: 'product001_supplier001_${DateTime.now().millisecondsSinceEpoch}',
  productId: 'product001',
  supplierId: 'supplier001',
  supplierProductCode: const Value('SUP001-ABC'),
  supplyPrice: const Value(15.50),
  isPrimary: const Value(true),
);
await dao.insertProductSupplier(companion);
```

### 2. 查询操作

```dart
// 获取商品的所有供应商
final suppliers = await dao.getSuppliersByProductId('product001');

// 获取商品的主要供应商
final primarySupplier = await dao.getPrimarySupplierByProductId('product001');

// 获取供应商的所有商品
final products = await dao.getProductsBySupplierId('supplier001');
```

### 3. 设置主要供应商

```dart
// 设置主要供应商（会自动将其他供应商设为非主要）
await dao.setPrimarySupplier('product001', 'supplier001');
```

## 业务场景

### 1. 商品管理
- 为新商品配置供应商
- 管理现有商品的供应商列表
- 设置主要供应商用于默认采购

### 2. 采购管理
- 根据商品查找可用供应商
- 比较不同供应商的价格和条件
- 选择最优供应商进行采购

### 3. 供应商管理
- 查看供应商可提供的商品
- 管理供应商的商品价格
- 评估供应商的商品覆盖范围

## 注意事项

1. **唯一性约束**：同一商品和供应商只能有一条关联记录
2. **主要供应商**：每个商品只能有一个主要供应商
3. **状态管理**：使用status字段管理关联的有效性
4. **价格管理**：supply_price字段用于记录供货价格，便于采购比价
5. **供货周期**：lead_time_days字段用于记录供货周期，便于采购计划

## 数据库迁移

新表已在数据库schema版本9中添加，升级时会自动创建该表。

## 相关文件

- `lib/core/database/product_suppliers_table.dart` - 表定义
- `lib/features/purchase/data/dao/product_supplier_dao.dart` - 数据访问对象
- `lib/examples/product_supplier_usage_example.dart` - 使用示例
- `lib/core/database/database.dart` - 数据库配置（已更新）

## 扩展功能

未来可考虑添加的功能：
- 供应商商品的历史价格记录
- 供应商评级和评价
- 自动供应商推荐
- 供货预警和提醒
