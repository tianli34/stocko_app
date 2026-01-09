# 采购订单状态快速参考

## 状态枚举

```dart
enum PurchaseOrderStatus {
  draft,          // 草稿
  pendingInbound, // 待入库
  completed,      // 已完成（已入库）
  cancelled       // 已取消
}

enum PurchaseFlowType {
  oneClick,  // 一键入库（采购+入库同时完成）
  twoStep    // 分步操作（先采购，后入库）
}
```

## 4种状态的使用场景

### 1. draft（草稿）
- **场景：** 保存未完成的采购单
- **触发：** 用户创建采购单但未提交
- **状态：** 目前代码中未实现，预留给未来功能

### 2. pendingInbound（待入库）
- **场景：** 仅采购但未入库的订单
- **触发：** 调用 `processPurchaseOnly()` 方法
- **flowType：** `twoStep`
- **UI表现：** 显示"待入库"标签，支持左滑入库
- **下一步：** 执行入库 → `completed`

### 3. completed（已完成）
- **场景1：** 一键入库完成
  - **触发：** 调用 `processOneClickInbound()` 方法
  - **flowType：** `oneClick`
  - **撤销后：** → `cancelled`

- **场景2：** 分步入库完成
  - **触发：** 对 `pendingInbound` 订单调用 `processInboundFromPurchaseOrder()`
  - **flowType：** `twoStep`
  - **撤销后：** → `pendingInbound`

### 4. cancelled（已取消）
- **场景：** 一键入库订单被撤销
- **触发：** 对 `flowType = oneClick` 的订单撤销入库
- **特点：** 终态，不可恢复

## 状态流转图

```
[创建] → draft (未实现)

[创建] → pendingInbound (仅采购, twoStep)
           ↓
        [执行入库]
           ↓
        completed (twoStep)
           ↓
        [撤销入库]
           ↓
        pendingInbound

[创建] → completed (一键入库, oneClick)
           ↓
        [撤销入库]
           ↓
        cancelled
```

## 代码示例

### 一键入库

```dart
// 创建并入库
await inboundService.processOneClickInbound(
  shopId: 1,
  inboundItems: items,
  source: '采购入库',
  isPurchaseMode: true,
  supplierId: 1,
);

// 结果：
// status = completed
// flowType = oneClick
```

### 分步操作

```dart
// 第一步：仅采购
await inboundService.processPurchaseOnly(
  shopId: 1,
  inboundItems: items,
  supplierId: 1,
);

// 结果：
// status = pendingInbound
// flowType = twoStep

// 第二步：执行入库
await inboundService.processInboundFromPurchaseOrder(
  purchaseOrderId: orderId,
  shopId: 1,
);

// 结果：
// status = completed
// flowType = twoStep (保持不变)
```

### 撤销入库

```dart
await inboundService.revokeInbound(inboundReceiptId);

// 根据 flowType 决定结果：
// - oneClick → cancelled
// - twoStep → pendingInbound
```

## 查询示例

### 查询待入库订单

```dart
final pendingOrders = await (select(purchaseOrder)
  ..where((tbl) => tbl.status.equals('pendingInbound')))
  .get();
```

### 查询已完成订单

```dart
final completedOrders = await (select(purchaseOrder)
  ..where((tbl) => tbl.status.equals('completed')))
  .get();
```

### 查询一键入库的订单

```dart
final oneClickOrders = await (select(purchaseOrder)
  ..where((tbl) => tbl.flowType.equals('oneClick')))
  .get();
```

### 查询分步操作的订单

```dart
final twoStepOrders = await (select(purchaseOrder)
  ..where((tbl) => tbl.flowType.equals('twoStep')))
  .get();
```

## UI 判断

### 显示"待入库"标签

```dart
final isPendingInbound = order.status == PurchaseOrderStatus.pendingInbound;

if (isPendingInbound) {
  // 显示"待入库"标签
  // 支持左滑入库操作
}
```

### 列表排序

```dart
orders.sort((a, b) {
  // 待入库订单置顶
  final aIsPending = a.status == PurchaseOrderStatus.pendingInbound;
  final bIsPending = b.status == PurchaseOrderStatus.pendingInbound;
  
  if (aIsPending && !bIsPending) return -1;
  if (!aIsPending && bIsPending) return 1;
  
  // 同状态按创建时间降序
  return b.createdAt.compareTo(a.createdAt);
});
```

## 常见问题

### Q: completed 和 inbounded 有什么区别？
A: 在新版本中，`inbounded` 已被移除，统一使用 `completed` 表示已入库。通过 `flowType` 字段可以区分是一键入库还是分步入库。

### Q: 如何区分一键入库和分步入库？
A: 通过 `flowType` 字段：
- `oneClick`：一键入库
- `twoStep`：分步操作

### Q: 撤销入库后状态是什么？
A: 取决于 `flowType`：
- `oneClick` → `cancelled`（不可恢复）
- `twoStep` → `pendingInbound`（可以重新入库）

### Q: preset 状态去哪了？
A: `preset` 状态已被移除，因为它没有实际业务意义。旧数据会自动迁移为 `pendingInbound`。

### Q: draft 状态有什么用？
A: `draft` 状态预留给未来的草稿功能，目前代码中未实现。

---

**版本：** v33  
**更新时间：** 2024
