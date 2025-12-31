import '../model/unit.dart';
import '../../presentation/widgets/auxiliary_unit/auxiliary_unit_model.dart';

/// 单位验证结果
class UnitValidationResult {
  /// 是否有效
  final bool isValid;
  
  /// 错误消息（如果无效）
  final String? errorMessage;

  const UnitValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const UnitValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// 单位验证服务
/// 
/// 提供单位选择的验证逻辑
class UnitValidationService {
  const UnitValidationService._();

  /// 验证单位选择是否有效
  /// 
  /// [unit] 要验证的单位
  /// [baseUnitName] 基本单位名称
  /// [auxiliaryUnits] 当前辅单位列表
  /// [currentIndex] 当前编辑的辅单位索引
  static UnitValidationResult validateUnitSelection({
    required Unit unit,
    required String? baseUnitName,
    required List<AuxiliaryUnitModel> auxiliaryUnits,
    required int currentIndex,
  }) {
    // 检查是否与基本单位相同
    if (baseUnitName != null && unit.name == baseUnitName) {
      return const UnitValidationResult.invalid('辅单位不能与基本单位相同');
    }

    // 检查是否与其他辅单位重复
    final existingIndex = auxiliaryUnits.indexWhere(
      (aux) => aux.unit?.name == unit.name,
    );
    if (existingIndex != -1 && existingIndex != currentIndex) {
      return const UnitValidationResult.invalid('该单位已被其他辅单位使用');
    }

    return const UnitValidationResult.valid();
  }

  /// 验证换算率是否有效
  /// 
  /// [rate] 换算率
  static UnitValidationResult validateConversionRate(double? rate) {
    if (rate == null || rate <= 0) {
      return const UnitValidationResult.invalid('请输入有效的换算率');
    }
    if (rate == 1.0) {
      return const UnitValidationResult.invalid('辅单位换算率不能为1');
    }
    return const UnitValidationResult.valid();
  }
}
