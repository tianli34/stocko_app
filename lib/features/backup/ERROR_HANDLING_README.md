# 备份功能错误处理和日志系统

本文档描述了备份功能的统一错误处理机制、日志记录功能、重试机制和资源管理系统。

## 概述

错误处理系统包含以下核心组件：

1. **BackupLogger** - 日志记录器
2. **BackupErrorHandler** - 错误处理器
3. **BackupResourceManager** - 资源管理器
4. **BackupErrorService** - 统一错误服务
5. **BackupErrorWidget** - 错误显示组件

## 核心功能

### 1. 统一错误处理机制

#### 用户友好的错误消息
- 将技术错误转换为用户可理解的消息
- 提供具体的解决建议和操作步骤
- 支持错误严重程度分级

#### 错误分类
```dart
enum BackupErrorType {
  fileSystemError,      // 文件系统错误
  databaseError,        // 数据库错误
  serializationError,   // 序列化错误
  encryptionError,      // 加密错误
  validationError,      // 验证错误
  insufficientSpace,    // 存储空间不足
  permissionDenied,     // 权限被拒绝
  // ... 更多错误类型
}
```

### 2. 详细日志记录

#### 日志级别
```dart
enum LogLevel {
  debug,     // 调试信息
  info,      // 一般信息
  warning,   // 警告信息
  error,     // 错误信息
  critical,  // 严重错误
}
```

#### 日志功能
- 内存日志缓存（最多1000条）
- 文件日志持久化
- 按日期分割日志文件
- 自动清理过期日志
- 日志导出功能

### 3. 错误重试机制

#### 重试配置
```dart
class RetryConfig {
  final int maxAttempts;           // 最大重试次数
  final Duration initialDelay;     // 初始延迟
  final double backoffMultiplier;  // 退避倍数
  final Duration maxDelay;         // 最大延迟
}
```

#### 预定义重试策略
- `RetryConfig.fileSystem` - 文件系统操作
- `RetryConfig.database` - 数据库操作
- `RetryConfig.network` - 网络操作

### 4. 资源管理和清理

#### 资源类型
```dart
enum ResourceType {
  temporaryFile,      // 临时文件
  temporaryDirectory, // 临时目录
  lockFile,          // 锁文件
  cacheFile,         // 缓存文件
}
```

#### 资源管理功能
- 自动跟踪创建的资源
- 操作完成后自动清理
- 定期清理过期资源
- 强制清理所有资源

## 使用方法

### 1. 基本错误处理

```dart
final errorService = BackupErrorService.instance;

try {
  // 执行可能失败的操作
  await someRiskyOperation();
} catch (e) {
  // 处理错误并获取用户友好的错误信息
  final userError = await errorService.handleError(
    e,
    operation: 'SomeOperation',
    context: {'userId': '123'},
  );
  
  // 显示错误给用户
  BackupErrorSnackBar.show(context, error: userError);
}
```

### 2. 带重试机制的操作

```dart
final result = await errorService.executeWithRetry(
  () => performBackupOperation(),
  config: RetryConfig.fileSystem,
  operationName: 'CreateBackup',
  context: {'backupId': 'backup_123'},
);
```

### 3. 安全执行（不抛出异常）

```dart
final result = await errorService.executeSafely(
  () => riskyOperation(),
  operationName: 'SafeOperation',
  defaultValue: null,
);
```

### 4. 资源管理

```dart
final resourceManager = BackupResourceManager.instance;

// 创建临时文件
final tempFile = await resourceManager.createTemporaryFile(
  prefix: 'backup_temp',
  operation: 'CreateBackup',
);

// 使用文件...

// 资源会在操作完成后自动清理
await resourceManager.releaseOperationResources('CreateBackup');
```

### 5. 日志记录

```dart
final logger = BackupLogger.instance;

// 记录不同级别的日志
await logger.info('BackupService', '开始创建备份');
await logger.warning('BackupService', '存储空间不足');
await logger.error('BackupService', '备份失败', 
    error: exception, stackTrace: stackTrace);

// 获取日志
final logs = logger.getMemoryLogs(
  minLevel: LogLevel.warning,
  since: DateTime.now().subtract(Duration(hours: 24)),
);
```

## UI 组件

### 1. 错误显示组件

```dart
// 完整的错误显示卡片
BackupErrorWidget(
  error: userFriendlyError,
  onRetry: () => retryOperation(),
  showTechnicalDetails: true,
  showSuggestions: true,
)

// 错误对话框
BackupErrorDialog.show(
  context,
  error: userFriendlyError,
  onRetry: () => retryOperation(),
)

// 简单的错误提示条
BackupErrorSnackBar.show(
  context,
  error: userFriendlyError,
  onRetry: () => retryOperation(),
)
```

### 2. 错误流监听

```dart
// 使用 Riverpod 监听错误流
ref.listen(backupErrorStreamProvider, (previous, next) {
  next.when(
    data: (error) {
      // 显示错误给用户
      BackupErrorDialog.show(context, error: error);
    },
    loading: () {},
    error: (error, stackTrace) {},
  );
});
```

## 集成到现有服务

### 1. 备份服务集成

```dart
class BackupService implements IBackupService {
  final BackupErrorService _errorService = BackupErrorService.instance;
  final BackupResourceManager _resourceManager = BackupResourceManager.instance;

  @override
  Future<BackupResult> createBackup({...}) async {
    final operationId = await _errorService.createOperationContext('CreateBackup');
    File? tempFile;
    
    try {
      // 创建临时资源
      tempFile = await _resourceManager.createTemporaryFile(
        operation: 'CreateBackup',
      );
      
      // 执行备份操作（带重试）
      final result = await _errorService.executeWithRetry(
        () => performActualBackup(),
        config: RetryConfig.fileSystem,
        operationName: 'PerformBackup',
      );
      
      // 完成操作
      await _errorService.completeOperationContext(
        operationId, 'CreateBackup', success: true,
      );
      
      return result;
    } catch (e) {
      // 处理错误
      final userError = await _errorService.handleError(
        e, operation: 'CreateBackup',
      );
      
      return BackupResult.failure(userError.message);
    } finally {
      // 清理资源
      if (tempFile != null) {
        await _errorService.executeSafely(() => tempFile!.delete());
      }
    }
  }
}
```

## 配置和初始化

### 1. 应用启动时初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化错误处理服务
  await BackupErrorService.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Riverpod 提供者

```dart
// 使用提供者管理服务生命周期
final errorService = ref.watch(backupErrorServiceProvider);
final errorStats = ref.watch(backupErrorStatsProvider());
```

## 最佳实践

### 1. 错误处理
- 总是使用 `BackupErrorService` 处理错误
- 为每个操作提供有意义的操作名称
- 包含相关的上下文信息
- 根据错误类型选择合适的显示方式

### 2. 资源管理
- 使用 `BackupResourceManager` 管理临时资源
- 在 finally 块中清理资源
- 为资源提供操作标识符便于批量清理

### 3. 日志记录
- 记录操作的开始和结束
- 包含足够的上下文信息用于调试
- 使用适当的日志级别
- 定期清理旧日志文件

### 4. 重试机制
- 根据操作类型选择合适的重试配置
- 不要对不可重试的错误进行重试
- 提供取消机制避免无限重试

## 故障排除

### 1. 常见问题
- **日志文件过大**: 检查日志清理配置
- **资源泄漏**: 确保操作完成后清理资源
- **重试次数过多**: 调整重试配置或检查错误类型

### 2. 调试工具
- 使用 `getErrorStats()` 查看错误统计
- 使用 `exportErrorReport()` 导出详细报告
- 查看内存日志了解最近的操作

## 性能考虑

### 1. 内存使用
- 内存日志限制为1000条
- 定期清理过期资源
- 避免在日志中存储大量数据

### 2. 文件I/O
- 日志异步写入文件
- 批量清理过期文件
- 使用合适的文件缓冲区大小

### 3. 错误处理开销
- 错误处理本身不应抛出异常
- 避免在错误处理中进行复杂操作
- 使用适当的日志级别减少I/O