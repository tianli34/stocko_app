import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart';
import '../../../purchase/data/dao/purchase_dao.dart';
import '../../../product/data/dao/batch_dao.dart';
import '../../../inbound/data/dao/inbound_receipt_dao.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';
import '../../../purchase/data/dao/product_supplier_dao.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../inventory/domain/model/batch.dart';
import '../../domain/model/inbound_item.dart';
import '../../../purchase/domain/repository/i_supplier_repository.dart';
import '../../../purchase/domain/model/supplier.dart';
import '../../../purchase/application/provider/supplier_providers.dart';

/// 入库服务
/// 处理入库单的业务逻辑
class InboundService {
  final AppDatabase _database;
  final PurchaseDao _purchaseDao;
  final BatchDao _batchDao;
  final InboundReceiptDao _inboundReceiptDao;
  final InboundItemDao _inboundItemDao;
  final ProductSupplierDao _productSupplierDao;
  final InventoryService _inventoryService;
  final ISupplierRepository _supplierRepository;

  InboundService(
    this._database,
    this._inventoryService,
    this._supplierRepository,
  ) : _purchaseDao = _database.purchaseDao,
      _batchDao = _database.batchDao,
      _inboundReceiptDao = _database.inboundReceiptDao,
      _inboundItemDao = _database.inboundItemDao,
      _productSupplierDao = _database.productSupplierDao;

  /// 一键入库
  /// 1. 如果是采购模式，检查并创建供应商、创建采购单、写入货品供应商关联
  /// 2. 写入批次表
  /// 3. 写入入库单表、入库单明细表
  /// 4. 更新库存
  Future<String> processOneClickInbound({
    required String shopId,
    required List<InboundItem> inboundItems,
    required String source,
    required bool isPurchaseMode,
    String? supplierId,
    String? supplierName,
    String? remarks,
  }) async {
    print('🚀 开始执行一键入库流程...');
    print('📦 模式: ${isPurchaseMode ? "采购" : "非采购"}');
    print('🏪 店铺ID: $shopId');
    print('📦 商品数量: ${inboundItems.length}');
    print('ℹ️ 来源: $source');

    return await _database.transaction(() async {
      final now = DateTime.now();
      int? purchaseOrderId;
      String? purchaseOrderNumber;

      if (isPurchaseMode) {
        // --- 采购模式下的特定逻辑 ---
        if (supplierId == null) {
          throw Exception("采购模式下，supplierId不能为空");
        }
        // 1. 检查并创建供应商
        final actualSupplierId = await _ensureSupplierExists(
          supplierId,
          supplierName,
        );
        print('✅ 确认供应商ID: $actualSupplierId');

        // 2. 创建完整的采购订单
        print('⏳ 步骤2: 创建采购订单...');
        final purchaseOrderData = await _createPurchaseOrder(
          supplierId: actualSupplierId,
          shopId: shopId,
          purchaseItems: inboundItems,
          purchaseDate: now,
        );
        purchaseOrderId = purchaseOrderData.orderId;
        purchaseOrderNumber = purchaseOrderData.orderNumber;
        print('✅ 采购订单创建完成，ID: $purchaseOrderId');

        // 4. 写入货品供应商关联表
        print('⏳ 步骤4: 写入货品供应商关联表...');
        await _writeProductSupplierRecords(
          supplierId: actualSupplierId,
          purchaseItems: inboundItems,
        );
      }

      // --- 通用逻辑 ---
      // 3. 根据条件写入批次表
      print('⏳ 步骤3: 根据条件写入批次表...');
      await _writeBatchRecords(shopId: shopId, inboundItems: inboundItems);

      // 5. 写入入库单表、入库单明细表
      print('⏳ 步骤5: 写入入库单表、入库单明细表...');
      final receiptNumber = await _writeInboundRecords(
        shopId: shopId,
        inboundItems: inboundItems,
        purchaseOrderId: purchaseOrderId,
        purchaseOrderNumber: purchaseOrderNumber,
        remarks: remarks,
        source: source, // 传递 source
      );

      // 6. 间接写入流水表、库存表
      print('⏳ 步骤6: 间接写入流水表、库存表...');
      await _writeInventoryRecords(shopId: shopId, inboundItems: inboundItems);

      print('🎉 一键入库流程执行完成！入库单号: $receiptNumber');
      return receiptNumber;
    });
  }

  /// 创建采购订单（包括订单头和所有明细）
  Future<({int orderId, String orderNumber})> _createPurchaseOrder({
    required String supplierId,
    required String shopId,
    required List<InboundItem> purchaseItems,
    required DateTime purchaseDate,
  }) async {
    // 生成采购单号
    final purchaseNumber = await _purchaseDao.generatePurchaseNumber(
      purchaseDate,
    );

    // 准备订单头
    final orderCompanion = PurchaseOrdersTableCompanion(
      purchaseOrderNumber: drift.Value(purchaseNumber),
      supplierId: drift.Value(supplierId),
      shopId: drift.Value(shopId),
      purchaseDate: drift.Value(purchaseDate),
      status: const drift.Value('completed'), // 一键入库直接完成
    );

    // 准备订单明细列表
    final itemCompanions = <PurchaseOrderItemsTableCompanion>[];
    for (final item in purchaseItems) {
      final unitId = await _getUnitIdFromUnitName(item.unitName);
      itemCompanions.add(
        PurchaseOrderItemsTableCompanion(
          productId: drift.Value(item.productId),
          unitId: drift.Value(unitId),
          quantity: drift.Value(item.quantity),
          unitPrice: drift.Value(item.unitPrice),
          productionDate: drift.Value(item.productionDate),
        ),
      );
    }

    // 调用DAO中的事务方法创建完整订单
    final orderId = await _purchaseDao.createFullPurchaseOrder(
      order: orderCompanion,
      items: itemCompanions,
    );

    return (orderId: orderId, orderNumber: purchaseNumber);
  }

  /// 根据条件写入批次表
  Future<void> _writeBatchRecords({
    required String shopId,
    required List<InboundItem> inboundItems,
  }) async {
    for (final item in inboundItems) {
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

  /// 写入货品供应商关联表
  Future<void> _writeProductSupplierRecords({
    required String supplierId,
    required List<InboundItem> purchaseItems,
  }) async {
    print('📋 开始处理货品供应商关联...');

    for (final item in purchaseItems) {
      try {
        // 获取单位ID
        final unitId = await _getUnitIdFromUnitName(item.unitName);

        // 检查该商品-供应商-单位的关联是否已存在
        final exists = await _productSupplierDao.existsProductSupplierWithUnit(
          item.productId,
          supplierId,
          unitId,
        );

        if (exists) {
          // 如果关联已存在，更新供货价格（如果有变化）
          final existingRelations = await _productSupplierDao
              .getSuppliersByProductIdAndUnitId(item.productId, unitId);

          if (existingRelations.isNotEmpty) {
            final existingRelation = existingRelations.firstWhere(
              (relation) => relation.supplierId == supplierId,
              orElse: () => existingRelations.first,
            );

            // 如果价格有变化，更新供货价格
            if (existingRelation.supplyPrice != item.unitPrice) {
              final updatedRelation = existingRelation.copyWith(
                supplyPrice: drift.Value(item.unitPrice),
                updatedAt: DateTime.now(),
              );
              await _productSupplierDao.updateProductSupplier(updatedRelation);
              print(
                '📝 更新 ${item.productName}(${item.unitName}) 的供货价格: ${item.unitPrice}',
              );
            } else {
              print('✅ ${item.productName}(${item.unitName}) 的供应商关联已存在，无需更新');
            }
          }
        } else {
          // 如果关联不存在，创建新的关联记录
          final relationId =
              '${item.productId}_${supplierId}_${unitId}_${DateTime.now().millisecondsSinceEpoch}';

          final companion = ProductSuppliersTableCompanion.insert(
            id: relationId,
            productId: item.productId,
            supplierId: supplierId,
            unitId: unitId,
            supplierProductName: drift.Value(item.productName),
            supplyPrice: drift.Value(item.unitPrice),
            isPrimary: const drift.Value(false), // 默认不设为主要供应商
            status: const drift.Value('active'),
            remarks: const drift.Value('通过采购单自动创建'),
          );

          await _productSupplierDao.insertProductSupplier(companion);
          print(
            '✅ 新建货品供应商关联: ${item.productName}(${item.unitName}) - $supplierId',
          );
        }
      } catch (e) {
        print('❌ 处理 ${item.productName} 的供应商关联失败: $e');
        // 不抛出异常，继续处理其他商品
      }
    }

    print('📋 货品供应商关联处理完成');
  }

  /// 写入入库单表、入库单明细表
  Future<String> _writeInboundRecords({
    required String shopId,
    required List<InboundItem> inboundItems,
    required String source,
    int? purchaseOrderId,
    String? purchaseOrderNumber,
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
      source: drift.Value(source),
    );

    await _inboundReceiptDao.insertInboundReceipt(receipt);
    print('✅ 入库单创建完成: $receiptNumber'); // 创建入库单明细记录
    final itemCompanions = <InboundReceiptItemsTableCompanion>[];

    for (final item in inboundItems) {
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
        purchaseOrderId: drift.Value(purchaseOrderId?.toString()),
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

  /// 间接写入流水表、库存表
  Future<void> _writeInventoryRecords({
    required String shopId,
    required List<InboundItem> inboundItems,
  }) async {
    for (final item in inboundItems) {
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
  Future<int> _getUnitIdFromUnitName(String unitName) async {
    try {
      final unitDao = _database.unitDao;
      final unit = await unitDao.getUnitByName(unitName);
      if (unit != null) {
        return unit.id;
      }

      // 如果找不到对应单位，根据常见映射返回
      // 注意：这里硬编码了ID，这在实际应用中可能不是最佳实践
      // 最好是确保所有单位都已预先插入数据库
      final unitMapping = {
        '个': 1,
        '箱': 2,
        '包': 3,
        '公斤': 4,
        '克': 5,
        '升': 6,
        '毫升': 7,
      };

      final mappedUnitId = unitMapping[unitName];
      if (mappedUnitId != null) {
        print('🔄 使用映射单位: $unitName -> $mappedUnitId');
        return mappedUnitId;
      }

      // 如果都找不到，返回默认单位 "个" 的ID
      print('⚠️ 未找到单位 "$unitName"，使用默认单位 "个"');
      final defaultUnit = await unitDao.getUnitByName('个');
      if (defaultUnit != null) {
        return defaultUnit.id;
      }
      return 1; // Fallback to ID 1 for '个'
    } catch (e) {
      print('⚠️ 查询单位失败: $e，使用默认单位 "个"');
      return 1; // 默认单位 "个" 的ID
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

/// 入库服务提供者
final inboundServiceProvider = Provider<InboundService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  final supplierRepository = ref.watch(supplierRepositoryProvider);
  return InboundService(database, inventoryService, supplierRepository);
});
