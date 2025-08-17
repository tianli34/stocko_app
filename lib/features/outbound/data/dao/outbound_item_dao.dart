import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/outbound_receipt_items_table.dart';

part 'outbound_item_dao.g.dart';

@DriftAccessor(tables: [OutboundItem])
class OutboundItemDao extends DatabaseAccessor<AppDatabase>
    with _$OutboundItemDaoMixin {
  OutboundItemDao(super.db);

  // Methods to interact with the table will be defined here
}