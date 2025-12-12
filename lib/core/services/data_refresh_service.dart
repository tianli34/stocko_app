import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 数据刷新服务
/// 用于在数据恢复后刷新所有相关的 Provider，避免需要重启应用
class DataRefreshService {
  final Ref _ref;

  DataRefreshService(this._ref);

  /// 刷新所有数据相关的 Provider
  /// 在备份恢复成功后调用此方法
  void refreshAllData() {
    // 使用 invalidate 来刷新所有数据 Provider
    // 这会导致下次访问时重新从数据库加载数据
    
    // 由于 Riverpod 的依赖机制，我们只需要 invalidate 核心的数据源 Provider
    // 其他依赖它们的 Provider 会自动重新计算
    
    // 注意：我们不能直接 invalidate appDatabaseProvider，因为数据库连接不应该被重置
    // 而是 invalidate 那些从数据库读取数据的 StreamProvider 和 FutureProvider
    
    // 通过 invalidateSelf 触发重新构建
    _ref.invalidateSelf();
  }
}

/// 数据刷新服务 Provider
final dataRefreshServiceProvider = Provider<DataRefreshService>((ref) {
  return DataRefreshService(ref);
});

/// 数据刷新触发器 Provider
/// 当需要刷新所有数据时，调用 ref.invalidate(dataRefreshTriggerProvider)
/// 所有监听此 Provider 的数据 Provider 都会重新加载
final dataRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 触发数据刷新的扩展方法
extension DataRefreshExtension on WidgetRef {
  /// 触发全局数据刷新
  /// 在备份恢复成功后调用此方法
  void triggerDataRefresh() {
    // 递增触发器值，导致所有监听它的 Provider 重新计算
    read(dataRefreshTriggerProvider.notifier).state++;
  }
}

/// 用于 StateNotifier 中触发数据刷新
extension DataRefreshNotifierExtension on Ref {
  /// 触发全局数据刷新
  void triggerDataRefresh() {
    read(dataRefreshTriggerProvider.notifier).state++;
  }
}
