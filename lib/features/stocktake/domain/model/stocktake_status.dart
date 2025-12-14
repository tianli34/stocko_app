/// 盘点单状态枚举
enum StocktakeStatus {
  /// 草稿
  draft,
  /// 进行中
  inProgress,
  /// 已完成
  completed,
  /// 已审核
  audited;

  String get value {
    switch (this) {
      case StocktakeStatus.draft:
        return 'draft';
      case StocktakeStatus.inProgress:
        return 'in_progress';
      case StocktakeStatus.completed:
        return 'completed';
      case StocktakeStatus.audited:
        return 'audited';
    }
  }

  String get displayName {
    switch (this) {
      case StocktakeStatus.draft:
        return '草稿';
      case StocktakeStatus.inProgress:
        return '进行中';
      case StocktakeStatus.completed:
        return '已完成';
      case StocktakeStatus.audited:
        return '已审核';
    }
  }

  static StocktakeStatus fromValue(String value) {
    switch (value) {
      case 'draft':
        return StocktakeStatus.draft;
      case 'in_progress':
        return StocktakeStatus.inProgress;
      case 'completed':
        return StocktakeStatus.completed;
      case 'audited':
        return StocktakeStatus.audited;
      default:
        return StocktakeStatus.draft;
    }
  }
}

/// 盘点类型枚举
enum StocktakeType {
  /// 全盘
  full,
  /// 部分盘点（按分类）
  partial;

  String get value {
    switch (this) {
      case StocktakeType.full:
        return 'full';
      case StocktakeType.partial:
        return 'partial';
    }
  }

  String get displayName {
    switch (this) {
      case StocktakeType.full:
        return '全盘';
      case StocktakeType.partial:
        return '部分盘点';
    }
  }

  static StocktakeType fromValue(String value) {
    switch (value) {
      case 'full':
        return StocktakeType.full;
      case 'partial':
        return StocktakeType.partial;
      default:
        return StocktakeType.full;
    }
  }
}

/// 差异原因枚举
enum DifferenceReason {
  /// 损耗
  loss,
  /// 盗窃
  theft,
  /// 录入错误
  inputError,
  /// 过期报废
  expired,
  /// 赠送
  gift,
  /// 其他
  other;

  String get displayName {
    switch (this) {
      case DifferenceReason.loss:
        return '损耗';
      case DifferenceReason.theft:
        return '盗窃';
      case DifferenceReason.inputError:
        return '录入错误';
      case DifferenceReason.expired:
        return '过期报废';
      case DifferenceReason.gift:
        return '赠送';
      case DifferenceReason.other:
        return '其他';
    }
  }
}
