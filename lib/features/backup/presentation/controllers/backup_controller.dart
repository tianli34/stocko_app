import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/backup_options.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/services/i_backup_service.dart';
import '../../domain/common/backup_common.dart';
import '../../data/providers/backup_service_provider.dart';
import '../widgets/backup_progress_dialog.dart';

part 'backup_controller.freezed.dart';

/// 备份控制器状态
@freezed
abstract class BackupState with _$BackupState {
  const factory BackupState({
    /// 是否正在备份
    @Default(false) bool isBackingUp,

    /// 错误信息
    String? errorMessage,

    /// 备份进度信息
    BackupProgressInfo? progressInfo,

    /// 备份结果元数据
    BackupMetadata? resultMetadata,

    /// 备份文件路径
    String? resultFilePath,
  }) = _BackupState;
}

/// 备份控制器
class BackupController extends StateNotifier<BackupState> {
  final IBackupService _backupService;
  CancelToken? _cancelToken;

  BackupController(this._backupService) : super(const BackupState());

  /// 开始备份
  Future<void> startBackup({
    BackupOptions? options,
  }) async {
    try {
      _cancelToken = CancelToken();

      state = state.copyWith(
        isBackingUp: true,
        errorMessage: null,
        progressInfo: const BackupProgressInfo(
          message: '准备开始备份...',
          current: 0,
          total: 100,
        ),
        resultMetadata: null,
        resultFilePath: null,
      );

      final result = await _backupService.createBackup(
        options: options,
        onProgress: (message, current, total) {
          if (!mounted) return;
          
          state = state.copyWith(
            progressInfo: BackupProgressInfo(
              message: message,
              current: current,
              total: total,
            ),
          );
        },
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      if (result.success) {
        state = state.copyWith(
          isBackingUp: false,
          progressInfo: state.progressInfo?.copyWith(
            isCompleted: true,
            message: '备份完成',
          ),
          resultMetadata: result.metadata,
          resultFilePath: result.filePath,
        );
      } else {
        state = state.copyWith(
          isBackingUp: false,
          errorMessage: result.errorMessage,
          progressInfo: state.progressInfo?.copyWith(
            isCompleted: true,
            errorMessage: result.errorMessage,
          ),
        );
      }
    } on BackupCancelledException {
      if (!mounted) return;
      
      state = state.copyWith(
        isBackingUp: false,
        progressInfo: state.progressInfo?.copyWith(
          isCancelled: true,
          isCompleted: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = '备份失败: ${e.toString()}';
      state = state.copyWith(
        isBackingUp: false,
        errorMessage: errorMessage,
        progressInfo: state.progressInfo?.copyWith(
          isCompleted: true,
          errorMessage: errorMessage,
        ),
      );
    }
  }

  /// 取消备份
  void cancelBackup() {
    _cancelToken?.cancel();
    
    if (state.isBackingUp) {
      state = state.copyWith(
        isBackingUp: false,
        progressInfo: state.progressInfo?.copyWith(
          isCancelled: true,
          isCompleted: true,
        ),
      );
    }
  }

  /// 重试备份
  Future<void> retryBackup({BackupOptions? options}) async {
    await startBackup(options: options);
  }

  /// 重置状态
  void reset() {
    _cancelToken?.cancel();
    state = const BackupState();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 估算备份大小
  Future<int> estimateBackupSize() async {
    try {
      return await _backupService.estimateBackupSize();
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

/// 备份控制器提供者
final backupControllerProvider =
    StateNotifierProvider<BackupController, BackupState>((ref) {
      final backupService = ref.watch(backupServiceProvider);
      return BackupController(backupService);
    });