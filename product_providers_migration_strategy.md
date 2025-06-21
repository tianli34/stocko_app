# 渐进式迁移策略：从 `product_providers.dart` 到 `product_providers_refactored.dart`

## 目标
- 平滑过渡到新的 AsyncNotifier 实现，保持现有功能不受影响
- 最小化一次性大规模修改风险，快速回退到旧版
- 降低测试和验证成本，确保每一步都可编译、可运行、可测试

---

## 1. 前期准备

1. **版本控制**：确保项目在 Git 等版本控制下，且当前 `main` 或 `master` 分支处于干净状态。
2. **分支创建**：新建分支 `feature/migrate-product-providers` 进行所有迁移工作。
3. **依赖确认**：项目已升级到 Riverpod 2.x，并安装 `flutter_riverpod`、`riverpod_annotation`、`build_runner`。
4. **备份原文件**：在项目根目录下创建 `product_providers_old.dart` 备份：
   ```powershell
   cp lib\features\product\application\provider\product_providers.dart \
      lib\features\product\application\provider\product_providers_old.dart
   ```

---

## 2. 阶段 1：兼容性适配 🪢

### 2.1 引入重构文件
1. 将 `product_providers_refactored.dart` 拷贝到目标目录且重命名为临时文件：
   ```powershell
   cp lib\features\product\application\provider\product_providers_refactored.dart \
      lib\features\product\application\provider\product_providers_new.dart
   ```
2. 不替换旧文件，仍保留旧的 `product_providers.dart`。

### 2.2 增加别名 Provider
在 `product_providers.dart` 文件末尾添加一行：
```dart
// 临时兼容：将旧 Provider 指向新实现
final productControllerProvider = productOperationsProvider;
```
这样，旧 UI 中所有对 `productControllerProvider` 的引用会自动使用新实现。

### 2.3 确认编译和基本功能
- 执行 `flutter pub run build_runner build`（如果使用代码生成）
- 运行应用，关注产品列表、添加/编辑/删除功能是否正常
- 确认所有单元测试通过：
  ```powershell
  flutter test
  ```

---

## 3. 阶段 2：逐步迁移 UI 调用 ✂️

**目标**：在不影响业务功能的情况下，将各处 `ref.read(productControllerProvider.notifier)` 改为 `ref.read(productOperationsProvider.notifier)`，并更新状态读取。

1. **搜索定位**：使用 IDE 全局搜索关键词：
   - `productControllerProvider.notifier`
   - `ref.watch(productControllerProvider)`
2. **逐文件修改**：每次只改一个文件：
   - `product_add_edit_screen.dart`
   - `product_list_screen.dart`
   - `inbound_barcode_scanner_screen.dart` 等
3. **替换示例**：
   ```diff
   - final controller = ref.read(productControllerProvider.notifier);
   + final operations = ref.read(productOperationsProvider.notifier);
   
   - final controllerState = ref.watch(productControllerProvider);
   + final operationsState = ref.watch(productOperationsProvider);
   ```
4. **更新状态处理**：
   ```dart
   operationsState.when(
     data: (_) => ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('操作成功')),
     ),
     loading: () => /* 可选：显示 loading */, 
     error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('操作失败: $e')),
     ),
   );
   ```
5. **编译 & 测试**：每修改完一个文件，立即执行编译和测试，确保无编译错误并通过相关测试。

---

## 4. 阶段 3：测试覆盖 & 边缘场景验证 🧪

1. **新增测试**：针对 `productByIdProvider`、`productByBarcodeProvider` 写单元测试，确保新 Provider 行为与旧方法一致。
2. **更新现有测试**：修改测试文件中对 `productControllerProvider` 的 override，切换到 `productOperationsProvider`。
3. **UI 测试**：运行 Widget 测试、集成测试，验证界面交互场景。

---

## 5. 阶段 4：清理与收尾 🧹

1. **移除兼容别名**：删除 `productControllerProvider = productOperationsProvider;`。
2. **删除旧文件**：移除 `product_providers_old.dart`、`product_providers_new.dart`。
3. **重命名新文件**：将 `product_providers_new.dart` 重命名为 `product_providers.dart`。
4. **格式化 & 优化导入**：执行 `flutter pub run dart format .` 并移除未使用 import。
5. **最终测试**：全量测试通过后合并到主分支。

---

## 6. 风险 & 回退方案

- **风险点**：状态监听逻辑改动、UI 渲染差异、边缘错误消息处理
- **回退策略**：如果遇到问题，可立即切换回旧实现：
  ```diff
  - final productControllerProvider = productOperationsProvider;
  + // 恢复旧实现
  + final productControllerProvider = StateNotifierProvider<ProductController, ProductControllerState>(...);
  ```
- **Version control**：每阶段提交都要保证能回到上一个稳定状态


---

*作者：程序员小G*  
*日期：2025-06-21*
