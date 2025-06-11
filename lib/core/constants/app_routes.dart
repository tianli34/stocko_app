// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String productEdit = '/products/:id/edit';
  static const String productNew = '/products/new';
  static const String categories = '/categories';
  static const String categoryTest = '/categories/test';
  static const String inventory = '/inventory';
  static const String sales = '/sales';
  static const String test = '/test';

  // 辅助方法，用于生成带参数的路由
  static String productDetailPath(String id) => '/products/$id';
  static String productEditPath(String id) => '/products/$id/edit';
}
