import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart';
import '../../data/dao/purchase_dao.dart';
import '../../../product/data/dao/batch_dao.dart';
import '../../../inbound/data/dao/inbound_receipt_dao.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../inventory/domain/model/batch.dart';
import '../../presentation/screens/create_purchase_screen.dart';
import '../../domain/repository/i_supplier_repository.dart';
import '../../domain/model/supplier.dart';
import '../provider/supplier_providers.dart';

/// 采购服务
/// 处理采购单入库的业务逻辑
class PurchaseService {
  final AppDatabase _database;
  final PurchaseDao _purchaseDao;
  final BatchDao _batchDao;
  final InboundReceiptDao _inboundReceiptDao;
  final InboundItemDao _inboundItemDao;
  final InventoryService _inventoryService;
  final ISupplierRepository _supplierRepository;

  PurchaseService(
    this._database,
    this._inventoryService,
    this._supplierRepository,
  ) : _purchaseDao = _database.purchaseDao,
      _batchDao = _database.batchDao,
      _inboundReceiptDao = _database.inboundReceiptDao,
      _inboundItemDao = _database.inboundItemDao;

  /// 一键入库
  /// 1. 检查并创建供应商（如果不存在）
  /// 2. 写入采购表
  /// 3. 根据条件写入批次表
  /// 4. 写入入库单表、入库单明细表
  /// 5. 间接写入流水表、库存表
  Future<String> processOneClickInbound({
    required String supplierId,
    required String shopId,
    required List<PurchaseItem> purchaseItems,
    String? remarks,
    String? supplierName, // 新增参数：供应商名称，用于自动创建供应商
  }) async {
    print('🚀 开始执行一键入库流程...');
    print('📊 供应商ID: $supplierId');
    print('🏪 店铺ID: $shopId');
    print('📦 采购商品数量: ${purchaseItems.length}');

    return await _database.transaction(() async {
      final now = DateTime.now();

      // 1. 检查并创建供应商（如果不存在）
      final actualSupplierId = await _ensureSupplierExists(
        supplierId,
        supplierName,
      );
      print('✅ 确认供应商ID: $actualSupplierId');

      // 生成采购单号
      final purchaseNumber = await _purchaseDao.generatePurchaseNumber(now);
      print('📝 生成采购单号: $purchaseNumber'); // 2. 写入采购表
      print('⏳ 步骤2: 写入采购表...');
      await _writePurchaseRecords(
        purchaseNumber: purchaseNumber,
        supplierId: actualSupplierId,
        shopId: shopId,
        purchaseItems: purchaseItems,
        purchaseDate: now,
      );

      // 3. 根据条件写入批次表
      print('⏳ 步骤3: 根据条件写入批次表...');
      await _writeBatchRecords(
        shopId: shopId,
        purchaseItems: purchaseItems,
      ); // 4. 写入入库单表、入库单明细表
      print('⏳ 步骤4: 写入入库单表、入库单明细表...');
      final receiptNumber = await _writeInboundRecords(
        shopId: shopId,
        purchaseItems: purchaseItems,
        purchaseNumber: purchaseNumber,
        remarks: remarks,
      ); // 5. 间接写入流水表、库存表
      print('⏳ 步骤5: 间接写入流水表、库存表...');
      await _writeInventoryRecords(
        shopId: shopId,
        purchaseItems: purchaseItems,
      );

      print('🎉 一键入库流程执行完成！入库单号: $receiptNumber');
      return receiptNumber;
    });
  }

  /// 1. 写入采购表
  Future<void> _writePurchaseRecords({
    required String purchaseNumber,
    required String supplierId,
    required String shopId,
    required List<PurchaseItem> purchaseItems,
    required DateTime purchaseDate,
  }) async {
    final companions = <PurchasesTableCompanion>[];

    for (final item in purchaseItems) {
      // 获取单位ID
      final unitId = await _getUnitIdFromUnitName(item.unitName);

      // 为每个商品项创建采购记录
      final companion = PurchasesTableCompanion.insert(
        purchaseNumber: '${purchaseNumber}_${item.id}', // 每个商品项单独的采购单号
        productId: item.productId,
        unitId: unitId,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        productionDate: item.productionDate ?? purchaseDate,
        shopId: shopId,
        supplierId: supplierId,
        purchaseDate: purchaseDate,
      );
      companions.add(companion);
    }

    await _purchaseDao.insertMultiplePurchases(companions);
    print('✅ 采购记录写入完成，共 ${companions.length} 条');
  }

  /// 2. 根据条件写入批次表
  Future<void> _writeBatchRecords({
    required String shopId,
    required List<PurchaseItem> purchaseItems,
  }) async {
    for (final item in purchaseItems) {
      // 检查产品是否启用批次管理
      final product = await _database.productDao.getProductById(item.productId);

      if (product?.enableBatchManagement == true &&
          item.productionDate != null) {
        final batchNumber = Batch.generateBatchNumber(
          item.productId,
          item.productionDate!,
        );

        // 检查批次是否已存在
        final existingBatch = await _batchDao.getBatchByNumber(batchNumber);

        if (existingBatch != null) {
          // 如果批次已存在，累加初始数量
          final newInitialQuantity =
              existingBatch.initialQuantity + item.quantity;
          await _batchDao.updateBatchQuantity(batchNumber, newInitialQuantity);
          print('📦 批次 $batchNumber 数量累加: ${item.quantity}');
        } else {
          // 如果批次不存在，创建新批次
          await _batchDao.createBatch(
            productId: item.productId,
            productionDate: item.productionDate!,
            initialQuantity: item.quantity,
            shopId: shopId,
          );
          print('📦 新建批次 $batchNumber: ${item.quantity}');
        }
      }
    }
  }

  /// 3. 写入入库单表、入库单明细表
  Future<String> _writeInboundRecords({
    required String shopId,
    required List<PurchaseItem> purchaseItems,
    required String purchaseNumber,
    String? remarks,
  }) async {
    final now = DateTime.now();

    // 创建入库单主记录
    final receiptId = 'receipt_${now.millisecondsSinceEpoch}';
    final receiptNumber = await _inboundReceiptDao.generateReceiptNumber(now);

    final receipt = InboundReceiptsTableCompanion(
      id: drift.Value(receiptId),
      receiptNumber: drift.Value(receiptNumber),
      status: const drift.Value('completed'), // 一键入库直接完成
      remarks: drift.Value(remarks),
      shopId: drift.Value(shopId),
      submittedAt: drift.Value(now),
      completedAt: drift.Value(now),
    );

    await _inboundReceiptDao.insertInboundReceipt(receipt);
    print('✅ 入库单创建完成: $receiptNumber'); // 创建入库单明细记录
    final itemCompanions = <InboundReceiptItemsTableCompanion>[];

    for (final item in purchaseItems) {
      final product = await _database.productDao.getProductById(item.productId);
      final unitId = await _getUnitIdFromUnitName(item.unitName);

      final itemCompanion = InboundReceiptItemsTableCompanion(
        id: drift.Value('item_${now.millisecondsSinceEpoch}_${item.id}'),
        receiptId: drift.Value(receiptId),
        productId: drift.Value(item.productId),
        quantity: drift.Value(item.quantity),
        unitId: drift.Value(unitId),
        productionDate: drift.Value(item.productionDate),
        locationId: const drift.Value.absent(), // 采购入库暂不指定货位
        purchaseQuantity: drift.Value(item.quantity),
        purchaseOrderId: drift.Value('${purchaseNumber}_${item.id}'),
        batchNumber:
            item.productionDate != null &&
                product?.enableBatchManagement == true
            ? drift.Value(
                Batch.generateBatchNumber(item.productId, item.productionDate!),
              )
            : const drift.Value.absent(),
      );
      itemCompanions.add(itemCompanion);
    }

    await _inboundItemDao.insertMultipleInboundItems(itemCompanions);
    print('✅ 入库明细创建完成，共 ${itemCompanions.length} 条');

    return receiptNumber;
  }

  /// 4. 间接写入流水表、库存表
  Future<void> _writeInventoryRecords({
    required String shopId,
    required List<PurchaseItem> purchaseItems,
  }) async {
    for (final item in purchaseItems) {
      final product = await _database.productDao.getProductById(item.productId);

      // 根据产品批次管理设置决定批次号生成策略
      final batchNumber =
          item.productionDate != null && product?.enableBatchManagement == true
          ? Batch.generateBatchNumber(item.productId, item.productionDate!)
          : 'BATCH_${DateTime.now().millisecondsSinceEpoch}_${item.id}';

      final success = await _inventoryService.inbound(
        productId: item.productId,
        shopId: shopId,
        batchNumber: batchNumber,
        quantity: item.quantity,
        time: DateTime.now(),
      );

      if (!success) {
        throw Exception('商品 ${item.productName} 库存更新失败');
      }

      print('✅ 商品 ${item.productName} 库存更新完成');
    }
  }

  /// 根据单位名称获取单位ID
  Future<String> _getUnitIdFromUnitName(String unitName) async {
    try {
      final unitDao = _database.unitDao;
      final unit = await unitDao.getUnitByName(unitName);
      if (unit != null) {
        return unit.id;
      }

      // 如果找不到对应单位，根据常见映射返回
      final unitMapping = {
        '瓶': 'unit_bottle',
        '包': 'unit_package',
        '箱': 'unit_box',
        '千克': 'unit_kg',
        '个': 'unit_piece',
      };

      final mappedUnitId = unitMapping[unitName];
      if (mappedUnitId != null) {
        print('🔄 使用映射单位: $unitName -> $mappedUnitId');
        return mappedUnitId;
      }

      // 如果都找不到，返回默认单位
      print('⚠️ 未找到单位 "$unitName"，使用默认单位');
      return 'unit_piece'; // 默认单位
    } catch (e) {
      print('⚠️ 查询单位失败: $e，使用默认单位');
      return 'unit_piece'; // 默认单位
    }
  }

  /// 确保供应商存在，如果不存在则创建
  Future<String> _ensureSupplierExists(
    String supplierId,
    String? supplierName,
  ) async {
    // 首先尝试根据ID获取供应商
    final existingSupplier = await _supplierRepository.getSupplierById(
      supplierId,
    );
    if (existingSupplier != null) {
      print('✅ 供应商已存在: ${existingSupplier.name}');
      return supplierId;
    }

    // 如果没有提供供应商名称，无法创建新供应商
    if (supplierName == null || supplierName.trim().isEmpty) {
      throw Exception('供应商不存在且未提供供应商名称，无法自动创建');
    }

    // 检查是否有重名的供应商
    final supplierByName = await _supplierRepository.getSupplierByName(
      supplierName,
    );
    if (supplierByName != null) {
      print('✅ 找到重名供应商，使用现有供应商: ${supplierByName.name}');
      return supplierByName.id;
    }

    // 创建新供应商
    final newSupplier = Supplier(id: supplierId, name: supplierName.trim());

    try {
      await _supplierRepository.addSupplier(newSupplier);
      print('✅ 自动创建新供应商: ${newSupplier.name} (ID: ${newSupplier.id})');
      return newSupplier.id;
    } catch (e) {
      print('❌ 创建供应商失败: $e');
      throw Exception('创建供应商失败: $e');
    }
  }
}

/// 采购服务提供者
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  final supplierRepository = ref.watch(supplierRepositoryProvider);
  return PurchaseService(database, inventoryService, supplierRepository);
});
