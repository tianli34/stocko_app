import 'package:drift/drift.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'categories_table.dart';
import 'units_table.dart';
import 'product_groups_table.dart';

// --- 类型转换器 ---
class MoneyConverter extends TypeConverter<Money, int> {
  const MoneyConverter();
  @override
  Money fromSql(int fromDb) {
    return Money(fromDb);
  }

  @override
  int toSql(Money value) {
    return value.cents;
  }
}

class Product extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable().customConstraint('UNIQUE')();
  TextColumn get image => text().nullable()();
  IntColumn get baseUnitId => integer().references(Unit, #id)();
  IntColumn get categoryId => integer().references(Category, #id).nullable()();
  
  /// 商品组ID - 用于关联同系列商品（如乐事薯片的各种口味），可空表示普通商品
  IntColumn get groupId => integer().references(ProductGroup, #id).nullable()();
  
  /// 变体名称 - 如"黄瓜味"、"番茄味"，仅当 groupId 不为空时有意义
  TextColumn get variantName => text().nullable()();
  
  TextColumn get specification => text().nullable()();
  TextColumn get brand => text().nullable()();

  // 使用 MoneyConverter，列名更简洁
  IntColumn get cost =>
      integer().map(const MoneyConverter()).nullable()();
  IntColumn get suggestedRetailPrice =>
      integer().map(const MoneyConverter()).nullable()();
  IntColumn get retailPrice =>
      integer().map(const MoneyConverter()).nullable()();
  IntColumn get promotionalPrice =>
      integer().map(const MoneyConverter()).nullable()();

  IntColumn get stockWarningValue => integer().nullable()();
  IntColumn get shelfLife =>
      integer().nullable()(); // 注释：保质期数值，单位由 shelfLifeUnit 决定

  TextColumn get shelfLifeUnit => text()
      .map(const EnumNameConverter(ShelfLifeUnit.values))
      .withDefault(Constant(ShelfLifeUnit.months.name))();

  BoolColumn get enableBatchManagement =>
      boolean().withDefault(const Constant(false))();

  TextColumn get status => text()
      .map(const EnumNameConverter(ProductStatus.values))
      .withDefault(Constant(ProductStatus.active.name))();

  TextColumn get remarks => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();
}
