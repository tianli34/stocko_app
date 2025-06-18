import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/locations_table.dart';

part 'location_dao.g.dart';

/// 货位数据访问对象
/// 负责处理货位表的数据库操作
@DriftAccessor(tables: [LocationsTable])
class LocationDao extends DatabaseAccessor<AppDatabase>
    with _$LocationDaoMixin {
  LocationDao(super.db);

  /// 插入货位
  Future<int> insertLocation(LocationsTableCompanion location) async {
    return await into(locationsTable).insert(location);
  }

  /// 根据ID获取货位
  Future<LocationsTableData?> getLocationById(String id) {
    return (select(
      locationsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据编码获取货位
  Future<LocationsTableData?> getLocationByCode(String code, String shopId) {
    return (select(locationsTable)
          ..where((t) => t.code.equals(code) & t.shopId.equals(shopId)))
        .getSingleOrNull();
  }

  /// 获取所有货位
  Future<List<LocationsTableData>> getAllLocations() {
    return select(locationsTable).get();
  }

  /// 根据店铺ID获取货位
  Future<List<LocationsTableData>> getLocationsByShop(String shopId) {
    return (select(
      locationsTable,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据状态获取货位
  Future<List<LocationsTableData>> getLocationsByStatus(String status) {
    return (select(
      locationsTable,
    )..where((t) => t.status.equals(status))).get();
  }

  /// 获取活跃货位
  Future<List<LocationsTableData>> getActiveLocationsByShop(String shopId) {
    return (select(
      locationsTable,
    )..where((t) => t.shopId.equals(shopId) & t.status.equals('active'))).get();
  }

  /// 监听所有货位变化
  Stream<List<LocationsTableData>> watchAllLocations() {
    return select(locationsTable).watch();
  }

  /// 监听指定店铺的货位变化
  Stream<List<LocationsTableData>> watchLocationsByShop(String shopId) {
    return (select(
      locationsTable,
    )..where((t) => t.shopId.equals(shopId))).watch();
  }

  /// 更新货位
  Future<bool> updateLocation(LocationsTableCompanion location) async {
    final result = await (update(
      locationsTable,
    )..where((t) => t.id.equals(location.id.value))).write(location);
    return result > 0;
  }

  /// 删除货位
  Future<int> deleteLocation(String id) {
    return (delete(locationsTable)..where((t) => t.id.equals(id))).go();
  }

  /// 检查货位编码是否已存在（同一店铺内）
  Future<bool> isLocationCodeExists(
    String code,
    String shopId, [
    String? excludeId,
  ]) async {
    var query = select(locationsTable)
      ..where((t) => t.code.equals(code) & t.shopId.equals(shopId));

    if (excludeId != null) {
      query = query..where((t) => t.id.isNotValue(excludeId));
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// 根据名称搜索货位
  Future<List<LocationsTableData>> searchLocationsByName(String searchTerm) {
    return (select(locationsTable)..where(
          (t) => t.name.contains(searchTerm) | t.code.contains(searchTerm),
        ))
        .get();
  }

  /// 获取货位总数
  Future<int> getLocationCount() async {
    final result = await (selectOnly(
      locationsTable,
    )..addColumns([locationsTable.id.count()])).getSingle();
    return result.read(locationsTable.id.count()) ?? 0;
  }

  /// 批量插入货位
  Future<void> insertMultipleLocations(
    List<LocationsTableCompanion> locations,
  ) async {
    await batch((batch) {
      batch.insertAll(locationsTable, locations);
    });
  }
}
