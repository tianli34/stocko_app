import 'package:freezed_annotation/freezed_annotation.dart';
import 'backup_metadata.dart';

part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

/// 完整的备份数据结构
@freezed
abstract class BackupData with _$BackupData {
  const factory BackupData({
    /// 备份元数据
    required BackupMetadata metadata,
    /// 各表的数据，键为表名，值为记录列表
    required Map<String, List<Map<String, dynamic>>> tables,
    /// 应用设置数据（可选）
    Map<String, dynamic>? settings,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}