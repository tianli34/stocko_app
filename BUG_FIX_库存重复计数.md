# Bug修复：入库1件货品，库存显示2件

## 问题描述
当执行入库操作时，入库1件货品，但库存显示为2件，存在重复计数的问题。

## 根本原因
在 `inbound_service.dart` 的 `_writeInventoryRecords` 方法中，库存数量被更新了两次：

1. **第一次更新**：调用 `weightedAveragePriceService.updateWeightedAveragePrice()` 时
   - 该方法在计算移动加权平均价格的同时，也更新了库存数量
   - 代码位置：`weighted_average_price_service.dart` 第51行
   ```dart
   quantity: drift.Value(totalQuantity),  // totalQuantity = currentQuantity + inboundQuantity
   ```

2. **第二次更新**：调用 `inventoryService.inbound()` 时
   - 该方法通过 `incrementQuantity` 再次增加库存数量
   - 代码位置：`inventory_service.dart` 第47行

## 修复方案

### 1. 修改 `weighted_average_price_service.dart`
- 移除 `updateWeightedAveragePrice` 方法中对库存数量的更新
- 该方法现在只负责更新移动加权平均价格，不再更新库存数量
- 当库存记录不存在时，直接返回（库存记录由 `InventoryService.inbound` 创建）

### 2. 调整 `inbound_service.dart` 中的调用顺序
- 先调用 `inventoryService.inbound()` 创建/更新库存数量
- 再调用 `weightedAveragePriceService.updateWeightedAveragePrice()` 更新平均价格
- 这样确保在更新平均价格时，库存记录已经存在

## 修改的文件
1. `lib/features/inventory/application/service/weighted_average_price_service.dart`
2. `lib/features/inbound/application/service/inbound_service.dart`

## 职责划分
- **InventoryService.inbound()**：负责更新库存数量和记录库存流水
- **WeightedAveragePriceService.updateWeightedAveragePrice()**：只负责计算和更新移动加权平均价格

## 测试建议
1. 测试入库1件货品，验证库存显示为1件
2. 测试多次入库，验证库存累加正确
3. 测试批次管理的货品入库
4. 测试移动加权平均价格计算是否正确
