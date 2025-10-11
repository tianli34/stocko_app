# Design Document

## Overview

本设计文档描述了库存查询页面聚合展示功能的技术实现方案。该功能将在未筛选店铺时，将相同货品的多条库存记录聚合为一张可展开的卡片，提升用户体验。在筛选店铺时，保持原有的展示逻辑。

核心设计理念：
- 智能聚合：仅当同一货品有多条记录（≥2）时才启用聚合模式
- 在数据层进行聚合处理，减少UI层复杂度
- 使用可展开的卡片组件实现交互
- 单条记录的货品使用普通卡片，无展开/收起功能
- 保持与现有代码架构的一致性
- 最小化对现有功能的影响

## Architecture

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                  InventoryQueryScreen                    │
│                    (Presentation)                        │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              inventoryQueryProvider                      │
│                   (State Management)                     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│            InventoryQueryService                         │
│              (Business Logic)                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │  getInventoryWithDetails()                       │   │
│  │  ↓                                               │   │
│  │  getAggregatedInventory() [新增]                │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Data Repositories                           │
│   (InventoryRepository, ProductRepository, etc.)        │
└─────────────────────────────────────────────────────────┘
```

### 数据流

1. **未筛选店铺时**：
   - UI → Provider → Service.getAggregatedInventory() → 返回聚合数据
   - 聚合数据结构包含总库存和详细记录列表

2. **筛选店铺时**：
   - UI → Provider → Service.getInventoryWithDetails() → 返回原始数据
   - 保持现有逻辑不变


## Components and Interfaces

### 1. 数据模型

#### AggregatedInventoryItem (新增)

聚合后的库存项数据结构：

```dart
class AggregatedInventoryItem {
  final int productId;
  final String productName;
  final String? productImage;
  final int totalQuantity;           // 总库存数量
  final String unit;
  final int? categoryId;
  final String categoryName;
  final List<InventoryDetail> details; // 详细记录列表
  final bool needsAggregation;       // 是否需要聚合（记录数 > 1）
  
  AggregatedInventoryItem({...});
  
  // 便捷方法：判断是否需要展开/收起功能
  bool get isExpandable => details.length > 1;
}
```

#### InventoryDetail (新增)

单条库存详细信息：

```dart
class InventoryDetail {
  final int stockId;
  final int shopId;
  final String shopName;
  final int quantity;
  final int? batchId;
  final String? batchNumber;
  final DateTime? productionDate;
  final int? shelfLifeDays;
  final String? shelfLifeUnit;
  final int? remainingDays;          // 剩余保质期天数
  
  InventoryDetail({...});
}
```

### 2. Service层修改

#### InventoryQueryService

新增方法：

```dart
/// 获取聚合后的库存数据（未筛选店铺时使用）
Future<List<AggregatedInventoryItem>> getAggregatedInventory({
  String? categoryFilter,
  String? statusFilter,
}) async {
  // 1. 获取所有库存详细信息
  final allInventory = await getInventoryWithDetails(
    categoryFilter: categoryFilter,
    statusFilter: statusFilter,
  );
  
  // 2. 按productId分组聚合
  final Map<int, List<Map<String, dynamic>>> groupedByProduct = {};
  for (var item in allInventory) {
    final productId = item['productId'] as int;
    groupedByProduct.putIfAbsent(productId, () => []).add(item);
  }
  
  // 3. 构建聚合数据
  final result = <AggregatedInventoryItem>[];
  for (var entry in groupedByProduct.entries) {
    final items = entry.value;
    final firstItem = items.first;
    
    // 计算总库存
    final totalQuantity = items.fold<int>(
      0, 
      (sum, item) => sum + (item['quantity'] as int)
    );
    
    // 构建详细记录列表
    final details = items.map((item) => InventoryDetail(...)).toList();
    
    // 判断是否需要聚合（记录数 > 1）
    final needsAggregation = items.length > 1;
    
    result.add(AggregatedInventoryItem(
      needsAggregation: needsAggregation,
      ...
    ));
  }
  
  return result;
}
```

### 3. Provider层修改

#### inventoryQueryProvider

修改逻辑以支持聚合模式：

```dart
final inventoryQueryProvider = FutureProvider<dynamic>((ref) async {
  final filterState = ref.watch(inventoryFilterProvider);
  final queryService = ref.watch(inventoryQueryServiceProvider);
  
  ref.watch(productListStreamProvider);
  
  final shopFilter = filterState.selectedShop == '所有仓库' 
      ? null 
      : filterState.selectedShop;
  final categoryFilter = filterState.selectedCategory == '所有分类'
      ? null
      : filterState.selectedCategory;
  final statusFilter = filterState.selectedStatus == '库存状态'
      ? null
      : filterState.selectedStatus;
  
  // 判断是否需要聚合
  if (shopFilter == null) {
    // 未筛选店铺，返回聚合数据
    final aggregatedData = await queryService.getAggregatedInventory(
      categoryFilter: categoryFilter,
      statusFilter: statusFilter,
    );
    
    // 应用排序
    _applySortToAggregated(aggregatedData, filterState.sortBy);
    
    return aggregatedData;
  } else {
    // 筛选了店铺，返回原始数据
    final data = await queryService.getInventoryWithDetails(
      shopFilter: shopFilter,
      categoryFilter: categoryFilter,
      statusFilter: statusFilter,
    );
    
    _applySortToOriginal(data, filterState.sortBy);
    
    return data;
  }
});
```


### 4. UI组件

#### InventoryQueryScreen

修改build方法以支持两种展示模式：

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final inventoryAsyncValue = ref.watch(inventoryQueryProvider);
  final filterState = ref.watch(inventoryFilterProvider);
  final isAggregatedMode = filterState.selectedShop == '所有仓库';
  
  return Scaffold(
    appBar: AppBar(...),
    body: inventoryAsyncValue.when(
      data: (inventoryData) {
        if (isAggregatedMode) {
          // 聚合模式
          final aggregatedList = inventoryData as List<AggregatedInventoryItem>;
          return _buildAggregatedView(aggregatedList);
        } else {
          // 原始模式
          final inventoryList = inventoryData as List<Map<String, dynamic>>;
          return _buildOriginalView(inventoryList);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorView(error),
    ),
  );
}

Widget _buildAggregatedView(List<AggregatedInventoryItem> items) {
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      // 根据是否需要聚合选择不同的卡片组件
      if (item.isExpandable) {
        return AggregatedInventoryCard(item: item);
      } else {
        // 单条记录，使用普通卡片（不可展开）
        return SimpleInventoryCard(item: item);
      }
    },
  );
}
```

#### AggregatedInventoryCard (新增组件)

可展开的聚合库存卡片（仅用于多条记录的货品）：

```dart
class AggregatedInventoryCard extends StatefulWidget {
  final AggregatedInventoryItem item;
  
  const AggregatedInventoryCard({required this.item});
  
  @override
  State<AggregatedInventoryCard> createState() => 
      _AggregatedInventoryCardState();
}

class _AggregatedInventoryCardState extends State<AggregatedInventoryCard> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    // 断言：此组件仅用于可展开的项
    assert(widget.item.isExpandable, 
      'AggregatedInventoryCard should only be used for items with multiple records');
    
    return Card(
      child: Column(
        children: [
          // 收起状态：显示货品基本信息和总库存
          _buildCollapsedHeader(),
          
          // 展开状态：显示详细库存列表
          if (_isExpanded) _buildExpandedDetails(),
        ],
      ),
    );
  }
  
  Widget _buildCollapsedHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 商品图片
            _buildProductImage(),
            const SizedBox(width: 16),
            
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.productName, style: ...),
                  Text(widget.item.categoryName, style: ...),
                  const SizedBox(height: 12),
                  
                  // 总库存（醒目显示）
                  Row(
                    children: [
                      Text(
                        '${widget.item.totalQuantity}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(widget.item.unit, style: ...),
                      const Spacer(),
                      
                      // 展开/收起图标（仅多条记录时显示）
                      Icon(
                        _isExpanded 
                            ? Icons.expand_less 
                            : Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.item.details.length}条记录',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpandedDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.item.details.length,
        separatorBuilder: (_, __) => Divider(height: 1),
        itemBuilder: (context, index) {
          final detail = widget.item.details[index];
          return _buildDetailRow(detail);
        },
      ),
    );
  }
  
  Widget _buildDetailRow(InventoryDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 店铺名称
          Expanded(
            flex: 2,
            child: Text(detail.shopName, style: ...),
          ),
          
          // 生产日期
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(detail.productionDate),
              style: ...,
            ),
          ),
          
          // 剩余保质期
          Expanded(
            flex: 2,
            child: Text(
              detail.remainingDays != null
                  ? '剩余${detail.remainingDays}天'
                  : '-',
              style: TextStyle(
                color: _getShelfLifeColor(detail.remainingDays),
              ),
            ),
          ),
          
          // 库存数量
          Expanded(
            flex: 1,
            child: Text(
              '${detail.quantity}${widget.item.unit}',
              style: ...,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### SimpleInventoryCard (新增组件)

普通库存卡片（用于单条记录的货品，不可展开）：

```dart
class SimpleInventoryCard extends StatelessWidget {
  final AggregatedInventoryItem item;
  
  const SimpleInventoryCard({required this.item});
  
  @override
  Widget build(BuildContext context) {
    // 断言：此组件仅用于单条记录
    assert(!item.isExpandable, 
      'SimpleInventoryCard should only be used for items with single record');
    
    final detail = item.details.first; // 只有一条记录
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 商品图片
            _buildProductImage(item.productImage),
            const SizedBox(width: 16),
            
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.categoryName} · ${detail.shopName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (detail.remainingDays != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '剩余: ${detail.remainingDays}天',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getShelfLifeColor(detail.remainingDays),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // 库存数量（无展开图标，样式与原始卡片一致）
                  Row(
                    children: [
                      Text(
                        '${item.totalQuantity}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```


## Data Models

### 数据结构设计

#### 聚合数据结构

```dart
// 聚合后的库存项
{
  'productId': 1,
  'productName': '可口可乐',
  'productImage': '/path/to/image.jpg',
  'totalQuantity': 150,
  'unit': '瓶',
  'categoryId': 1,
  'categoryName': '饮料',
  'details': [
    {
      'stockId': 1,
      'shopId': 1,
      'shopName': '总店',
      'quantity': 100,
      'batchId': 1,
      'batchNumber': 'B20240101',
      'productionDate': '2024-01-01T00:00:00.000Z',
      'shelfLifeDays': 365,
      'shelfLifeUnit': 'days',
      'remainingDays': 200,
    },
    {
      'stockId': 2,
      'shopId': 2,
      'shopName': '分店A',
      'quantity': 50,
      'batchId': 2,
      'batchNumber': 'B20240115',
      'productionDate': '2024-01-15T00:00:00.000Z',
      'shelfLifeDays': 365,
      'shelfLifeUnit': 'days',
      'remainingDays': 214,
    },
  ],
}
```

#### 原始数据结构（保持不变）

```dart
{
  'id': 1,
  'productName': '可口可乐',
  'productImage': '/path/to/image.jpg',
  'quantity': 100,
  'unit': '瓶',
  'shopId': 1,
  'shopName': '总店',
  'categoryId': 1,
  'categoryName': '饮料',
  'productId': 1,
  'batchNumber': 'B20240101',
  'productionDate': '2024-01-01T00:00:00.000Z',
  'shelfLifeDays': 365,
  'shelfLifeUnit': 'days',
}
```

### 数据转换流程

```
原始库存数据 (List<Map>)
    ↓
按productId分组
    ↓
计算每组的总库存
    ↓
构建详细记录列表
    ↓
聚合数据 (List<AggregatedInventoryItem>)
```

## Error Handling

### 错误场景处理

1. **数据聚合失败**
   - 捕获异常并记录日志
   - 降级到原始展示模式
   - 向用户显示友好的错误提示

2. **批次信息缺失**
   - 在详细列表中显示"-"或"无批次"
   - 不影响总库存计算
   - 保质期字段显示为空

3. **店铺信息缺失**
   - 显示"未知店铺"
   - 仍然包含在聚合计算中

4. **图片加载失败**
   - 使用占位图标
   - 不影响其他信息展示

### 异常处理策略

```dart
try {
  final aggregatedData = await getAggregatedInventory(...);
  return aggregatedData;
} catch (e) {
  // 记录错误
  print('聚合数据失败: $e');
  
  // 降级到原始模式
  final originalData = await getInventoryWithDetails(...);
  return originalData;
}
```


## Testing Strategy

### 单元测试

#### Service层测试

```dart
// test/features/inventory/presentation/application/inventory_query_service_test.dart

group('InventoryQueryService - Aggregation', () {
  test('应该正确聚合相同货品的库存', () async {
    // Arrange
    final service = InventoryQueryService(...);
    
    // Act
    final result = await service.getAggregatedInventory();
    
    // Assert
    expect(result.length, lessThan(originalLength));
    expect(result.first.totalQuantity, equals(expectedTotal));
  });
  
  test('应该正确计算总库存数量', () async {
    // 测试多个店铺和批次的库存总和
  });
  
  test('应该正确构建详细记录列表', () async {
    // 测试details列表包含所有原始记录
  });
  
  test('应该正确处理无批次信息的库存', () async {
    // 测试批次为null的情况
  });
  
  test('应该正确应用分类筛选', () async {
    // 测试聚合后仍能正确筛选分类
  });
  
  test('应该正确应用库存状态筛选', () async {
    // 测试聚合后的总库存状态判断
  });
});
```

#### Provider层测试

```dart
group('inventoryQueryProvider - Aggregation Mode', () {
  test('未筛选店铺时应返回聚合数据', () async {
    // 测试shopFilter为null时的行为
  });
  
  test('筛选店铺时应返回原始数据', () async {
    // 测试shopFilter有值时的行为
  });
  
  test('应该正确应用排序到聚合数据', () async {
    // 测试按数量和保质期排序
  });
});
```

### Widget测试

```dart
group('AggregatedInventoryCard', () {
  testWidgets('应该显示货品基本信息和总库存', (tester) async {
    // 测试收起状态的显示
  });
  
  testWidgets('点击后应该展开显示详细信息', (tester) async {
    // 测试展开/收起交互
  });
  
  testWidgets('应该正确显示所有详细记录', (tester) async {
    // 测试详细列表的渲染
  });
  
  testWidgets('应该正确显示保质期颜色', (tester) async {
    // 测试保质期预警颜色
  });
});

group('InventoryQueryScreen - Aggregation', () {
  testWidgets('未筛选店铺时应显示聚合卡片', (tester) async {
    // 测试聚合模式的UI
  });
  
  testWidgets('筛选店铺时应显示原始卡片', (tester) async {
    // 测试原始模式的UI
  });
  
  testWidgets('切换筛选条件时应正确更新显示', (tester) async {
    // 测试模式切换
  });
});
```

### 集成测试

```dart
group('Inventory Aggregation Integration', () {
  testWidgets('完整的聚合展示流程', (tester) async {
    // 1. 打开库存查询页面
    // 2. 验证显示聚合卡片
    // 3. 点击展开卡片
    // 4. 验证显示详细信息
    // 5. 选择店铺筛选
    // 6. 验证切换到原始模式
    // 7. 清除筛选
    // 8. 验证切换回聚合模式
  });
});
```

### 测试数据准备

```dart
// 测试用的模拟数据
final mockInventoryData = [
  {
    'productId': 1,
    'productName': '可口可乐',
    'quantity': 100,
    'shopId': 1,
    'shopName': '总店',
    // ...
  },
  {
    'productId': 1,
    'productName': '可口可乐',
    'quantity': 50,
    'shopId': 2,
    'shopName': '分店A',
    // ...
  },
  {
    'productId': 2,
    'productName': '雪碧',
    'quantity': 80,
    'shopId': 1,
    'shopName': '总店',
    // ...
  },
];
```

## Implementation Notes

### 性能考虑

1. **数据聚合性能**
   - 使用Map进行分组，时间复杂度O(n)
   - 避免嵌套循环
   - 对于大量数据，考虑在后台线程处理

2. **UI渲染性能**
   - 使用ListView.builder进行懒加载
   - 展开的详细列表使用shrinkWrap避免嵌套滚动
   - 图片使用缓存机制

3. **内存优化**
   - 聚合数据复用原始数据的引用
   - 避免不必要的数据复制

### 兼容性考虑

1. **向后兼容**
   - 保持原有API不变
   - 新增方法而非修改现有方法
   - 原始展示模式完全不受影响

2. **数据库兼容**
   - 不需要修改数据库结构
   - 不需要数据迁移

3. **现有功能兼容**
   - 筛选功能正常工作
   - 排序功能正常工作
   - 搜索功能正常工作

### 开发顺序建议

1. **Phase 1: 数据层**
   - 实现聚合数据模型
   - 实现Service层的聚合方法
   - 编写单元测试

2. **Phase 2: 状态管理**
   - 修改Provider支持两种模式
   - 实现模式切换逻辑
   - 编写Provider测试

3. **Phase 3: UI层**
   - 实现AggregatedInventoryCard组件
   - 修改InventoryQueryScreen
   - 编写Widget测试

4. **Phase 4: 集成与优化**
   - 集成测试
   - 性能优化
   - UI/UX调整

### 潜在风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 聚合逻辑错误导致库存数量不准确 | 高 | 充分的单元测试，代码审查 |
| 大量数据时性能下降 | 中 | 性能测试，必要时优化算法 |
| UI展开/收起状态管理复杂 | 低 | 使用StatefulWidget简化状态管理 |
| 与现有筛选功能冲突 | 中 | 详细的集成测试 |

## Design Decisions

### 为什么在Service层聚合而不是在数据库层？

**决策**：在Service层进行数据聚合

**理由**：
1. 不需要修改数据库结构和查询
2. 更灵活，易于调整聚合逻辑
3. 保持数据库层的简单性
4. 便于测试和维护

### 为什么使用StatefulWidget而不是Provider管理展开状态？

**决策**：使用StatefulWidget管理每个卡片的展开状态

**理由**：
1. 展开状态是UI局部状态，不需要全局管理
2. 简化状态管理逻辑
3. 更好的性能，避免不必要的重建
4. 符合Flutter最佳实践

### 为什么不使用ExpansionTile？

**决策**：自定义可展开卡片组件

**理由**：
1. 需要自定义展开后的详细列表样式
2. 需要更灵活的布局控制
3. 需要与现有卡片样式保持一致
4. ExpansionTile的默认样式不符合设计需求

### 为什么保留两种展示模式？

**决策**：根据是否筛选店铺动态切换展示模式

**理由**：
1. 满足不同场景的需求
2. 筛选特定店铺时，用户关注该店铺的详细情况
3. 未筛选时，用户需要总览所有货品
4. 保持现有用户习惯，减少学习成本
