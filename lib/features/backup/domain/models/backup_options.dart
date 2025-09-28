import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_options.freezed.dart';
part 'backup_options.g.dart';

/// 备份选项配置
@freezed
abstract class BackupOptions with _$BackupOptions {
  const factory BackupOptions({
    /// 自定义备份名称
    String? customName,
    /// 是否包含图片文件
    @Default(false) bool includeImages,
    /// 是否加密备份
    @Default(false) bool encrypt,
    /// 加密密码
    String? password,
    /// 要包含的表名列表（为空则包含所有表）
    List<String>? includeTables,
    /// 要排除的表名列表
    @Default([]) List<String> excludeTables,
    /// 是否压缩备份文件
    @Default(false) bool compress,
    /// 备份描述
    String? description,
  }) = _BackupOptions;

  factory BackupOptions.fromJson(Map<String, dynamic> json) =>
      _$BackupOptionsFromJson(json);
}