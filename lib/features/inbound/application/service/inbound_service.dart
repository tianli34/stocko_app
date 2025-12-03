import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart';
import '../../../purchase/data/dao/purchase_dao.dart';
import '../../../product/data/dao/batch_dao.dart';
import '../../../inbound/data/dao/inbound_receipt_dao.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';
// import '../../../purchase/data/dao/product_supplier_dao.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../inventory/application/service/weighted_average_price_service.dart';
import '../../application/provider/inbound_list_provider.dart';
import '../../domain/model/inbound_item.dart';
import '../../../purchase/domain/repository/i_supplier_repository.dart';
import '../../../purchase/domain/model/supplier.dart';
import '../../../purchase/application/provider/supplier_providers.dart';
import '../../../../core/database/purchase_orders_table.dart';

/// A private record type to hold both domain model and UI-related info internally.
typedef _PurchaseItem = ({
  InboundItemModel model,
  int unitPriceInSis,
  String productName,
  String unitName,
  DateTime? productionDate
});

/// 入库服务
/// 处理入库单的业务逻辑
class InboundService {
  final AppDatabase _database;
  final PurchaseDao _purchaseDao;
  final BatchDao _batchDao;
  final InboundReceiptDao _inboundReceiptDao;
  final InboundItemDao _inboundItemDao;
  // final ProductSupplierDao _productSupplierDao;
  final InventoryService _inventoryService;
  final WeightedAveragePriceService _weightedAveragePriceService;
  final ISupplierRepository _supplierRepository;

  InboundService(
    this._database,
    this._inventoryService,
    this._weightedAveragePriceService,
    this._supplierRepository,
  ) : _purchaseDao = _database.purchaseDao,
      _batchDao = _database.batchDao,
      _inboundReceiptDao = _database.inboundReceiptDao,
      _inboundItemDao = _database.inboundItemDao;
      // _productSupplierDao = _database.productSupplierDao;

  /// 将UI状态模型转换为内部处理用的元组列表（共享方法）
  Future<List<_PurchaseItem>> _convertToInternalItems(
    List<InboundItemState> inboundItems,
  ) async {
    return await Future.wait(inboundItems.map((item) async {
      // 根据productId和unitId查找unitProductId
      final unitProduct = await _database.productUnitDao.getUnitProductByProductAndUnit(
        item.productId,
        item.unitId,
      );
      if (unitProduct == null) {
        throw Exception('未找到产品${item.productName}的单位${item.unitName}配置');
      }
      
      final domainModel = InboundItemModel(
        unitProductId: unitProduct.id,
        quantity: item.quantity,
      );
      return (
        model: domainModel,
        unitPriceInSis: item.unitPriceInSis,
        productName: item.productName,
        unitName: item.unitName,
        productionDate: item.productionDate
      );
    }).toList());
  }

  /// 执行采购流程（共享方法）
  /// 返回采购订单ID和订单号
  Future<({int orderId, String orderNumber})> _processPurchase({
    required int shopId,
    required List<_PurchaseItem> internalItems,
    required int? supplierId,
    required String? supplierName,
    PurchaseOrderStatus status = PurchaseOrderStatus.completed,
  }) async {
    // 允许仅提供名称时自动创建供应商
    final actualSupplierId = await _ensureSupplierExists(supplierId, supplierName);
    print('✅ 确认供应商ID: $actualSupplierId');

    final purchaseOrderData = await _createPurchaseOrder(
      supplierId: actualSupplierId,
      shopId: shopId,
      purchaseItems: internalItems,
      status: status,
    );
    print('✅ 采购订单创建完成，ID: ${purchaseOrderData.orderId}');
    
    return purchaseOrderData;
  }

  /// 仅采购（不入库）- 创建待入库状态的采购单
  /// 1. 检查并创建供应商
  /// 2. 创建采购单（状态为待入库）
  Future<String> processPurchaseOnly({
    required int shopId,
    required List<InboundItemState> inboundItems,
    required int? supplierId,
    required String? supplierName,
  }) async {
    print('🚀 开始执行采购流程...');
    print('🏪 店铺ID: $shopId');
    print('📦 商品数量: ${inboundItems.length}');

    return await _database.transaction(() async {
      final internalItems = await _convertToInternalItems(inboundItems);

      final purchaseOrderData = await _processPurchase(
        shopId: shopId,
        internalItems: internalItems,
        supplierId: supplierId,
        supplierName: supplierName,
        status: PurchaseOrderStatus.pendingInbound, // 待入库状态
      );

      print('🎉 采购流程执行完成！采购单号: ${purchaseOrderData.orderNumber}');
      return purchaseOrderData.orderNumber;
    });
  }

  /// 一键入库
  /// 1. 如果是采购模式，检查并创建供应商、创建采购单
  /// 2. 写入批次表
  /// 3. 写入入库单表、入库单明细表
  /// 4. 更新库存
  Future<String> processOneClickInbound({
    required int shopId,
    required List<InboundItemState> inboundItems,
    required String source,
    required bool isPurchaseMode,
    int? supplierId,
    String? supplierName,
    String? remarks,
  }) async {
    print('🚀 开始执行一键入库流程...');
    print('📦 模式: ${isPurchaseMode ? "采购" : "非采购"}');
    print('🏪 店铺ID: $shopId');
    print('📦 商品数量: ${inboundItems.length}');
    print('ℹ️ 来源: $source');

    return await _database.transaction(() async {
      int? purchaseOrderId;
      String? id;

      // 1. 将UI状态模型转换为内部处理用的元组列表
      final internalItems = await _convertToInternalItems(inboundItems);

      if (isPurchaseMode) {
        // --- 采购模式下的特定逻辑 ---
        final purchaseOrderData = await _processPurchase(
          shopId: shopId,
          internalItems: internalItems,
          supplierId: supplierId,
          supplierName: supplierName,
        );
        purchaseOrderId = purchaseOrderData.orderId;
        id = purchaseOrderData.orderNumber;
      }

      // --- 通用入库逻辑 ---
      final receiptNumber = await _processInboundCore(
        shopId: shopId,
        internalItems: internalItems,
        purchaseOrderId: purchaseOrderId,
        id: id,
        remarks: remarks,
        source: source,
      );

      print('🎉 一键入库流程执行完成！入库单号: $receiptNumber');
      return receiptNumber;
    });
  }

  /// 根据采购订单入库（供待入库订单使用）
  /// 将待入库的采购订单执行入库，并更新状态为已入库
  Future<String> processInboundFromPurchaseOrder({
    required int purchaseOrderId,
    required int shopId,
    String? remarks,
  }) async {
    print('🚀 开始执行采购订单入库流程...');
    print('📋 采购订单ID: $purchaseOrderId');
    print('🏪 店铺ID: $shopId');

    return await _database.transaction(() async {
      // 1. 获取采购订单及其明细
      final orderItems = await _purchaseDao.getPurchaseOrderItems(purchaseOrderId);
      if (orderItems.isEmpty) {
        throw Exception('采购订单明细为空');
      }

      // 2. 将采购订单明细转换为内部处理格式
      final internalItems = await Future.wait(orderItems.map((item) async {
        final unitProduct = await _database.productUnitDao.getUnitProductById(item.unitProductId);
        if (unitProduct == null) {
          throw Exception('未找到产品单位配置，ID: ${item.unitProductId}');
        }
        final product = await _database.productDao.getProductById(unitProduct.productId);
        final unit = await _database.unitDao.getUnitById(unitProduct.unitId);
        
        final domainModel = InboundItemModel(
          unitProductId: item.unitProductId,
          quantity: item.quantity,
        );
        return (
          model: domainModel,
          unitPriceInSis: item.unitPriceInSis,
          productName: product?.name ?? '未知商品',
          unitName: unit?.name ?? '',
          productionDate: item.productionDate,
        );
      }).toList());

      // 3. 执行入库核心逻辑
      final receiptNumber = await _processInboundCore(
        shopId: shopId,
        internalItems: internalItems,
        purchaseOrderId: purchaseOrderId,
        id: 'PO$purchaseOrderId',
        remarks: remarks,
        source: '采购入库',
      );

      // 4. 更新采购订单状态为已入库
      await _updatePurchaseOrderStatus(purchaseOrderId, PurchaseOrderStatus.inbounded);

      print('🎉 采购订单入库完成！入库单号: $receiptNumber');
      return receiptNumber;
    });
  }

  /// 入库核心逻辑（共享方法）
  /// 1. 写入批次表
  /// 2. 写入入库单表、入库单明细表
  /// 3. 更新库存
  Future<String> _processInboundCore({
    required int shopId,
    required List<_PurchaseItem> internalItems,
    int? purchaseOrderId,
    String? id,
    String? remarks,
    required String source,
  }) async {
    // 1. 写入批次记录
    await _writeBatchRecords(shopId: shopId, inboundItems: internalItems);

    // 2. 写入入库单记录
    final receiptNumber = await _writeInboundRecords(
      shopId: shopId,
      inboundItems: internalItems,
      purchaseOrderId: purchaseOrderId,
      id: id,
      remarks: remarks,
      source: source,
    );

    // 3. 更新库存记录
    await _writeInventoryRecords(shopId: shopId, inboundItems: internalItems);

    return receiptNumber;
  }

  /// 更新采购订单状态
  Future<void> _updatePurchaseOrderStatus(int orderId, PurchaseOrderStatus status) async {
    final order = await _purchaseDao.getPurchaseOrderById(orderId);
    if (order == null) {
      throw Exception('采购订单不存在，ID: $orderId');
    }
    
    await (_database.update(_database.purchaseOrder)
      ..where((tbl) => tbl.id.equals(orderId)))
      .write(PurchaseOrderCompanion(
        status: drift.Value(status),
        updatedAt: drift.Value(DateTime.now()),
      ));
    print('✅ 采购订单状态更新为: $status');
  }

  /// 创建采购订单（包括订单头和所有明细）
  Future<({int orderId, String orderNumber})> _createPurchaseOrder({
    required int supplierId,
    required int shopId,
    required List<_PurchaseItem> purchaseItems,
    PurchaseOrderStatus status = PurchaseOrderStatus.completed,
  }) async {
    // 生成采购单号
    final purchaseNumber = 'PO${DateTime.now().millisecondsSinceEpoch}';

    // 准备订单头
    final orderCompanion = PurchaseOrderCompanion(
      // id is auto-increment, so we don't set it.
      supplierId: drift.Value(supplierId),
      shopId: drift.Value(shopId),
      status: drift.Value(status),
    );

    // 准备订单明细列表（不包含purchaseOrderId，将在createFullPurchaseOrder中填充）
    final itemCompanions = <PurchaseOrderItemCompanion>[];
    for (final item in purchaseItems) {
      final itemCompanion = PurchaseOrderItemCompanion.insert(
        purchaseOrderId: 0, // 临时值，将在createFullPurchaseOrder中被替换
        unitProductId: item.model.unitProductId,
        unitPriceInSis: item.unitPriceInSis,
        quantity: item.model.quantity,
        productionDate: drift.Value(item.productionDate),
      );
      itemCompanions.add(itemCompanion);
    }

    // 使用事务创建完整订单
    final orderId = await _purchaseDao.createFullPurchaseOrder(
      order: orderCompanion,
      items: itemCompanions,
    );

    return (orderId: orderId, orderNumber: purchaseNumber);
  }

  /// 根据条件写入批次表
  Future<void> _writeBatchRecords({
    required int shopId,
    required List<_PurchaseItem> inboundItems,
  }) async {
    for (final item in inboundItems) {
      // 从unitProductId获取productId
      final unitProduct = await _database.productUnitDao.getUnitProductById(item.model.unitProductId);
      if (unitProduct == null) {
        throw Exception('未找到产品单位配置，ID: ${item.model.unitProductId}');
      }
      
      final product = await _database.productDao.getProductById(unitProduct.productId);

      if (product?.enableBatchManagement == true && item.productionDate != null) {
        // 将入库数量换算为基本单位数量
        final baseUnitQuantity = item.model.quantity * unitProduct.conversionRate;
        
        await _batchDao.upsertBatchIncrement(
          productId: unitProduct.productId,
          productionDate: item.productionDate!,
          shopId: shopId,
          increment: baseUnitQuantity,
        );
        print(
          '📦 批次(商品:${unitProduct.productId}, 日期:${item.productionDate}, 店铺:$shopId) 数量累计 +$baseUnitQuantity',
        );
      }
    }
  }

  /// 写入货品供应商关联表
  // Future<void> _writeProductSupplierRecords({
  //   required int supplierId,
  //   required List<_PurchaseItem> purchaseItems,
  // }) async {
  //   print('📋 开始处理货品供应商关联...');

  //   for (final item in purchaseItems) {
  //     try {
  //       // 获取单位ID
  //       final exists = await _productSupplierDao.existsProductSupplierWithUnit(
  //         item.model.productId,
  //         supplierId,
  //       );

  //       if (exists) {
  //         final existingRelations =
  //             await _productSupplierDao.getSuppliersByProductIdAndUnitId(
  //                 item.model.productId, item.model.unitId);

  //         if (existingRelations.isNotEmpty) {
  //           final existingRelation = existingRelations.firstWhere(
  //             (relation) => relation.supplierId == supplierId,
  //             orElse: () => existingRelations.first,
  //           );

  //           if (existingRelation.supplyPrice != item.unitPriceInCents) {
  //             final updatedRelation = existingRelation.copyWith(
  //               supplyPrice: drift.Value(item.unitPriceInCents.toDouble()),
  //               updatedAt: DateTime.now(),
  //             );
  //             await _productSupplierDao.updateProductSupplier(updatedRelation);
  //             print(
  //               '📝 更新 ${item.productName}(${item.unitName}) 的供货价格: ${item.unitPriceInCents}',
  //             );
  //           } else {
  //             print(
  //                 '✅ ${item.productName}(${item.unitName}) 的供应商关联已存在，无需更新');
  //           }
  //         }
  //       } else {
  //         final relationId =
  //             '${item.model.productId}_${supplierId}_${item.model.unitId}_${DateTime.now().millisecondsSinceEpoch}';

  //         final companion = ProductSuppliersTableCompanion.insert(
  //           id: relationId,
  //           productId: item.model.productId,
  //           supplierId: supplierId,
  //           supplierProductName: drift.Value(item.productName),
  //           supplyPrice: drift.Value(item.unitPriceInCents.toDouble()),
  //           isPrimary: const drift.Value(false),
  //           status: const drift.Value('active'),
  //           remarks: const drift.Value('通过采购单自动创建'),
  //         );

  //         await _productSupplierDao.insertProductSupplier(companion);
  //         print(
  //           '✅ 新建货品供应商关联: ${item.productName}(${item.unitName}) - $supplierId',
  //         );
  //       }
  //     } catch (e) {
  //       print('❌ 处理 ${item.productName} 的供应商关联失败: $e');
  //       // 不抛出异常，继续处理其他商品
  //     }
  //   }

  //   print('📋 货品供应商关联处理完成');
  // }

  /// 写入入库单表、入库单明细表
  Future<String> _writeInboundRecords({
    required int shopId,
    required List<_PurchaseItem> inboundItems,
    required String source,
    int? purchaseOrderId,
    String? id,
    String? remarks,
  }) async {
    // final now = DateTime.now();

    // 创建入库单主记录
  // 若上游未生成单号，可使用 receiptId 作为返回标识
  String? receiptNumber = id;

    final receipt = InboundReceiptCompanion(
      // id is auto-incrementing
      status: const drift.Value('completed'), // 一键入库直接完成
      remarks: drift.Value(remarks),
      shopId: drift.Value(shopId),
      source: drift.Value(source),
    );

    final receiptId = await _inboundReceiptDao.insertInboundReceipt(receipt);
    print('✅ 入库单创建完成: $receiptId'); // 创建入库单明细记录
    final itemCompanions = <InboundItemCompanion>[];

    for (final item in inboundItems) {
      // 从unitProductId获取productId
      final unitProduct = await _database.productUnitDao.getUnitProductById(item.model.unitProductId);
      if (unitProduct == null) {
        throw Exception('未找到产品单位配置，ID: ${item.model.unitProductId}');
      }
      
      final product = await _database.productDao.getProductById(unitProduct.productId);

      int? resolvedBatchNumber;
      if (item.productionDate != null &&
          product?.enableBatchManagement == true) {
  final batchIdOnly = await _batchDao.getBatchIdByBusinessKey(
          productId: unitProduct.productId,
          productionDate: item.productionDate!,
          shopId: shopId,
        );
  resolvedBatchNumber = batchIdOnly;
      }

      final itemCompanion = InboundItemCompanion(
        // id 在数据库中自增，此处不需要提供
        receiptId: drift.Value(receiptId),
        unitProductId: drift.Value(item.model.unitProductId),
        quantity: drift.Value(item.model.quantity),
        // 正确写入批次列到 batchId，而不是误写到主键 id
        batchId: resolvedBatchNumber != null
          ? drift.Value(resolvedBatchNumber)
          : const drift.Value.absent(),
      );
      itemCompanions.add(itemCompanion);
    }

    await _inboundItemDao.insertMultipleInboundItems(itemCompanions);
    print('✅ 入库明细创建完成，共 ${itemCompanions.length} 条');

  // 如果没有传入单号，则用数据库生成的 receiptId 作为回传编号
  return (receiptNumber ?? receiptId.toString());
  }

  /// 间接写入流水表、库存表
  Future<void> _writeInventoryRecords({
    required int shopId,
    required List<_PurchaseItem> inboundItems,
  }) async {
    for (final item in inboundItems) {
      // 从unitProductId获取productId
      final unitProduct = await _database.productUnitDao.getUnitProductById(item.model.unitProductId);
      if (unitProduct == null) {
        throw Exception('未找到产品单位配置，ID: ${item.model.unitProductId}');
      }
      
      final product = await _database.productDao.getProductById(unitProduct.productId);

      int? batchId;
      if (product?.enableBatchManagement == true &&
          item.productionDate != null) {
  final batchIdOnly = await _batchDao.getBatchIdByBusinessKey(
          productId: unitProduct.productId,
          productionDate: item.productionDate!,
          shopId: shopId,
        );
  batchId = batchIdOnly;
      }

      // 将入库数量换算为基本单位数量
      final baseUnitQuantity = item.model.quantity * unitProduct.conversionRate;
      
      // 将入库单位价格换算为基本单位价格
      // 例如：100元/箱，10个/箱 -> 10元/个
      final baseUnitPriceInSis = (item.unitPriceInSis / unitProduct.conversionRate).round();

      // 先更新库存数量和记录流水
      final success = await _inventoryService.inbound(
        productId: unitProduct.productId,
        shopId: shopId,
        batchId: batchId,
        quantity: baseUnitQuantity,
        time: DateTime.now(),
      );

      if (!success) {
        throw Exception('商品 ${item.productName} 库存更新失败');
      }

      // 再更新移动加权平均价格（此时库存记录已存在）
      await _weightedAveragePriceService.updateWeightedAveragePrice(
        productId: unitProduct.productId,
        shopId: shopId,
        batchId: batchId,
        inboundQuantity: baseUnitQuantity,
        inboundUnitPriceInSis: baseUnitPriceInSis,
      );

      print('✅ 商品 ${item.productName} 库存和移动加权平均价格更新完成');
    }
  }

  /// 确保供应商存在，如果不存在则创建
  Future<int> _ensureSupplierExists(
    int? supplierId,
    String? supplierName,
  ) async {
    // 1) 若提供了 ID，优先用 ID 校验
    if (supplierId != null) {
      final existingSupplier = await _supplierRepository.getSupplierById(
        supplierId,
      );
      if (existingSupplier != null) {
        print('✅ 供应商已存在: ${existingSupplier.name}');
        return supplierId;
      }
      // 若 ID 不存在，则尝试用名称处理
    }

    // 2) 若无有效 ID，则必须有名称
    if (supplierName == null || supplierName.trim().isEmpty) {
      throw Exception('采购模式下需要提供供应商名称，或选择一个已有供应商');
    }

    // 3) 名称已存在则复用
    final supplierByName = await _supplierRepository.getSupplierByName(
      supplierName,
    );
    if (supplierByName != null) {
      print('✅ 找到重名供应商，使用现有供应商: ${supplierByName.name}');
      return supplierByName.id!;
    }

    // 4) 否则创建新供应商
    final newSupplier = Supplier(name: supplierName.trim());

    try {
      final newId = await _supplierRepository.addSupplier(newSupplier);
      print('✅ 自动创建新供应商: ${newSupplier.name} (ID: $newId)');
      return newId;
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
  final weightedAveragePriceService = ref.watch(weightedAveragePriceServiceProvider);
  final supplierRepository = ref.watch(supplierRepositoryProvider);
  return InboundService(database, inventoryService, weightedAveragePriceService, supplierRepository);
});
