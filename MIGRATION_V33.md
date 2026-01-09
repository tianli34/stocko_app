# 数据库迁移 v33：采购订单状态优化

## 变更概述

本次迁移优化了采购订单的状态管理，通过添加 `flowType` 字段来区分采购流程类型，并简化了状态枚举。

## 主要变更

### 1. 新增字段

**PurchaseOrder 表**
- 新增 `flow_type` 字段（TEXT，默认值：`twoStep`）
  - `oneClick`: 一键入库（采购+入库同时完成）
  - `twoStep`: 分步操作（先采购，后入库）

### 2. 状态枚举简化

**旧状态枚举：**
```dart
enum PurchaseOrderStatus { 
  preset,         // 预设（未使用）
  draft,          // 草稿（未使用）
  completed,      // 已完成
  pendingInbound, // 待入库
  inbounded       // 已入库
}
```

**新状态枚举：**
```dart
enum PurchaseOrderStatus { 
  draft,          // 草稿
  pendingInbound, // 待入库
  completed,      // 已完成（已入库）
  cancelled       // 已取消
}
```

### 3. 数据迁移规则

| 旧状态 | 新状态 | flowType | 说明 |
|--------|--------|----------|------|
| `preset` | `pendingInbound` | `twoStep` | 预设状态修正为待入库 |
| `draft` | `draft` | `twoStep` | 保持不变 |
| `completed` | `completed` | `oneClick` | 一键入库完成的订单 |
| `pendingInbound` | `pendingInbound` | `twoStep` | 分步操作的待入库订单 |
| `inbounded` | `completed` | `twoStep` | 分步入库完成的订单 |

## 业务逻辑变更

### 创建采购订单

**一键入库：**
```dart
PurchaseOrderCompanion(
  status: Value(PurchaseOrderStatus.completed),
  flowType: Value(PurchaseFlowType.oneClick),
)
```

**分步操作：**
```dart
// 第一步：创建采购单
PurchaseOrderCompanion(
  status: Value(PurchaseOrderStatus.pendingInbound),
  flowType: Value(PurchaseFlowType.twoStep),
)

// 第二步：执行入库
// 状态更新为 completed
```

### 撤销入库逻辑

根据 `flowType` 决定撤销后的状态：

```dart
final newStatus = order.flowType == PurchaseFlowType.oneClick
    ? PurchaseOrderStatus.cancelled      // 一键入库 → 取消
    : PurchaseOrderStatus.pendingInbound; // 分步操作 → 回到待入库
```

## 优势

1. **语义清晰**：状态表达"是什么"，flowType 表达"怎么来的"
2. **易于查询**：统计已入库订单只需查询 `status = completed`
3. **可追溯性**：通过 flowType 可以区分不同的采购流程
4. **扩展性强**：未来可以轻松添加新的流程类型

## 影响范围

### 修改的文件

1. `lib/core/database/purchase_orders_table.dart` - 表定义
2. `lib/core/database/database.dart` - 迁移逻辑
3. `lib/features/inbound/application/service/inbound_service.dart` - 业务逻辑
4. `lib/features/purchase/domain/model/purchase_order.dart` - 领域模型
5. `lib/features/purchase/presentation/screens/purchase_records_screen.dart` - UI（无需修改）

### 兼容性

- ✅ 自动迁移现有数据
- ✅ 向后兼容（旧状态自动转换）
- ✅ 无需手动数据处理

## 测试建议

1. 测试一键入库流程
2. 测试分步入库流程
3. 测试撤销入库（两种流程）
4. 验证数据迁移后的状态正确性
5. 验证 UI 显示正确（待入库标签等）

## 回滚方案

如需回滚到 v32，需要：
1. 删除 `flow_type` 列
2. 将 `completed` 状态根据业务逻辑拆分回 `completed` 和 `inbounded`
3. 恢复旧的状态枚举定义

**注意：** 不建议回滚，因为新设计更加合理和易维护。
