import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'database_initializer.dart';

/// 数据库初始化 Provider
/// 在应用启动时调用，确保数据库有基础数据
final databaseInitializationProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final initializer = DatabaseInitializer(database);

  try {
    await initializer.initializeAllDefaults();
    print('🎉 数据库初始化完成');
  } catch (e) {
    print('💥 数据库初始化失败: $e');
    rethrow;
  }
});

/// 手动重置数据库 Provider（用于开发/测试）
final resetDatabaseProvider = FutureProvider.family<void, bool>((
  ref,
  force,
) async {
  if (!force) return;

  final database = ref.watch(appDatabaseProvider);
  final initializer = DatabaseInitializer(database);

  await initializer.resetAllData();
  ref.invalidateSelf();
});
