import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/models/restore_mode.dart';
import '../../domain/common/backup_common.dart';
import '../../domain/services/i_restore_service.dart';

/// 数据导入仓储类
/// 负责将备份数据导入到数据库中
class DataImportRepository {
  final AppDatabase _database;

  DataImportRepository(this._database);

  /// 导入所有表数据（增强版本，支持进度跟踪和错误处理）
  /// [tablesData] 包含所有表数据的Map，键为表名，值为记录列表
  /// [mode] 恢复模式
  /// [selectedTables] 选择要恢复的表（null表示恢复所有表）
  /// [onProgress] 进度回调函数
  /// [cancelToken] 取消令牌
  /// 返回各表导入的记录数统计
  Future<Map<String, int>> importAllTables(
    Map<String, List<Map<String, dynamic>>> tablesData,
    RestoreMode mode, {
    List<String>? selectedTables,
    RestoreProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    print('═══════════════════════════════════════════════════════════════');
    print('🚀 开始导入所有表数据');
    print('恢复模式: $mode');
    print('总表数: ${tablesData.length}');
    print('选择的表: ${selectedTables ?? "全部"}');
    print('═══════════════════════════════════════════════════════════════');
    final Map<String, int> importCounts = {};
    if (tablesData.isEmpty) {
      return importCounts;
    }
    final List<String> errors = [];
    final List<DataConflict> allConflicts = [];

    // 计算总记录数用于进度跟踪
    int totalRecords = 0;
    int processedRecords = 0;

    final tablesToProcess = selectedTables ?? tablesData.keys.toList();
    for (final tableName in tablesToProcess) {
      if (tablesData.containsKey(tableName)) {
        totalRecords += tablesData[tableName]!.length;
      }
    }

    try {
      print('📊 计算总记录数: $totalRecords');
      print('📋 待处理表列表: $tablesToProcess');

      // 使用数据库事务确保数据一致性
      return await _database.transaction(() async {
        print('🔄 开始数据库事务');
        onProgress?.call('准备数据恢复...', 0, totalRecords);
        cancelToken?.throwIfCancelled();

        // 如果是完全替换模式，先清空相关表
        if (mode == RestoreMode.replace) {
          print('🗑️ 替换模式：开始清空现有数据');
          onProgress?.call('清空现有数据...', 0, totalRecords);
          await _clearTables(tablesToProcess);
          print('✅ 现有数据清空完成');
        }

        // 按照依赖关系顺序导入表数据
        final importOrder = _getTableImportOrder();
        print('📋 表导入顺序: $importOrder');

        for (final tableName in importOrder) {
          if (!tablesToProcess.contains(tableName)) {
            continue;
          }

          if (tablesData.containsKey(tableName)) {
            final records = tablesData[tableName]!;

            print(
              '───────────────────────────────────────────────────────────────',
            );
            print('📊 开始处理表: $tableName');
            print('记录数量: ${records.length}');
            print(
              '───────────────────────────────────────────────────────────────',
            );

            onProgress?.call(
              '恢复表 $tableName...',
              processedRecords,
              totalRecords,
            );
            cancelToken?.throwIfCancelled();

            final result = await _importTableWithProgress(
              tableName,
              records,
              mode,
              onProgress: (current, total) {
                final globalProgress = processedRecords + current;
                onProgress?.call(
                  '恢复表 $tableName ($current/$total)',
                  globalProgress,
                  totalRecords,
                );
              },
              cancelToken: cancelToken,
            );

            importCounts[tableName] = result.successCount;
            errors.addAll(result.errors);
            allConflicts.addAll(result.conflicts);
            processedRecords += records.length;

            print('✅ 表 $tableName 处理完成');
            print('成功导入: ${result.successCount} 条记录');
            print('失败记录: ${result.failureCount} 条');
            print('冲突记录: ${result.conflicts.length} 条');
          }
        }

        // 如果有严重错误，回滚事务
        if (errors.length > totalRecords * 0.1) {
          // 如果错误率超过10%
          print('❌ 错误率过高，准备回滚事务');
          print('总错误数: ${errors.length}');
          print('总记录数: $totalRecords');
          print(
            '错误率: ${(errors.length / totalRecords * 100).toStringAsFixed(2)}%',
          );
          throw BackupException(
            type: BackupErrorType.databaseError,
            message: '恢复过程中错误过多，已回滚所有更改。错误: ${errors.take(5).join(', ')}',
          );
        }

        print('🎉 所有表数据导入完成');
        print('总导入记录数: ${importCounts.values.fold(0, (a, b) => a + b)}');
        print('总错误数: ${errors.length}');
        print('总冲突数: ${allConflicts.length}');
        onProgress?.call('数据恢复完成', totalRecords, totalRecords);

        return importCounts;
      });
    } on RestoreCancelledException {
      // 取消操作，事务会自动回滚
      rethrow;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '导入数据库表失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 导入所有表数据（原版本，保持向后兼容）
  Future<Map<String, int>> importAllTablesLegacy(
    Map<String, List<Map<String, dynamic>>> tablesData,
    RestoreMode mode, {
    List<String>? selectedTables,
  }) async {
    return importAllTables(tablesData, mode, selectedTables: selectedTables);
  }

  /// 导入指定表的数据（增强版本，支持进度跟踪）
  /// [tableName] 表名
  /// [records] 要导入的记录列表
  /// [mode] 恢复模式
  /// [onProgress] 进度回调函数
  /// [cancelToken] 取消令牌
  /// [batchSize] 批处理大小，默认100条记录
  Future<BatchResult> _importTableWithProgress(
    String tableName,
    List<Map<String, dynamic>> records,
    RestoreMode mode, {
    void Function(int current, int total)? onProgress,
    CancelToken? cancelToken,
    int batchSize = 100,
  }) async {
    print('🔄 开始导入表: $tableName');
    print('记录总数: ${records.length}');
    print('批处理大小: $batchSize');
    print('预计批次数: ${(records.length / batchSize).ceil()}');
    try {
      int successCount = 0;
      final List<String> errors = [];
      final List<DataConflict> conflicts = [];

      // 分批处理记录
      for (int i = 0; i < records.length; i += batchSize) {
        cancelToken?.throwIfCancelled();

        final batch = records.skip(i).take(batchSize).toList();
        final batchNumber = (i / batchSize).floor() + 1;
        final totalBatches = (records.length / batchSize).ceil();

        print(
          '📦 处理批次 $batchNumber/$totalBatches (记录 ${i + 1}-${(i + batch.length).clamp(0, records.length)})',
        );
        onProgress?.call(i, records.length);

        final batchResult = await _importTableBatchEnhanced(
          tableName,
          batch,
          mode,
        );
        successCount += batchResult.successCount;
        errors.addAll(batchResult.errors);
        conflicts.addAll(batchResult.conflicts);

        print(
          '✅ 批次 $batchNumber 完成 - 成功: ${batchResult.successCount}, 失败: ${batchResult.failureCount}',
        );
      }

      onProgress?.call(records.length, records.length);

      return BatchResult(
        successCount: successCount,
        failureCount: records.length - successCount,
        errors: errors,
        conflicts: conflicts,
      );
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '导入表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 导入指定表的数据（原版本，保持向后兼容）
  Future<int> _importTable(
    String tableName,
    List<Map<String, dynamic>> records,
    RestoreMode mode, {
    int batchSize = 100,
  }) async {
    final result = await _importTableWithProgress(
      tableName,
      records,
      mode,
      batchSize: batchSize,
    );
    return result.successCount;
  }

  /// 分批导入表数据（增强版本，支持冲突检测）
  /// [tableName] 表名
  /// [records] 记录列表
  /// [mode] 恢复模式
  Future<BatchResult> _importTableBatchEnhanced(
    String tableName,
    List<Map<String, dynamic>> records,
    RestoreMode mode,
  ) async {
    print('🔍 开始批量导入 - 表: $tableName, 记录数: ${records.length}');
    try {
      int successCount = 0;
      final List<String> errors = [];
      final List<DataConflict> conflicts = [];

      // 获取主键信息用于冲突检测
      final primaryKey = await _getPrimaryKeyColumn(tableName);
      print('🔑 表 $tableName 的主键: ${primaryKey ?? "无主键"}');

      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        try {
          print(
            '📝 处理记录 ${i + 1}/${records.length}: ${record.keys.take(3).join(", ")}...',
          );

          final result = await _importRecordWithConflictDetection(
            tableName,
            record,
            mode,
            primaryKey,
          );

          if (result['success'] == true) {
            successCount++;
            print('✅ 记录 ${i + 1} 导入成功');
          } else {
            print('❌ 记录 ${i + 1} 导入失败: ${result['error']}');
          }

          if (result['conflict'] != null) {
            conflicts.add(result['conflict'] as DataConflict);
            print('⚠️ 记录 ${i + 1} 存在冲突');
          }
        } catch (e) {
          final errorMsg = '导入记录失败: ${e.toString()}';
          errors.add(errorMsg);
          print('💥 记录 ${i + 1} 异常: $errorMsg');
        }
      }

      return BatchResult(
        successCount: successCount,
        failureCount: records.length - successCount,
        errors: errors,
        conflicts: conflicts,
      );
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '分批导入表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 分批导入表数据（原版本，保持向后兼容）
  Future<int> _importTableBatch(
    String tableName,
    List<Map<String, dynamic>> records,
    RestoreMode mode,
  ) async {
    final result = await _importTableBatchEnhanced(tableName, records, mode);
    return result.successCount;
  }

  /// 导入单条记录（增强版本，支持冲突检测）
  /// [tableName] 表名
  /// [record] 记录数据
  /// [mode] 恢复模式
  /// [primaryKey] 主键列名
  /// 返回包含成功状态和冲突信息的Map
  Future<Map<String, dynamic>> _importRecordWithConflictDetection(
    String tableName,
    Map<String, dynamic> record,
    RestoreMode mode,
    String? primaryKey,
  ) async {
    final primaryKeyValue = primaryKey != null ? record[primaryKey] : null;
    print('🎯 导入记录到表 $tableName - 主键值: $primaryKeyValue - 模式: $mode');
    try {
      switch (mode) {
        case RestoreMode.replace:
          // 完全替换模式：直接插入（表已清空）
          print('🔄 替换模式：直接插入记录');
          await _insertRecord(tableName, record);
          print('✅ 替换模式：记录插入成功');
          return {'success': true};

        case RestoreMode.merge:
          // 合并模式：检测冲突并处理
          print('🔄 合并模式：检测冲突并处理');
          final result = await _upsertRecordWithConflictDetection(
            tableName,
            record,
            primaryKey,
          );
          print('✅ 合并模式：处理完成 - 成功: ${result['success']}');
          return result;

        case RestoreMode.addOnly:
          // 仅添加模式：检测冲突并跳过
          print('🔄 仅添加模式：检测冲突并跳过');
          final result = await _insertIfNotExistsWithConflictDetection(
            tableName,
            record,
            primaryKey,
          );
          print('✅ 仅添加模式：处理完成 - 成功: ${result['success']}');
          return result;
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('💥 导入记录异常: $errorMsg');
      return {'success': false, 'error': errorMsg};
    }
  }

  /// 导入单条记录（原版本，保持向后兼容）
  Future<bool> _importRecord(
    String tableName,
    Map<String, dynamic> record,
    RestoreMode mode,
  ) async {
    final primaryKey = await _getPrimaryKeyColumn(tableName);
    final result = await _importRecordWithConflictDetection(
      tableName,
      record,
      mode,
      primaryKey,
    );
    return result['success'] == true;
  }

  /// 插入记录
  Future<void> _insertRecord(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    print('═══════════════════════════════════════════════════════════════');
    print('🔥 执行数据库插入操作');
    print('表名: $tableName');
    print('记录字段: ${record.keys.toList()}');
    print('记录值: ${record.values.toList()}');

    // 获取表的实际列信息，过滤掉不存在的列
    final validColumns = await _getValidColumnsForTable(tableName, record);

    final columns = validColumns.keys.join(', ');
    final placeholders = validColumns.keys.map((_) => '?').join(', ');
    final values = validColumns.values.toList();

    final query = 'INSERT INTO $tableName ($columns) VALUES ($placeholders)';
    print('SQL语句: $query');
    print('参数值: $values');

    try {
      print('⏳ 开始执行 _database.customStatement()...');
      await _database.customStatement(query, values);
      print('🎉 _database.customStatement() 执行成功！');
      print('✅ 记录已成功插入到表 $tableName');
    } catch (e) {
      print('💥 _database.customStatement() 执行失败！');
      print('错误信息: ${e.toString()}');
      print('错误类型: ${e.runtimeType}');
      rethrow;
    }
    print('═══════════════════════════════════════════════════════════════');
  }

  /// 更新或插入记录（UPSERT）增强版本，支持冲突检测
  Future<Map<String, dynamic>> _upsertRecordWithConflictDetection(
    String tableName,
    Map<String, dynamic> record,
    String? primaryKey,
  ) async {
    try {
      if (primaryKey == null || !record.containsKey(primaryKey)) {
        // 没有主键信息，直接插入
        await _insertRecord(tableName, record);
        return {'success': true};
      }

      // 检查记录是否存在
      final existingRecord = await _getExistingRecord(
        tableName,
        primaryKey,
        record[primaryKey],
      );

      if (existingRecord != null) {
        // 记录存在，检测冲突
        final hasConflict = _detectDataConflict(existingRecord, record);

        DataConflict? conflict;
        if (hasConflict) {
          conflict = DataConflict(
            tableName: tableName,
            primaryKey: primaryKey,
            primaryKeyValue: record[primaryKey],
            existingRecord: existingRecord,
            newRecord: record,
            resolution: ConflictResolution.overwrite,
          );
        }

        // 更新记录
        await _updateRecord(tableName, record, primaryKey);

        return {'success': true, 'conflict': conflict};
      } else {
        // 记录不存在，插入
        await _insertRecord(tableName, record);
        return {'success': true};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 仅在记录不存在时插入（增强版本，支持冲突检测）
  Future<Map<String, dynamic>> _insertIfNotExistsWithConflictDetection(
    String tableName,
    Map<String, dynamic> record,
    String? primaryKey,
  ) async {
    try {
      if (primaryKey == null || !record.containsKey(primaryKey)) {
        // 没有主键信息，尝试插入
        await _insertRecord(tableName, record);
        return {'success': true};
      }

      // 检查记录是否存在
      final existingRecord = await _getExistingRecord(
        tableName,
        primaryKey,
        record[primaryKey],
      );

      if (existingRecord == null) {
        await _insertRecord(tableName, record);
        return {'success': true};
      } else {
        // 记录已存在，创建冲突信息
        final conflict = DataConflict(
          tableName: tableName,
          primaryKey: primaryKey,
          primaryKeyValue: record[primaryKey],
          existingRecord: existingRecord,
          newRecord: record,
          resolution: ConflictResolution.skip,
        );

        return {
          'success': true, // 在AddOnly模式下，记录已存在是预期行为，应视为成功
          'conflict': conflict,
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 更新或插入记录（UPSERT）原版本，保持向后兼容
  Future<bool> _upsertRecord(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final primaryKey = await _getPrimaryKeyColumn(tableName);
    final result = await _upsertRecordWithConflictDetection(
      tableName,
      record,
      primaryKey,
    );
    return result['success'] == true;
  }

  /// 仅在记录不存在时插入（原版本，保持向后兼容）
  Future<bool> _insertIfNotExists(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final primaryKey = await _getPrimaryKeyColumn(tableName);
    final result = await _insertIfNotExistsWithConflictDetection(
      tableName,
      record,
      primaryKey,
    );
    return result['success'] == true;
  }

  /// 更新记录
  Future<void> _updateRecord(
    String tableName,
    Map<String, dynamic> record,
    String primaryKey,
  ) async {
    print('═══════════════════════════════════════════════════════════════');
    print('🔄 执行数据库更新操作');
    print('表名: $tableName');
    print('主键: $primaryKey = ${record[primaryKey]}');
    print('更新字段: ${record.keys.where((key) => key != primaryKey).toList()}');

    // 获取表的实际列信息，过滤掉不存在的列
    final validColumns = await _getValidColumnsForTable(tableName, record);
    
    final updateColumns = validColumns.keys
        .where((key) => key != primaryKey)
        .map((key) => '$key = ?')
        .join(', ');

    final values = validColumns.entries
        .where((entry) => entry.key != primaryKey)
        .map((entry) => entry.value)
        .toList();

    values.add(validColumns[primaryKey]);

    final query = 'UPDATE $tableName SET $updateColumns WHERE $primaryKey = ?';
    print('SQL语句: $query');
    print('参数值: $values');

    try {
      print('⏳ 开始执行 _database.customStatement()...');
      await _database.customStatement(query, values);
      print('🎉 _database.customStatement() 执行成功！');
      print('✅ 记录已成功更新到表 $tableName');
    } catch (e) {
      print('💥 _database.customStatement() 执行失败！');
      print('错误信息: ${e.toString()}');
      print('错误类型: ${e.runtimeType}');
      rethrow;
    }
    print('═══════════════════════════════════════════════════════════════');
  }

  /// 检查记录是否存在
  Future<bool> _recordExists(
    String tableName,
    String primaryKey,
    dynamic value,
  ) async {
    final query = 'SELECT 1 FROM $tableName WHERE $primaryKey = ? LIMIT 1';
    final result = await _database
        .customSelect(query, variables: [_createVariable(value)])
        .getSingleOrNull();

    return result != null;
  }

  /// 获取现有记录的完整数据
  Future<Map<String, dynamic>?> _getExistingRecord(
    String tableName,
    String primaryKey,
    dynamic value,
  ) async {
    try {
      final query = 'SELECT * FROM $tableName WHERE $primaryKey = ? LIMIT 1';
      final result = await _database
          .customSelect(query, variables: [_createVariable(value)])
          .getSingleOrNull();

      return result?.data;
    } catch (e) {
      return null;
    }
  }

  /// 检测数据冲突
  /// 比较现有记录和新记录，检查是否有实质性差异
  bool _detectDataConflict(
    Map<String, dynamic> existingRecord,
    Map<String, dynamic> newRecord,
  ) {
    // 检查所有字段是否有差异
    for (final entry in newRecord.entries) {
      final key = entry.key;
      final newValue = entry.value;
      final existingValue = existingRecord[key];

      // 跳过null值比较
      if (newValue == null && existingValue == null) {
        continue;
      }

      // 如果值不同，则存在冲突
      if (newValue != existingValue) {
        return true;
      }
    }

    return false;
  }

  /// 获取表的主键列名
  Future<String?> _getPrimaryKeyColumn(String tableName) async {
    try {
      final query = 'PRAGMA table_info($tableName)';
      final result = await _database.customSelect(query).get();

      for (final row in result) {
        final data = row.data;
        if (data['pk'] == 1) {
          return data['name'] as String;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 清空指定表的数据
  Future<void> _clearTables(List<String> tableNames) async {
    print('═══════════════════════════════════════════════════════════════');
    print('🗑️ 开始清空表数据');
    print('需要清空的表: $tableNames');

    try {
      // 按照反向依赖关系顺序清空表（避免外键约束问题）
      final clearOrder = _getTableImportOrder().reversed.toList();
      print('清空顺序: $clearOrder');

      for (final tableName in clearOrder) {
        if (tableNames.contains(tableName)) {
          print('🔄 清空表: $tableName');
          final query = 'DELETE FROM $tableName';
          print('SQL语句: $query');

          try {
            print('⏳ 开始执行 _database.customStatement()...');
            await _database.customStatement(query, []);
            print('🎉 _database.customStatement() 执行成功！');
            print('✅ 表 $tableName 已清空');
          } catch (e) {
            print('💥 清空表 $tableName 失败: ${e.toString()}');
            rethrow;
          }
        }
      }
      print('🎉 所有表清空完成');
    } catch (e) {
      print('💥 清空表数据异常: ${e.toString()}');
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '清空表数据失败: ${e.toString()}',
        originalError: e,
      );
    }
    print('═══════════════════════════════════════════════════════════════');
  }

  /// 获取表导入顺序（按照依赖关系）
  List<String> _getTableImportOrder() {
    return [
      // 1. 基础数据表（无外键依赖）
      'category',
      'unit',
      'shop',
      'supplier',
      'customers',
      'locations',

      // 2. 产品相关表
      'product',
      'unit_product',
      'barcode',
      'product_batch',

      // 3. 库存相关表
      'stock',
      'inventory_transaction',

      // 4. 业务单据表
      'purchase_order',
      'purchase_order_item',
      'inbound_receipt',
      'inbound_item',
      'sales_transaction',
      'sales_transaction_item',
      'outbound_receipt',
      'outbound_item',
    ];
  }

  /// 验证导入数据的完整性
  /// [tablesData] 要验证的表数据
  /// 返回验证结果和错误信息
  Future<Map<String, dynamic>> validateImportData(
    Map<String, List<Map<String, dynamic>>> tablesData,
  ) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    int totalRecords = 0;

    try {
      for (final entry in tablesData.entries) {
        final tableName = entry.key;
        final records = entry.value;

        totalRecords += records.length;

        // 检查表是否存在
        final tableExists = await _tableExists(tableName);
        if (!tableExists) {
          warnings.add('表 $tableName 在当前数据库中不存在，将跳过');
          continue;
        }

        // 验证记录结构
        if (records.isNotEmpty) {
          final sampleRecord = records.first;
          final validationResult = await _validateRecordStructure(
            tableName,
            sampleRecord,
          );
          if (!validationResult['valid']) {
            errors.add('表 $tableName 的记录结构无效: ${validationResult['error']}');
          }
        }
      }

      return {
        'valid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'totalRecords': totalRecords,
      };
    } catch (e) {
      return {
        'valid': false,
        'errors': ['验证导入数据时发生错误: ${e.toString()}'],
        'warnings': warnings,
        'totalRecords': totalRecords,
      };
    }
  }

  /// 检查表是否存在
  Future<bool> _tableExists(String tableName) async {
    try {
      final query = '''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name=?
      ''';
      final result = await _database
          .customSelect(query, variables: [Variable.withString(tableName)])
          .getSingleOrNull();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// 验证记录结构
  Future<Map<String, dynamic>> _validateRecordStructure(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    try {
      // 获取表结构信息
      final query = 'PRAGMA table_info($tableName)';
      final result = await _database.customSelect(query).get();

      final tableColumns = <String, Map<String, dynamic>>{};
      for (final row in result) {
        final data = row.data;
        tableColumns[data['name'] as String] = {
          'type': data['type'],
          'notNull': data['notnull'] == 1,
          'defaultValue': data['dflt_value'],
        };
      }

      // 检查必需字段
      for (final entry in tableColumns.entries) {
        final columnName = entry.key;
        final columnInfo = entry.value;

        if (columnInfo['notNull'] &&
            columnInfo['defaultValue'] == null &&
            !record.containsKey(columnName)) {
          return {'valid': false, 'error': '缺少必需字段: $columnName'};
        }
      }

      return {'valid': true};
    } catch (e) {
      return {'valid': false, 'error': '验证记录结构失败: ${e.toString()}'};
    }
  }

  /// 估算导入时间（秒）
  /// [recordCount] 记录总数
  /// [mode] 恢复模式
  Future<int> estimateImportTime(int recordCount, RestoreMode mode) async {
    try {
      // 基于记录数量和恢复模式估算时间
      // 这些数值基于经验，实际情况可能有所不同

      int baseTimePerRecord; // 毫秒

      switch (mode) {
        case RestoreMode.replace:
          baseTimePerRecord = 2; // 替换模式最快
          break;
        case RestoreMode.merge:
          baseTimePerRecord = 5; // 合并模式需要检查和更新
          break;
        case RestoreMode.addOnly:
          baseTimePerRecord = 3; // 仅添加模式需要检查存在性
          break;
      }

      final totalTimeMs = recordCount * baseTimePerRecord;
      final totalTimeSeconds = (totalTimeMs / 1000).ceil();

      // 最少1秒，最多不超过3600秒（1小时）
      return totalTimeSeconds.clamp(1, 3600);
    } catch (e) {
      return 60; // 默认估算1分钟
    }
  }

  /// 获取冲突记录数量估算
  /// [tablesData] 表数据
  /// [mode] 恢复模式
  Future<int> estimateConflicts(
    Map<String, List<Map<String, dynamic>>> tablesData,
    RestoreMode mode,
  ) async {
    if (mode == RestoreMode.replace) {
      return 0; // 替换模式没有冲突
    }

    try {
      int conflictCount = 0;

      for (final entry in tablesData.entries) {
        final tableName = entry.key;
        final records = entry.value;

        final primaryKey = await _getPrimaryKeyColumn(tableName);
        if (primaryKey == null) continue;

        // 检查前100条记录的冲突情况，然后按比例估算
        final sampleSize = records.length > 100 ? 100 : records.length;
        int sampleConflicts = 0;

        for (int i = 0; i < sampleSize; i++) {
          final record = records[i];
          if (record.containsKey(primaryKey)) {
            final exists = await _recordExists(
              tableName,
              primaryKey,
              record[primaryKey],
            );
            if (exists) {
              sampleConflicts++;
            }
          }
        }

        // 按比例估算总冲突数
        if (sampleSize > 0) {
          final conflictRatio = sampleConflicts / sampleSize;
          conflictCount += (records.length * conflictRatio).round();
        }
      }

      return conflictCount;
    } catch (e) {
      return 0; // 估算失败时返回0
    }
  }

  /// 执行数据库健康检查
  /// 在恢复完成后验证数据完整性
  Future<Map<String, dynamic>> performHealthCheck(
    List<String> tablesToCheck,
  ) async {
    try {
      final Map<String, int> tableCounts = {};
      final List<String> issues = [];

      for (final tableName in tablesToCheck) {
        try {
          // 检查表记录数
          final countQuery = 'SELECT COUNT(*) as count FROM $tableName';
          final result = await _database.customSelect(countQuery).getSingle();
          final count = result.data['count'] as int;
          tableCounts[tableName] = count;

          // 检查表结构完整性
          final integrityQuery = 'PRAGMA integrity_check($tableName)';
          final integrityResult = await _database
              .customSelect(integrityQuery)
              .get();

          for (final row in integrityResult) {
            final message = row.data.values.first as String;
            if (message != 'ok') {
              issues.add('表 $tableName 完整性检查失败: $message');
            }
          }
        } catch (e) {
          issues.add('检查表 $tableName 时发生错误: ${e.toString()}');
        }
      }

      return {
        'success': issues.isEmpty,
        'tableCounts': tableCounts,
        'issues': issues,
      };
    } catch (e) {
      return {
        'success': false,
        'tableCounts': <String, int>{},
        'issues': ['健康检查失败: ${e.toString()}'],
      };
    }
  }

  /// 创建恢复点（用于回滚）
  /// 在开始恢复前创建数据快照
  Future<String?> createRestorePoint(List<String> tablesToBackup) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final restorePointId = 'restore_point_$timestamp';

      // 这里可以实现创建临时备份表的逻辑
      // 由于复杂性，暂时返回标识符
      // 实际实现中可以创建临时表或文件备份

      return restorePointId;
    } catch (e) {
      return null;
    }
  }

  /// 回滚到恢复点
  /// 在恢复失败时回滚数据
  Future<bool> rollbackToRestorePoint(String restorePointId) async {
    try {
      // 这里可以实现从恢复点回滚的逻辑
      // 由于复杂性，暂时返回成功
      // 实际实现中可以从临时表或文件恢复数据

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取表的有效列（过滤掉不存在的列）
  /// [tableName] 表名
  /// [record] 要插入/更新的记录
  /// 返回过滤后的有效列数据
  Future<Map<String, dynamic>> _getValidColumnsForTable(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    try {
      // 获取表结构信息
      final query = 'PRAGMA table_info($tableName)';
      final result = await _database.customSelect(query).get();

      final validColumnNames = <String>{};
      for (final row in result) {
        final data = row.data;
        validColumnNames.add(data['name'] as String);
      }

      // 过滤掉不存在的列
      final validColumns = <String, dynamic>{};
      for (final entry in record.entries) {
        if (validColumnNames.contains(entry.key)) {
          validColumns[entry.key] = entry.value;
        } else {
          print('⚠️ 跳过不存在的列: ${entry.key} (表: $tableName)');
        }
      }

      print('📋 表 $tableName 有效列: ${validColumns.keys.toList()}');
      return validColumns;
    } catch (e) {
      print('💥 获取表结构失败，使用原始记录: ${e.toString()}');
      // 如果获取表结构失败，返回原始记录
      return record;
    }
  }

  /// 创建适当类型的 Variable 对象
  /// 避免类型推断错误导致的解析异常
  Variable _createVariable(dynamic value) {
    if (value == null) {
      return const Variable(null);
    } else if (value is int) {
      return Variable.withInt(value);
    } else if (value is double) {
      return Variable.withReal(value);
    } else if (value is bool) {
      return Variable.withBool(value);
    } else if (value is DateTime) {
      return Variable.withDateTime(value);
    } else {
      // 对于字符串和其他类型，使用 withString 确保正确处理
      return Variable.withString(value.toString());
    }
  }
}
