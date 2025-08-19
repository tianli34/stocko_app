import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';

/// 批次列表（按产品+店铺）
final batchesByProductAndShopProvider = FutureProvider.family<
    List<ProductBatchData>, ({int productId, int shopId})>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);
  return db.batchDao.getBatchesByProductAndShop(args.productId, args.shopId);
});
