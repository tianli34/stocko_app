import 'package:drift/drift.dart';

/// 商品组表 - 用于聚合同系列不同规格/口味的商品（如乐事薯片的各种口味）
class ProductGroup extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// 商品组名称，如"乐事薯片"
  TextColumn get name => text()();
  
  /// 商品组图片
  TextColumn get image => text().nullable()();
  
  /// 商品组描述
  TextColumn get description => text().nullable()();
  
  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
