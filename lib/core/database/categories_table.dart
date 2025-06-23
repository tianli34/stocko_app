import 'package:drift/drift.dart';

/// 类别表定义
/// 用于存储产品类别信息的数据库表结构
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  /// 类别ID - 主键
  TextColumn get id => text()();

  /// 类别名称 - 必填
  /// 添加唯一约束防止重复类别（在同一层级下）
  TextColumn get name => text()();

  /// 父类别ID - 可选，用于构建层级结构
  TextColumn get parentId => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// 添加复合唯一约束：同一父级下的类别名称不能重复
  @override
  List<Set<Column>> get uniqueKeys => [
    {name, parentId}, // 父类别ID + 类别名称的组合必须唯一
  ];
}
