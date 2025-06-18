/// 货位领域模型
/// 表示仓库货位信息
class Location {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String shopId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Location({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.shopId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 货位状态常量
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  /// 状态显示名称映射
  static const Map<String, String> statusNames = {
    statusActive: '活跃',
    statusInactive: '停用',
  };

  /// 获取状态显示名称
  String get statusDisplayName => statusNames[status] ?? status;

  /// 是否活跃
  bool get isActive => status == statusActive;

  /// 是否停用
  bool get isInactive => status == statusInactive;

  /// 复制并更新货位
  Location copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? shopId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      shopId: shopId ?? this.shopId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 创建新货位
  factory Location.create({
    required String code,
    required String name,
    String? description,
    required String shopId,
  }) {
    final now = DateTime.now();
    return Location(
      id: 'location_${now.millisecondsSinceEpoch}',
      code: code,
      name: name,
      description: description,
      shopId: shopId,
      status: statusActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 获取完整显示名称（编码 - 名称）
  String get fullDisplayName => '$code - $name';

  @override
  String toString() => fullDisplayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
