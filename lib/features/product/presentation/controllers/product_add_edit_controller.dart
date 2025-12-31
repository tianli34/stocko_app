// lib/features/product/presentation/controllers/product_add_edit_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/submit_multi_variants_use_case.dart';
import '../../application/use_cases/submit_single_product_use_case.dart';
import '../models/product_form_data.dart';
import '../models/product_operation_result.dart';

// 重新导出数据模型，保持向后兼容
export '../models/product_form_data.dart';
export '../models/product_operation_result.dart';

/// Controller 提供者
final productAddEditControllerProvider = Provider<ProductAddEditController>(
  (ref) => ProductAddEditController(ref),
);

/// 产品添加/编辑控制器
/// 
/// 职责：作为协调器，接收表单数据，委托给对应 UseCase 执行
/// 
/// 遵循 SOLID 原则：
/// - SRP: 仅负责协调，不包含业务逻辑
/// - OCP: 通过 UseCase 扩展功能
/// - DIP: 依赖抽象（UseCase），不依赖具体实现
class ProductAddEditController {
  final Ref ref;

  ProductAddEditController(this.ref);

  /// 提交表单并返回操作结果
  /// 
  /// 根据表单数据自动选择执行路径：
  /// - 多变体模式：批量创建商品
  /// - 单商品模式：创建或更新单个商品
  Future<ProductOperationResult> submitForm(ProductFormData data) async {
    // 多变体模式：批量创建商品
    if (data.isMultiVariantMode && data.variants.isNotEmpty && data.isCreateMode) {
      final useCase = ref.read(submitMultiVariantsUseCaseProvider);
      return useCase.execute(data);
    }

    // 单商品模式
    final useCase = ref.read(submitSingleProductUseCaseProvider);
    return useCase.execute(data);
  }
}
