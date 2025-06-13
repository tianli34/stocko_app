# ProductListTile 组件使用指南

## 概述

`ProductListTile` 是一个用于在产品列表中显示单个产品信息的 Flutter 组件。它提供了丰富的产品信息展示和操作功能。

## 组件特性

### 1. 完整版 ProductListTile

- **产品基本信息显示**：名称、SKU、条码、品牌、规格等
- **价格信息**：支持促销价、零售价、建议零售价，并显示价格类型
- **操作按钮**：编辑、删除功能
- **自定义回调**：支持点击、编辑、删除的自定义处理
- **加载状态**：与 ProductController 集成，支持加载状态管理

### 2. 简化版 SimpleProductListTile

- **基本信息显示**：名称、SKU、价格
- **头像显示**：使用产品名称首字母作为头像
- **轻量级设计**：适用于简单列表场景

## 使用方法

### 基本使用

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_list_tile.dart';

class MyProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = [/* 产品列表 */];
    
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductListTile(
          product: product,
          onTap: () => print('点击了产品: ${product.name}'),
          onEdit: () => print('编辑产品: ${product.name}'),
          onDelete: () => print('删除产品: ${product.name}'),
        );
      },
    );
  }
}
```

### 自定义显示选项

```dart
ProductListTile(
  product: product,
  showActions: true,    // 显示操作按钮
  showPrice: true,      // 显示价格信息
  onTap: () {
    // 自定义点击处理
  },
  onEdit: () {
    // 自定义编辑处理
  },
  onDelete: () {
    // 自定义删除处理
  },
)
```

### 使用简化版本

```dart
SimpleProductListTile(
  product: product,
  onTap: () {
    // 处理点击事件
  },
)
```

### 与 ProductController 集成

```dart
class ProductListExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);
    final controllerState = ref.watch(productControllerProvider);

    // 监听操作结果
    ref.listen<ProductControllerState>(productControllerProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作成功')),
        );
      } else if (next.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '操作失败')),
        );
      }
    });

    return Column(
      children: [
        // 显示加载状态
        if (controllerState.isLoading)
          LinearProgressIndicator(),
          
        // 产品列表
        Expanded(
          child: productsAsyncValue.when(
            data: (products) => ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductListTile(
                  product: product,
                  // 删除操作会自动调用 ProductController
                  onEdit: () {
                    // 导航到编辑页面
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ProductFormExample(product: product),
                    ));
                  },
                );
              },
            ),
            loading: () => CircularProgressIndicator(),
            error: (error, stackTrace) => Text('加载失败: $error'),
          ),
        ),
      ],
    );
  }
}
```

## 组件参数

### ProductListTile 参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| product | Product | ✓ | - | 要显示的产品对象 |
| onTap | VoidCallback? | ✗ | null | 点击整个组件时的回调 |
| onEdit | VoidCallback? | ✗ | null | 点击编辑按钮时的回调 |
| onDelete | VoidCallback? | ✗ | null | 点击删除按钮时的回调 |
| showActions | bool | ✗ | true | 是否显示操作按钮 |
| showPrice | bool | ✗ | true | 是否显示价格信息 |

### SimpleProductListTile 参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| product | Product | ✓ | - | 要显示的产品对象 |
| onTap | VoidCallback? | ✗ | null | 点击时的回调 |

## 样式定制

组件使用 Material Design 规范，并遵循当前主题的颜色和字体设置。主要样式特点：

- **卡片样式**：使用 Card 组件，提供阴影效果
- **响应式设计**：适配不同屏幕尺寸
- **价格突出显示**：使用主题色突出显示价格信息
- **促销价标识**：促销价使用红色文字，原价显示删除线

## 示例场景

### 1. 产品管理页面
使用 `ProductListPage` 作为完整的产品管理界面

### 2. 产品选择器
在订单创建等场景中，使用 `SimpleProductListTile` 进行产品选择

### 3. 搜索结果
在搜索结果页面中展示产品信息

### 4. 产品目录
作为产品目录的展示组件

## 注意事项

1. **权限控制**：删除操作会显示确认对话框
2. **错误处理**：集成了 ProductController 的错误处理机制
3. **加载状态**：组件会根据 ProductController 状态禁用操作按钮
4. **数据验证**：产品 ID 为空时不会执行删除操作
5. **用户体验**：提供了丰富的视觉反馈和状态提示

## 相关组件

- `ProductFormExample`：产品表单组件
- `ProductController`：产品操作控制器
- `Product`：产品数据模型
- `CustomErrorWidget`：错误提示组件
- `LoadingWidget`：加载状态组件
