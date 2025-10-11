# Implementation Plan

- [x] 1. 创建聚合数据模型和辅助类






  - 创建AggregatedInventoryItem和InventoryDetail数据类
  - 实现数据转换和计算逻辑（总库存、剩余保质期等）
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2_

- [x] 2. 实现Service层的聚合方法





  - 在InventoryQueryService中添加getAggregatedInventory方法
  - 实现按productId分组的聚合逻辑
  - 实现详细记录列表的构建逻辑
  - 处理批次信息缺失的情况
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3_

- [x] 2.1 编写Service层聚合方法的单元测试






  - 测试聚合逻辑的正确性
  - 测试总库存计算
  - 测试详细记录列表构建
  - 测试边界情况（无批次、无店铺等）
  - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [x] 3. 修改Provider支持聚合模式





  - 修改inventoryQueryProvider判断是否需要聚合
  - 实现根据shopFilter切换数据获取方式
  - 实现聚合数据的排序逻辑
  - 保持原始数据模式的排序逻辑不变
  - _Requirements: 1.1, 3.1, 3.2, 3.3, 5.1, 5.2_

- [x] 3.1 编写Provider层的单元测试







  - 测试未筛选店铺时返回聚合数据
  - 测试筛选店铺时返回原始数据
  - 测试排序功能在两种模式下的正确性
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 4. 创建AggregatedInventoryCard组件





  - 实现可展开/收起的卡片组件
  - 实现收起状态的UI（显示总库存）
  - 实现展开状态的UI（显示详细列表）
  - 实现展开/收起动画效果
  - 实现详细记录行的布局（店铺、批次、保质期、数量）
  - 实现保质期颜色预警逻辑
  - _Requirements: 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 4.1, 4.2, 4.3, 4.4_

- [x] 4.1 编写AggregatedInventoryCard的Widget测试






  - 测试收起状态的显示
  - 测试展开/收起交互
  - 测试详细列表的渲染
  - 测试保质期颜色显示
  - _Requirements: 1.3, 1.4, 2.1, 2.2, 4.1, 4.2, 4.3, 4.4_

- [x] 5. 修改InventoryQueryScreen支持两种展示模式





  - 修改build方法判断当前展示模式
  - 实现聚合模式的ListView构建（使用AggregatedInventoryCard）
  - 保持原始模式的ListView不变
  - 修改汇总统计逻辑适配聚合数据
  - 确保筛选条件变化时正确切换模式
  - _Requirements: 1.1, 3.1, 3.2, 3.3, 3.4, 5.1, 5.2, 5.3, 5.4_

- [x] 5.1 编写InventoryQueryScreen的Widget测试






  - 测试未筛选店铺时显示聚合卡片
  - 测试筛选店铺时显示原始卡片
  - 测试切换筛选条件时的模式切换
  - 测试汇总统计在两种模式下的正确性
  - _Requirements: 1.1, 3.1, 3.2, 3.3, 5.1, 5.2_

- [x] 6. 实现智能聚合逻辑（仅多条记录时聚合）





  - 在AggregatedInventoryItem中添加isExpandable属性（判断details.length > 1）
  - 修改InventoryQueryScreen的_buildAggregatedView方法，根据isExpandable选择卡片类型
  - 创建SimpleInventoryCard组件用于单条记录的货品（不可展开，样式与原始卡片一致）
  - 确保AggregatedInventoryCard仅用于多条记录的货品（可展开/收起）
  - 在AggregatedInventoryCard中显示记录数量提示（如"3条记录"）
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 4.1, 4.2_

- [ ] 7. 集成测试和UI优化
  - 测试单条记录货品使用SimpleInventoryCard（无展开功能）
  - 测试多条记录货品使用AggregatedInventoryCard（可展开）
  - 测试新增记录后自动切换为聚合模式
  - 测试各种筛选组合的正确性
  - 优化展开/收起动画的流畅度
  - 调整详细列表的样式和间距
  - 验证在不同数据量下的性能表现
  - 处理边界情况和异常场景
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4_
