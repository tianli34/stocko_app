# ProductController 使用指南

## 概述

`productControllerProvider` 是一个基于 Riverpod 2.x 的 StateNotifier，用于管理产品的增删改操作。它提供了完整的状态管理、错误处理和 Loading 状态管理。

## 核心功能

### 1. 状态管理

```dart
/// 产品操作状态
enum ProductOperationStatus {
  initial,  // 初始状态
  loading,  // 加载中
  success,  // 操作成功
  error,    // 操作失败
}

/// 产品控制器状态
class ProductControllerState {
  final ProductOperationStatus status;
  final String? errorMessage;          // 错误信息
  final Product? lastOperatedProduct;  // 最后操作的产品
}
```

### 2. 主要方法

- `addProduct(Product product)` - 添加产品
- `updateProduct(Product product)` - 更新产品
- `deleteProduct(String productId)` - 删除产品
- `getProductById(String productId)` - 根据ID获取产品
- `resetState()` - 重置状态
- `clearError()` - 清除错误状态

## 使用方式

### 在 Widget 中使用

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听控制器状态
    final controllerState = ref.watch(productControllerProvider);
    final controller = ref.read(productControllerProvider.notifier);
    
    // 监听状态变化
    ref.listen<ProductControllerState>(productControllerProvider, (previous, next) {
      if (next.isSuccess) {
        // 操作成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作成功')),
        );
      } else if (next.isError) {
        // 操作失败
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
          
        // 添加产品按钮
        ElevatedButton(
          onPressed: controllerState.isLoading ? null : () {
            final product = Product(name: '新产品');
            controller.addProduct(product);
          },
          child: Text('添加产品'),
        ),
        
        // 更新产品按钮
        ElevatedButton(
          onPressed: controllerState.isLoading ? null : () {
            final product = Product(id: 'some-id', name: '更新的产品');
            controller.updateProduct(product);
          },
          child: Text('更新产品'),
        ),
        
        // 删除产品按钮
        ElevatedButton(
          onPressed: controllerState.isLoading ? null : () {
            controller.deleteProduct('some-product-id');
          },
          child: Text('删除产品'),
        ),
      ],
    );
  }
}
```

### 与产品列表联动

```dart
class ProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(allProductsProvider);
    final controllerState = ref.watch(productControllerProvider);
    
    return Column(
      children: [
        // 操作状态指示器
        if (controllerState.isLoading)
          LinearProgressIndicator(),
          
        // 产品列表
        Expanded(
          child: productsAsyncValue.when(
            data: (products) => ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      final controller = ref.read(productControllerProvider.notifier);
                      controller.deleteProduct(product.id!);
                    },
                  ),
                );
              },
            ),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ),
      ],
    );
  }
}
```

## 特性

### 1. 自动刷新
- 每次增删改操作成功后，会自动调用 `ref.invalidate(allProductsProvider)` 刷新产品列表
- 由于使用了 Stream，数据库变化也会自动反映到 UI

### 2. 错误处理
- 所有操作都包含 try-catch 错误处理
- 错误信息会保存在状态中，方便 UI 显示
- 提供 `clearError()` 方法清除错误状态

### 3. 状态管理
- 提供完整的操作状态：initial、loading、success、error
- 保存最后操作的产品信息
- 提供便捷的状态检查方法：`isLoading`、`isError`、`isSuccess`

### 4. 类型安全
- 使用 TypeScript 风格的严格类型检查
- 所有方法都有完整的类型定义

## 依赖关系

```
productControllerProvider
    ↓ 依赖
productRepositoryProvider
    ↓ 依赖  
appDatabaseProvider
```

操作成功后会刷新：
```
productControllerProvider → invalidate → allProductsProvider
```

## 示例文件

- `product_list_example.dart` - 产品列表页面示例
- `product_form_example.dart` - 产品表单页面示例

这些示例展示了完整的增删改查功能实现。
