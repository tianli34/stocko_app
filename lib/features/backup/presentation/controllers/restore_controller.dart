import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/models/backup_metadata.dart';
import '../../domain/models/restore_preview.dart';
import '../../domain/models/restore_result.dart';
import '../../domain/models/restore_mode.dart';
import '../../domain/services/i_restore_service.dart';
import '../../domain/common/backup_common.dart';
import '../../data/providers/restore_service_provider.dart';
import '../../data/utils/file_access_helper.dart';

part 'restore_controller.freezed.dart';

/// 恢复控制器状态
@freezed
abstract class RestoreState with _$RestoreState {
  const factory RestoreState({
    /// 是否正在加载
    @Default(false) bool isLoading,
    /// 错误信息
    String? errorMessage,
    /// 选中的备份文件路径
    String? selectedFilePath,
    /// 备份文件元数据
    BackupMetadata? backupMetadata,
    /// 恢复预览信息
    RestorePreview? restorePreview,
    /// 选择的恢复模式
    @Default(RestoreMode.merge) RestoreMode restoreMode,
    /// 是否需要密码
    @Default(false) bool requiresPassword,
    /// 输入的密码
    String? password,
    /// 选择的表（null表示全部）
    List<String>? selectedTables,
    /// 恢复进度信息
    RestoreProgressInfo? progressInfo,
    /// 恢复结果
    RestoreResult? restoreResult,
  }) = _RestoreState;
}

/// 恢复进度信息
@freezed
abstract class RestoreProgressInfo with _$RestoreProgressInfo {
  const factory RestoreProgressInfo({
    required String message,
    required int current,
    required int total,
    @Default(false) bool isCompleted,
    @Default(false) bool isCancelled,
  }) = _RestoreProgressInfo;
}

/// 恢复控制器
class RestoreController extends StateNotifier<RestoreState> {
  final IRestoreService _restoreService;
  CancelToken? _cancelToken;

  RestoreController(this._restoreService) : super(const RestoreState());

  /// 选择备份文件
  Future<void> selectBackupFile() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'backup'],
        allowMultiple: false,
        withData: true, // 确保获取文件数据
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        String? filePath = platformFile.path;
        
        // 如果无法获取路径或路径无效，尝试使用文件数据
        if (filePath == null || !await FileAccessHelper.isFileAccessible(filePath)) {
          if (platformFile.bytes != null) {
            // 将文件数据保存到临时位置
            filePath = await FileAccessHelper.saveToTempFile(platformFile.bytes!, platformFile.name);
            
            // 提示用户文件已复制到临时位置
            state = state.copyWith(
              errorMessage: '原文件路径无法访问，已自动复制到临时位置进行处理',
            );
          } else {
            throw Exception('无法访问选择的文件。请将备份文件复制到下载或文档文件夹后重新选择。');
          }
        }
        
        state = state.copyWith(
          selectedFilePath: filePath,
          backupMetadata: null,
          restorePreview: null,
          requiresPassword: false,
          password: null,
        );
          
        // 尝试验证文件
        await _validateBackupFile(filePath);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: '选择文件失败: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 验证备份文件
  Future<void> _validateBackupFile(String filePath, {String? password}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final metadata = await _restoreService.validateBackupFile(
        filePath,
        password: password,
      );

      state = state.copyWith(
        backupMetadata: metadata,
        requiresPassword: false,
      );

      // 生成预览
      await _generatePreview(filePath, password: password);
    } catch (e) {
      final errorMessage = e.toString();
      
      // 检查是否是加密错误，需要密码
      if (errorMessage.contains('解密') || errorMessage.contains('密码')) {
        state = state.copyWith(
          requiresPassword: true,
          errorMessage: '此备份文件已加密，请输入密码',
        );
      } else {
        state = state.copyWith(
          errorMessage: '验证备份文件失败: $errorMessage',
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 输入密码并验证
  Future<void> validateWithPassword(String password) async {
    if (state.selectedFilePath == null) return;

    state = state.copyWith(password: password);
    await _validateBackupFile(state.selectedFilePath!, password: password);
  }

  /// 生成恢复预览
  Future<void> _generatePreview(String filePath, {String? password}) async {
    try {
      final preview = await _restoreService.previewRestore(
        filePath,
        mode: state.restoreMode,
        password: password,
      );

      state = state.copyWith(restorePreview: preview);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '生成预览失败: ${e.toString()}',
      );
    }
  }

  /// 设置恢复模式
  void setRestoreMode(RestoreMode mode) {
    state = state.copyWith(restoreMode: mode);
    
    // 如果已经选择了文件，重新生成预览以反映新的模式
    if (state.selectedFilePath != null && state.backupMetadata != null) {
      _generatePreview(state.selectedFilePath!, password: state.password);
    }
  }

  /// 设置选择的表
  void setSelectedTables(List<String>? tables) {
    state = state.copyWith(selectedTables: tables);
  }

  /// 开始恢复
  Future<void> startRestore() async {
    if (state.selectedFilePath == null) return;

    try {
      _cancelToken = CancelToken();
      
      state = state.copyWith(
        progressInfo: const RestoreProgressInfo(
          message: '准备开始恢复...',
          current: 0,
          total: 100,
        ),
        restoreResult: null,
        errorMessage: null,
      );

      final result = await _restoreService.restoreFromBackup(
        filePath: state.selectedFilePath!,
        mode: state.restoreMode,
        password: state.password,
        selectedTables: state.selectedTables,
        onProgress: (message, current, total) {
          state = state.copyWith(
            progressInfo: RestoreProgressInfo(
              message: message,
              current: current,
              total: total,
            ),
          );
        },
        cancelToken: _cancelToken,
      );

      state = state.copyWith(
        restoreResult: result,
        progressInfo: state.progressInfo?.copyWith(
          isCompleted: true,
        ),
      );
    } on RestoreCancelledException {
      state = state.copyWith(
        progressInfo: state.progressInfo?.copyWith(
          isCancelled: true,
          isCompleted: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '恢复失败: ${e.toString()}',
        progressInfo: state.progressInfo?.copyWith(
          isCompleted: true,
        ),
      );
    }
  }

  /// 取消恢复
  void cancelRestore() {
    _cancelToken?.cancel();
    state = state.copyWith(
      progressInfo: state.progressInfo?.copyWith(
        isCancelled: true,
        isCompleted: true,
      ),
    );
  }

  /// 重置状态
  void reset() {
    _cancelToken?.cancel();
    state = const RestoreState();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }


}

/// 恢复控制器提供者
final restoreControllerProvider = StateNotifierProvider<RestoreController, RestoreState>((ref) {
  final restoreService = ref.watch(restoreServiceProvider);
  return RestoreController(restoreService);
});