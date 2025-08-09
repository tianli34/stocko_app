import 'package:drift/drift.dart';

/// 单位表
/// 存储产品的计量单位信息（如 kg, pcs, m）
class Unit extends Table {

  IntColumn get id => integer().autoIncrement()();

  /// 单位名称（唯一，例如 "千克"、"米"、"件"）
  TextColumn get name => text().unique()();
}
