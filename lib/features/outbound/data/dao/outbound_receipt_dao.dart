import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/outbound_receipts_table.dart';

part 'outbound_receipt_dao.g.dart';

@DriftAccessor(tables: [OutboundReceipt])
class OutboundReceiptDao extends DatabaseAccessor<AppDatabase>
    with _$OutboundReceiptDaoMixin {
  OutboundReceiptDao(super.db);

  // Methods to interact with the table will be defined here
}