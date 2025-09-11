import 'package:drift/drift.dart';
import 'package:stocko_app/core/database/product_units_table.dart';

/// 条码表
/// 存储产品单位对应的条码信息
class Barcode extends Table {
  /// 主键 - 条码ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 产品单位ID，关联到product_units表
  IntColumn get unitProductId => integer().references(UnitProduct, #id)();

  /// 条码值
  TextColumn get barcodeValue => text().unique()();
}
