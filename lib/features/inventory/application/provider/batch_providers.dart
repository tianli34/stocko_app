import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';

/// 根据批次号获取批次信息
final batchByNumberProvider =
    FutureProvider.family<ProductBatchData?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  return db.batchDao.getBatchByNumber(id);
});