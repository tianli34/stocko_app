import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/product_groups_table.dart';

part 'product_group_dao.g.dart';

/// 商品组数据访问对象 (DAO)
/// 负责商品组相关的数据库操作
@DriftAccessor(tables: [ProductGroup])
class ProductGroupDao extends DatabaseAccessor<AppDatabase>
    with _$ProductGroupDaoMixin {
  ProductGroupDao(super.db);

  /// 添加商品组
  Future<int> insertProductGroup(ProductGroupCompanion companion) async {
    return await into(db.productGroup).insert(companion);
  }

  /// 根据ID获取商品组
  Future<ProductGroupData?> getProductGroupById(int id) async {
    return await (select(db.productGroup)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取所有商品组
  Future<List<ProductGroupData>> getAllProductGroups() async {
    return await select(db.productGroup).get();
  }

  /// 监听所有商品组变化
  Stream<List<ProductGroupData>> watchAllProductGroups() {
    return select(db.productGroup).watch();
  }

  /// 根据名称搜索商品组
  Future<List<ProductGroupData>> searchProductGroups(String keyword) async {
    return await (select(db.productGroup)
          ..where((tbl) => tbl.name.like('%$keyword%')))
        .get();
  }

  /// 更新商品组
  Future<bool> updateProductGroup(ProductGroupCompanion companion) async {
    return await update(db.productGroup).replace(companion);
  }

  /// 删除商品组
  Future<int> deleteProductGroup(int id) async {
    return await (delete(db.productGroup)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// 检查商品组名称是否已存在
  Future<bool> isProductGroupNameExists(String name, {int? excludeId}) async {
    var query = select(db.productGroup)
      ..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.isNotValue(excludeId));
    }

    final result = await query.get();
    return result.isNotEmpty;
  }
}
