# 备份服务实现

本文档描述了任务3"实现备份服务核心逻辑"的完整实现。

## 实现的功能

### 1. 核心服务接口 (IBackupService)
- `createBackup()` - 创建备份，支持自定义选项和进度回调
- `getLocalBackups()` - 获取本地备份文件列表
- `deleteBackup()` - 删除指定备份文件
- `getBackupInfo()` - 获取备份文件信息
- `validateBackupFile()` - 验证备份文件完整性
- `estimateBackupSize()` - 估算备份文件大小

### 2. 备份服务实现 (BackupService)
- 完整的备份创建流程，包含7个步骤
- 支持进度回调和取消机制
- 数据完整性校验（SHA-256）
- 元数据生成和管理
- 错误处理和异常管理

### 3. 状态管理 (BackupController)
- 使用 Riverpod StateNotifier 管理备份状态
- 实时进度更新
- 取消操作支持
- 错误状态处理

### 4. 用户界面组件
- `BackupProgressDialog` - 备份进度对话框
- `BackupButton` - 通用备份按钮
- `QuickBackupButton` - 快速备份按钮（用于设置页面）

### 5. 文件管理工具 (BackupFileManager)
- 备份文件的本地存储管理
- 文件重命名、复制、删除操作
- 文件大小计算和格式化
- 安全文件名生成

## 文件结构

```
lib/features/backup/
├── domain/
│   ├── models/                    # 已存在的数据模型
│   └── services/
│       └── i_backup_service.dart  # 备份服务接口
├── data/
│   ├── repository/
│   │   └── data_export_repository.dart  # 已存在的数据导出仓储
│   ├── services/
│   │   └── backup_service.dart    # 备份服务实现
│   ├── providers/
│   │   └── backup_service_provider.dart  # Riverpod 提供者
│   └── utils/
│       └── backup_file_manager.dart  # 文件管理工具
└── presentation/
    ├── controllers/
    │   └── backup_controller.dart  # 状态管理控制器
    ├── widgets/
    │   ├── backup_progress_dialog.dart  # 进度对话框
    │   └── backup_button.dart      # 备份按钮组件
    └── integration/
        └── settings_integration_example.dart  # 集成示例
```

## 使用方法

### 1. 基本使用

```dart
// 获取备份服务
final backupService = ref.watch(backupServiceProvider);

// 创建备份
final result = await backupService.createBackup(
  options: const BackupOptions(
    customName: 'my_backup',
    description: '手动备份',
  ),
  onProgress: (step, current, total) {
    print('$step: $current/$total');
  },
);

if (result.success) {
  print('备份成功: ${result.filePath}');
} else {
  print('备份失败: ${result.errorMessage}');
}
```

### 2. 在UI中使用

```dart
// 使用备份按钮
const BackupButton(
  customName: 'manual_backup',
  buttonText: '立即备份',
)

// 使用快速备份按钮（适合设置页面）
const QuickBackupButton()
```

### 3. 状态管理

```dart
// 监听备份状态
final backupState = ref.watch(backupControllerProvider);

// 开始备份
ref.read(backupControllerProvider.notifier).startBackup(
  options: const BackupOptions(customName: 'test'),
);

// 取消备份
ref.read(backupControllerProvider.notifier).cancelBackup();
```

## 集成到设置页面

在现有的 `_DataManagementSection` 中添加：

```dart
const QuickBackupButton(),
const Divider(),
```

或者使用完整的备份管理部分：

```dart
const BackupManagementSection(),
```

## 测试

运行备份服务测试：

```bash
flutter test test/features/backup/data/services/backup_service_test.dart
```

## 技术特性

1. **进度跟踪**: 7步备份流程，实时进度更新
2. **取消支持**: 使用 CancelToken 支持用户取消操作
3. **错误处理**: 完善的异常处理和用户友好的错误消息
4. **数据完整性**: SHA-256 校验和验证
5. **文件管理**: 完整的本地文件操作支持
6. **状态管理**: 使用 Riverpod 进行响应式状态管理

## 依赖的已有组件

- `DataExportRepository` - 数据导出功能
- `BackupMetadata`, `BackupData`, `BackupOptions` - 数据模型
- `BackupException` - 异常处理
- `AppDatabase` - 数据库访问

## 下一步

此实现完成了任务3的所有要求：
- ✅ 创建BackupService类实现IBackupService接口
- ✅ 实现createBackup方法，支持自定义备份名称和选项
- ✅ 添加备份进度回调和取消机制
- ✅ 实现备份文件的元数据生成和管理

可以继续实现任务4"实现文件系统操作和存储管理"中的高级文件操作功能。