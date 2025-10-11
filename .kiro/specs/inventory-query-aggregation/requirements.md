# Requirements Document

## Introduction

本需求文档描述了库存查询页面的展示逻辑优化功能。当前系统中，同一货品如果来自不同店铺或不同批次，会在库存查询页面分别展示在多张卡片上，导致信息分散。本功能将实现智能聚合展示：在未筛选店铺时，将相同货品聚合为一张卡片，支持展开查看详细信息；在筛选店铺时，保持当前的展示逻辑。

## Requirements

### Requirement 1

**User Story:** 作为库存管理员，我希望在未筛选店铺时能看到每个货品的聚合库存信息，这样我可以快速了解每种货品的总体库存情况，而不被多个卡片分散注意力。

#### Acceptance Criteria

1. WHEN 用户打开库存查询页面且未选择任何店铺筛选 THEN 系统 SHALL 检查每个货品的库存记录数量
2. WHEN 相同货品（相同货品ID）存在2条或以上库存记录 THEN 系统 SHALL 将这些记录聚合为一张可展开/收起的卡片展示
3. WHEN 相同货品仅存在1条库存记录 THEN 系统 SHALL 使用普通卡片展示，不启用聚合功能，不显示展开/收起图标
4. WHEN 聚合卡片处于收起状态 THEN 系统 SHALL 仅显示货品基本信息和总库存量
5. WHEN 用户点击聚合卡片展开 THEN 系统 SHALL 显示该货品的详细库存明细列表
6. WHEN 同一货品新增库存记录使总记录数达到2条或以上 THEN 系统 SHALL 自动将该货品切换为聚合展示模式

### Requirement 2

**User Story:** 作为库存管理员，我希望在展开聚合卡片后能看到每个店铺和批次的详细库存信息，这样我可以了解库存的具体分布情况。

#### Acceptance Criteria

1. WHEN 用户展开聚合卡片 THEN 系统 SHALL 显示该货品所有库存记录的详细信息列表
2. WHEN 展示详细库存信息 THEN 系统 SHALL 包含以下字段：店铺名称、批次号或生产日期、剩余保质期、当前库存数量
3. WHEN 存在多条库存记录 THEN 系统 SHALL 按店铺名称或批次时间排序展示
4. WHEN 用户再次点击卡片 THEN 系统 SHALL 收起详细信息，恢复到仅显示总库存的状态

### Requirement 3

**User Story:** 作为库存管理员，我希望在筛选了特定店铺后，系统能按原有逻辑展示该店铺的库存，这样我可以专注于查看特定店铺的库存情况。

#### Acceptance Criteria

1. WHEN 用户选择了一个或多个店铺进行筛选 THEN 系统 SHALL 禁用货品聚合功能
2. WHEN 店铺筛选激活时 THEN 系统 SHALL 按当前逻辑展示库存卡片（每个店铺-批次组合一张卡片）
3. WHEN 用户清除店铺筛选条件 THEN 系统 SHALL 自动切换回聚合展示模式
4. WHEN 切换筛选状态时 THEN 系统 SHALL 保持页面其他筛选条件不变

### Requirement 4

**User Story:** 作为库存管理员，我希望聚合卡片的展示样式清晰易读，这样我可以快速识别和操作。

#### Acceptance Criteria

1. WHEN 显示聚合卡片 THEN 系统 SHALL 使用与现有卡片一致的设计风格
2. WHEN 卡片可展开时 THEN 系统 SHALL 显示明确的展开/收起指示图标
3. WHEN 展示总库存数量 THEN 系统 SHALL 使用醒目的字体和颜色突出显示
4. WHEN 展示详细库存列表 THEN 系统 SHALL 使用清晰的分隔线或缩进区分不同记录

### Requirement 5

**User Story:** 作为库存管理员，我希望在聚合模式下仍能使用其他筛选功能（如货品名称搜索），这样我可以快速找到需要的货品。

#### Acceptance Criteria

1. WHEN 用户在聚合模式下使用货品名称搜索 THEN 系统 SHALL 仅显示匹配的聚合卡片
2. WHEN 用户应用其他筛选条件（如库存预警） THEN 系统 SHALL 在聚合后的结果上应用这些筛选
3. WHEN 筛选条件变化时 THEN 系统 SHALL 实时更新聚合卡片列表
4. WHEN 清除所有筛选条件 THEN 系统 SHALL 显示所有货品的聚合卡片
