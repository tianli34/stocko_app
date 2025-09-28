import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/backup_metadata.dart';
import '../../domain/services/i_backup_service.dart';
import '../../data/providers/backup_service_provider.dart';

part 'backup_management_controller.freezed.dart';

/// 备份管理状态
@freezed
abstract class BackupManagementState with _$BackupManagementState {
  const factory BackupManagementState({
    @Default(false) bool isLoading,
    @Default([]) List<BackupMetadata> backups,
    String? errorMessage,
  }) = _BackupManagementState;
}

/// 备份管理控制器
class BackupManagementController extends StateNotifier<BackupManagementState> {
  final IBackupService _backupService;

  BackupManagementController(this._backupService) : super(const BackupManagementState());

  /// 刷新备份列表
  Future<void> refreshBackups() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final backups = await _backupService.getLocalBackups();
      // 按创建时间倒序排列（最新的在前面）
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      state = state.copyWith(
        isLoading: false,
        backups: backups,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    try {
      final success = await _backupService.deleteBackup(backupId);
      if (success) {
        // 从列表中移除已删除的备份
        final updatedBackups = state.backups.where((backup) => backup.id != backupId).toList();
        state = state.copyWith(backups: updatedBackups);
      } else {
        throw Exception('删除备份失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 重命名备份
  Future<void> renameBackup(String backupId, String newName) async {
    try {
      // 找到要重命名的备份
      final backupIndex = state.backups.indexWhere((backup) => backup.id == backupId);
      if (backupIndex == -1) {
        throw Exception('找不到指定的备份文件');
      }

      // 创建新的备份元数据
      final oldBackup = state.backups[backupIndex];
      final updatedBackup = oldBackup.copyWith(fileName: newName);

      // 更新列表
      final updatedBackups = List<BackupMetadata>.from(state.backups);
      updatedBackups[backupIndex] = updatedBackup;

      state = state.copyWith(backups: updatedBackups);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取备份详情
  Future<BackupMetadata?> getBackupDetails(String filePath) async {
    try {
      return await _backupService.getBackupInfo(filePath);
    } catch (e) {
      return null;
    }
  }

  /// 验证备份文件
  Future<bool> validateBackup(String filePath) async {
    try {
      return await _backupService.validateBackupFile(filePath);
    } catch (e) {
      return false;
    }
  }
}

/// 备份管理控制器提供者
final backupManagementControllerProvider = 
    StateNotifierProvider<BackupManagementController, BackupManagementState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupManagementController(backupService);
});

/// 备份数量提供者
final backupCountProvider = Provider<int>((ref) {
  final state = ref.watch(backupManagementControllerProvider);
  return state.backups.length;
});

/// 总备份大小提供者
final totalBackupSizeProvider = Provider<int>((ref) {
  final state = ref.watch(backupManagementControllerProvider);
  return state.backups.fold(0, (sum, backup) => sum + backup.fileSize);
});