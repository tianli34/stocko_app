import 'package:drift/drift.dart';

/// 类别表定义
/// 用于存储产品类别信息的数据库表结构
class Category extends Table {
  /// 类别ID - 主键
  IntColumn get id => integer().autoIncrement()();

  /// 类别名称 - 必填
  /// 添加唯一约束防止重复类别（在同一层级下）
  TextColumn get name => text()();

  /// 父类别ID - 可选，用于构建层级结构
  IntColumn get parentId => integer().nullable()();

  /// 添加复合唯一约束：同一父级下的类别名称不能重复
  @override
  List<Set<Column>> get uniqueKeys => [
    {name, parentId}, // 父类别ID + 类别名称的组合必须唯一
  ];
}
