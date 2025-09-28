import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'backup_logger.dart';

/// 资源类型
enum ResourceType {
  temporaryFile,
  temporaryDirectory,
  lockFile,
  cacheFile,
}

/// 资源信息
class ResourceInfo {
  final String id;
  final ResourceType type;
  final String path;
  final DateTime createdAt;
  final String? operation;
  final Map<String, dynamic>? metadata;

  ResourceInfo({
    required this.id,
    required this.type,
    required this.path,
    required this.createdAt,
    this.operation,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        'operation': operation,
        'metadata': metadata,
      };

  factory ResourceInfo.fromJson(Map<String, dynamic> json) => ResourceInfo(
        id: json['id'],
        type: ResourceType.values.firstWhere((e) => e.name == json['type']),
        path: json['path'],
        createdAt: DateTime.parse(json['createdAt']),
        operation: json['operation'],
        metadata: json['metadata'],
      );
}

/// 备份资源管理器
class BackupResourceManager {
  static BackupResourceManager? _instance;
  static BackupResourceManager get instance => _instance ??= BackupResourceManager._();
  
  BackupResourceManager._();

  final BackupLogger _logger = BackupLogger.instance;
  final Map<String, ResourceInfo> _trackedResources = {};
  final Set<String> _activeOperations = {};
  Timer? _cleanupTimer;
  bool _initialized = false;

  /// 初始化资源管理器
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _logger.info('ResourceManager', '初始化资源管理器');
      
      // 清理遗留的临时文件
      await _cleanupOrphanedResources();
      
      // 启动定期清理任务
      _startPeriodicCleanup();
      
      _initialized = true;
      await _logger.info('ResourceManager', '资源管理器初始化完成');
    } catch (e) {
      await _logger.error('ResourceManager', '初始化资源管理器失败', error: e);
      rethrow;
    }
  }

  /// 创建临时文件
  Future<File> createTemporaryFile({
    String? prefix,
    String? suffix,
    String? operation,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _generateFileName(prefix: prefix, suffix: suffix);
      final file = File(path.join(tempDir.path, fileName));
      
      final resourceId = _generateResourceId();
      final resourceInfo = ResourceInfo(
        id: resourceId,
        type: ResourceType.temporaryFile,
        path: file.path,
        createdAt: DateTime.now(),
        operation: operation,
        metadata: metadata,
      );
      
      _trackedResources[resourceId] = resourceInfo;
      
      await _logger.debug('ResourceManager', '创建临时文件: ${file.path}', 
          details: {'resourceId': resourceId, 'operation': operation});
      
      return file;
    } catch (e) {
      await _logger.error('ResourceManager', '创建临时文件失败', error: e);
      rethrow;
    }
  }

  /// 创建临时目录
  Future<Directory> createTemporaryDirectory({
    String? prefix,
    String? operation,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final dirName = _generateFileName(prefix: prefix);
      final directory = Directory(path.join(tempDir.path, dirName));
      
      await directory.create(recursive: true);
      
      final resourceId = _generateResourceId();
      final resourceInfo = ResourceInfo(
        id: resourceId,
        type: ResourceType.temporaryDirectory,
        path: directory.path,
        createdAt: DateTime.now(),
        operation: operation,
        metadata: metadata,
      );
      
      _trackedResources[resourceId] = resourceInfo;
      
      await _logger.debug('ResourceManager', '创建临时目录: ${directory.path}', 
          details: {'resourceId': resourceId, 'operation': operation});
      
      return directory;
    } catch (e) {
      await _logger.error('ResourceManager', '创建临时目录失败', error: e);
      rethrow;
    }
  }

  /// 创建锁文件
  Future<File> createLockFile({
    required String operation,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final locksDir = Directory(path.join(appDir.path, 'locks'));
      
      if (!await locksDir.exists()) {
        await locksDir.create(recursive: true);
      }
      
      final lockFileName = '${operation}_${DateTime.now().millisecondsSinceEpoch}.lock';
      final lockFile = File(path.join(locksDir.path, lockFileName));
      
      // 写入锁文件信息
      final lockInfo = {
        'operation': operation,
        'createdAt': DateTime.now().toIso8601String(),
        'processId': pid,
        'metadata': metadata,
      };
      
      await lockFile.writeAsString(lockInfo.toString());
      
      final resourceId = _generateResourceId();
      final resourceInfo = ResourceInfo(
        id: resourceId,
        type: ResourceType.lockFile,
        path: lockFile.path,
        createdAt: DateTime.now(),
        operation: operation,
        metadata: metadata,
      );
      
      _trackedResources[resourceId] = resourceInfo;
      _activeOperations.add(operation);
      
      await _logger.debug('ResourceManager', '创建锁文件: ${lockFile.path}', 
          details: {'resourceId': resourceId, 'operation': operation});
      
      return lockFile;
    } catch (e) {
      await _logger.error('ResourceManager', '创建锁文件失败', error: e);
      rethrow;
    }
  }

  /// 释放资源
  Future<void> releaseResource(String resourceId) async {
    try {
      final resourceInfo = _trackedResources[resourceId];
      if (resourceInfo == null) {
        await _logger.warning('ResourceManager', '尝试释放不存在的资源: $resourceId');
        return;
      }
      
      await _deleteResource(resourceInfo);
      _trackedResources.remove(resourceId);
      
      if (resourceInfo.operation != null) {
        _activeOperations.remove(resourceInfo.operation);
      }
      
      await _logger.debug('ResourceManager', '释放资源: ${resourceInfo.path}', 
          details: {'resourceId': resourceId, 'type': resourceInfo.type.name});
    } catch (e) {
      await _logger.error('ResourceManager', '释放资源失败', 
          error: e, details: {'resourceId': resourceId});
    }
  }

  /// 释放操作相关的所有资源
  Future<void> releaseOperationResources(String operation) async {
    try {
      final operationResources = _trackedResources.values
          .where((resource) => resource.operation == operation)
          .toList();
      
      for (final resource in operationResources) {
        await releaseResource(resource.id);
      }
      
      _activeOperations.remove(operation);
      
      await _logger.info('ResourceManager', '释放操作相关资源: $operation', 
          details: {'resourceCount': operationResources.length});
    } catch (e) {
      await _logger.error('ResourceManager', '释放操作资源失败', 
          error: e, details: {'operation': operation});
    }
  }

  /// 清理过期资源
  Future<void> cleanupExpiredResources({Duration? maxAge}) async {
    await _ensureInitialized();
    
    try {
      final cutoffTime = DateTime.now().subtract(maxAge ?? const Duration(hours: 24));
      final expiredResources = _trackedResources.values
          .where((resource) => resource.createdAt.isBefore(cutoffTime))
          .toList();
      
      for (final resource in expiredResources) {
        await releaseResource(resource.id);
      }
      
      await _logger.info('ResourceManager', '清理过期资源完成', 
          details: {'cleanedCount': expiredResources.length});
    } catch (e) {
      await _logger.error('ResourceManager', '清理过期资源失败', error: e);
    }
  }

  /// 强制清理所有资源
  Future<void> forceCleanupAllResources() async {
    try {
      final allResources = _trackedResources.values.toList();
      
      for (final resource in allResources) {
        await releaseResource(resource.id);
      }
      
      _activeOperations.clear();
      
      await _logger.info('ResourceManager', '强制清理所有资源完成', 
          details: {'cleanedCount': allResources.length});
    } catch (e) {
      await _logger.error('ResourceManager', '强制清理所有资源失败', error: e);
    }
  }

  /// 检查操作是否正在进行
  bool isOperationActive(String operation) {
    return _activeOperations.contains(operation);
  }

  /// 获取资源统计信息
  Map<String, dynamic> getResourceStats() {
    final stats = <ResourceType, int>{};
    for (final resource in _trackedResources.values) {
      stats[resource.type] = (stats[resource.type] ?? 0) + 1;
    }
    
    return {
      'totalResources': _trackedResources.length,
      'activeOperations': _activeOperations.length,
      'resourcesByType': stats.map((type, count) => MapEntry(type.name, count)),
      'oldestResource': _trackedResources.values.isNotEmpty
          ? _trackedResources.values
              .map((r) => r.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String()
          : null,
    };
  }

  /// 获取所有跟踪的资源
  List<ResourceInfo> getTrackedResources() {
    return _trackedResources.values.toList();
  }

  /// 销毁资源管理器
  Future<void> dispose() async {
    try {
      _cleanupTimer?.cancel();
      await forceCleanupAllResources();
      _initialized = false;
      await _logger.info('ResourceManager', '资源管理器已销毁');
    } catch (e) {
      await _logger.error('ResourceManager', '销毁资源管理器失败', error: e);
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 生成资源ID
  String _generateResourceId() {
    return 'res_${DateTime.now().millisecondsSinceEpoch}_${_trackedResources.length}';
  }

  /// 生成文件名
  String _generateFileName({String? prefix, String? suffix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefixPart = prefix != null ? '${prefix}_' : 'backup_';
    final suffixPart = suffix ?? 'tmp';
    return '$prefixPart$timestamp.$suffixPart';
  }

  /// 删除资源
  Future<void> _deleteResource(ResourceInfo resourceInfo) async {
    try {
      switch (resourceInfo.type) {
        case ResourceType.temporaryFile:
        case ResourceType.lockFile:
        case ResourceType.cacheFile:
          final file = File(resourceInfo.path);
          if (await file.exists()) {
            await file.delete();
          }
          break;
        case ResourceType.temporaryDirectory:
          final directory = Directory(resourceInfo.path);
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
          break;
      }
    } catch (e) {
      await _logger.warning('ResourceManager', '删除资源失败: ${resourceInfo.path}', 
          details: {'error': e.toString()});
    }
  }

  /// 清理孤立资源
  Future<void> _cleanupOrphanedResources() async {
    try {
      // 清理临时目录中的孤立文件
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await _cleanupDirectoryOrphans(tempDir, 'backup_', const Duration(hours: 24));
      }
      
      // 清理锁文件目录
      final appDir = await getApplicationDocumentsDirectory();
      final locksDir = Directory(path.join(appDir.path, 'locks'));
      if (await locksDir.exists()) {
        await _cleanupDirectoryOrphans(locksDir, '', const Duration(hours: 1));
      }
      
      await _logger.info('ResourceManager', '清理孤立资源完成');
    } catch (e) {
      await _logger.error('ResourceManager', '清理孤立资源失败', error: e);
    }
  }

  /// 清理目录中的孤立文件
  Future<void> _cleanupDirectoryOrphans(
    Directory directory,
    String prefix,
    Duration maxAge,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(maxAge);
      final entities = await directory.list().toList();
      
      for (final entity in entities) {
        if (entity is File && entity.path.contains(prefix)) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await entity.delete();
            await _logger.debug('ResourceManager', '删除孤立文件: ${entity.path}');
          }
        }
      }
    } catch (e) {
      await _logger.warning('ResourceManager', '清理目录孤立文件失败: ${directory.path}', 
          details: {'error': e.toString()});
    }
  }

  /// 启动定期清理任务
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      await cleanupExpiredResources();
    });
  }
}