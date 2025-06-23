import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 检查条码表数据的简单工具
/// 用于验证辅单位条码是否正确写入数据库
void main() async {
  try {
    // 获取数据库路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stocko_app_database.db');

    // 打开数据库
    final database = await openDatabase(path);

    print('🔍 开始检查条码表...\n');

    // 1. 检查条码表结构
    final tableInfo = await database.rawQuery('PRAGMA table_info(barcodes)');
    print('📋 条码表结构:');
    for (final column in tableInfo) {
      print(
        '  - ${column['name']}: ${column['type']} (${column['notnull'] == 1 ? 'NOT NULL' : 'NULL'})',
      );
    }
    print('');

    // 2. 查询所有条码数据
    final allBarcodes = await database.query('barcodes');
    print('📊 条码表总数据量: ${allBarcodes.length}');
    print('');

    if (allBarcodes.isNotEmpty) {
      print('🔢 所有条码数据:');
      for (int i = 0; i < allBarcodes.length; i++) {
        final barcode = allBarcodes[i];
        print('  ${i + 1}. ID: ${barcode['id']}');
        print('     产品单位ID: ${barcode['product_unit_id']}');
        print('     条码值: ${barcode['barcode']}');
        print('     创建时间: ${barcode['created_at']}');
        print('     更新时间: ${barcode['updated_at']}');
        print('');
      }
    }

    // 3. 查询产品单位表，看看有哪些ProductUnit
    final productUnits = await database.query('product_units');
    print('📦 产品单位表数据量: ${productUnits.length}');
    if (productUnits.isNotEmpty) {
      print('🔗 产品单位数据:');
      for (int i = 0; i < productUnits.length; i++) {
        final unit = productUnits[i];
        print('  ${i + 1}. ProductUnit ID: ${unit['product_unit_id']}');
        print('     产品ID: ${unit['product_id']}');
        print('     单位ID: ${unit['unit_id']}');
        print('     换算率: ${unit['conversion_rate']}');

        // 查询该产品单位的条码
        final unitBarcodes = await database.query(
          'barcodes',
          where: 'product_unit_id = ?',
          whereArgs: [unit['product_unit_id']],
        );

        if (unitBarcodes.isNotEmpty) {
          print(
            '     关联条码: ${unitBarcodes.map((b) => b['barcode']).join(', ')}',
          );
        } else {
          print('     关联条码: 无');
        }
        print('');
      }
    }

    // 4. 检查索引
    final indexes = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='barcodes'",
    );
    print('📇 条码表索引:');
    for (final index in indexes) {
      print('  - ${index['name']}');
    }
    print('');

    // 5. 检查最近添加的条码（按创建时间排序）
    final recentBarcodes = await database.query(
      'barcodes',
      orderBy: 'created_at DESC',
      limit: 10,
    );

    if (recentBarcodes.isNotEmpty) {
      print('🕒 最近添加的10个条码:');
      for (int i = 0; i < recentBarcodes.length; i++) {
        final barcode = recentBarcodes[i];
        print('  ${i + 1}. ${barcode['barcode']} (${barcode['created_at']})');
      }
    }

    await database.close();
    print('\n✅ 数据库检查完成');
  } catch (e) {
    print('❌ 检查数据库时出错: $e');
  }
}
