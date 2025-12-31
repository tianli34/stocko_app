// lib/features/product/presentation/models/product_operation_result.dart

import '../../domain/model/product.dart';

/// 操作结果
class ProductOperationResult {
  final bool success;
  final String? message;
  final ProductModel? product;

  const ProductOperationResult._(this.success, {this.message, this.product});

  factory ProductOperationResult.success({
    String? message,
    ProductModel? product,
  }) =>
      ProductOperationResult._(true, message: message, product: product);

  factory ProductOperationResult.failure(String message) =>
      ProductOperationResult._(false, message: message);

  /// 是否成功
  bool get isSuccess => success;

  /// 是否失败
  bool get isFailure => !success;
}
