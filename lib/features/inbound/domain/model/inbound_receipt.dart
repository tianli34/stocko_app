/// 入库单领域模型
/// 表示入库单的业务实体
class InboundReceipt {
  final String id;
  final String receiptNumber;
  final String status;
  final String? remarks;
  final String shopId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;

  const InboundReceipt({
    required this.id,
    required this.receiptNumber,
    required this.status,
    this.remarks,
    required this.shopId,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.completedAt,
  });

  /// 复制并更新入库单
  InboundReceipt copyWith({
    String? id,
    String? receiptNumber,
    String? status,
    String? remarks,
    String? shopId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? completedAt,
  }) {
    return InboundReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 入库单状态枚举
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  /// 状态显示名称映射
  static const Map<String, String> statusNames = {
    statusDraft: '草稿',
    statusSubmitted: '已提交',
    statusCompleted: '已完成',
    statusCancelled: '已取消',
  };

  /// 获取状态显示名称
  String get statusDisplayName => statusNames[status] ?? status;

  /// 是否为草稿状态
  bool get isDraft => status == statusDraft;

  /// 是否已提交
  bool get isSubmitted => status == statusSubmitted;

  /// 是否已完成
  bool get isCompleted => status == statusCompleted;

  /// 是否已取消
  bool get isCancelled => status == statusCancelled;

  /// 是否可编辑（仅草稿状态可编辑）
  bool get canEdit => isDraft;

  /// 是否可提交（草稿状态且有明细时可提交）
  bool get canSubmit => isDraft;

  /// 是否可取消（草稿或已提交状态可取消）
  bool get canCancel => isDraft || isSubmitted;

  /// 生成入库单号
  /// 格式：RCT + YYYYMMDD + 4位序号
  static String generateReceiptNumber(DateTime date, int sequence) {
    final dateStr = date.toIso8601String().substring(0, 10).replaceAll('-', '');
    final seqStr = sequence.toString().padLeft(4, '0');
    return 'RCT$dateStr$seqStr';
  }

  /// 创建新的入库单
  factory InboundReceipt.create({required String shopId, String? remarks}) {
    final now = DateTime.now();
    return InboundReceipt(
      id: 'receipt_${now.millisecondsSinceEpoch}',
      receiptNumber: generateReceiptNumber(now, 1), // 序号需要从数据库获取
      status: statusDraft,
      remarks: remarks,
      shopId: shopId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
