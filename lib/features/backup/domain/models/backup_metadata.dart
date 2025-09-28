import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_metadata.freezed.dart';
part 'backup_metadata.g.dart';

/// 备份文件的元数据信息
@freezed
abstract class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    /// 备份文件的唯一标识符
    required String id,
    /// 备份文件名
    required String fileName,
    /// 创建时间
    required DateTime createdAt,
    /// 文件大小（字节）
    required int fileSize,
    /// 备份格式版本
    required String version,
    /// 各表的记录数量统计
    required Map<String, int> tableCounts,
    /// 数据校验和
    required String checksum,
    /// 是否加密
    @Default(false) bool isEncrypted,
    /// 备份描述
    String? description,
    /// 应用版本
    String? appVersion,
    /// 数据库架构版本
    int? schemaVersion,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}