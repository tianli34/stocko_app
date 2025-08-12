import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/application/provider/product_providers.dart';
import '../../../product/application/category_notifier.dart';
import '../../../product/data/repository/product_unit_repository.dart';
import '../../../product/data/repository/unit_repository.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';

/// 数据库展示屏幕
/// 显示数据库中所有表的数据
class DatabaseViewerScreen extends ConsumerStatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  ConsumerState<DatabaseViewerScreen> createState() =>
      _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends ConsumerState<DatabaseViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 初始加载数据
    Future.microtask(() {
      ref.read(allProductsProvider);
      ref.read(categoryListProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库查看器'),
        // 移除自定义leading，让go_router自动处理手势返回
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: '产品'),
            Tab(icon: Icon(Icons.category), text: '类别'),
            Tab(icon: Icon(Icons.straighten), text: '单位'),
            Tab(icon: Icon(Icons.link), text: '产品单位'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildCategoriesTab(),
          _buildUnitsTab(),
          _buildProductUnitsTab(),
        ],
      ),
    );
  }

  /// 刷新所有数据
  void _refreshData() {
    // 刷新产品数据
    ref.invalidate(allProductsProvider);
    // 刷新类别数据
    ref.read(categoryListProvider.notifier).loadCategories();

    // 显示刷新提示
    showAppSnackBar(context, message: '数据已刷新');
  }

  /// 构建产品数据页面
  Widget _buildProductsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final productsAsyncValue = ref.watch(allProductsProvider);

        return productsAsyncValue.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('暂无产品数据'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: product.image != null && product.image!.isNotEmpty
                        ? _buildCachedCircleAvatar(product.image!, index + 1)
                        : CircleAvatar(child: Text('${index + 1}')),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${product.id}'),
                        // 条码信息已移除，现在条码存储在独立的条码表中
                        if (product.sku != null) Text('SKU: ${product.sku}'),
                        if (product.categoryId != null)
                          Text('类别ID: ${product.categoryId}'),
                        if (product.retailPrice != null)
                          Text('零售价: ${product.retailPrice!.format()}'),
                        Text('状态: ${product.status}')
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('加载产品数据失败: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(allProductsProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建类别数据页面
  Widget _buildCategoriesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesState = ref.watch(categoryListProvider);

        if (categoriesState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoriesState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('加载类别数据失败: ${categoriesState.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(categoryListProvider.notifier).loadCategories(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final categories = categoriesState.categories;

        if (categories.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无类别数据'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(category.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${category.id}'),
                    if (category.parentId != null)
                      Text('父类别ID: ${category.parentId}')
                    else
                      const Text('根类别'),
                  ],
                ),
                trailing: Icon(
                  category.parentId == null
                      ? Icons.folder
                      : Icons.subdirectory_arrow_right,
                  color: category.parentId == null ? Colors.blue : Colors.grey,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建单位数据页面
  Widget _buildUnitsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final unitRepository = ref.watch(unitRepositoryProvider);

        return FutureBuilder(
          future: unitRepository.getAllUnits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('加载单位数据失败: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            final units = snapshot.data ?? [];

            if (units.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.straighten_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('暂无单位数据'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(unit.name),
                    subtitle: Text('ID: ${unit.id}'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 构建产品单位数据页面
  Widget _buildProductUnitsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final repo = ref.watch(productUnitRepositoryProvider);

        return FutureBuilder(
          future: repo.getAllProductUnits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('加载产品单位数据失败: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            final productUnits = snapshot.data ?? [];

            if (productUnits.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('暂无产品单位数据'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: productUnits.length,
              itemBuilder: (context, index) {
                final pu = productUnits[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('产品ID: ${pu.productId}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('产品单位ID: ${pu.productUnitId ?? '-'}'),
                        Text('单位ID: ${pu.unitId}'),
                        Text('换算率: ${pu.conversionRate}'),
                        if (pu.sellingPriceInCents != null)
                          Text('售价(分): ${pu.sellingPriceInCents}'),
                        if (pu.wholesalePriceInCents != null)
                          Text('批发价(分): ${pu.wholesalePriceInCents}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCachedCircleAvatar(String imagePath, int index) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imagePath),
      child: Hero(
        tag: 'db_viewer_image_$imagePath',
        child: ClipOval(
          child: CachedImageWidget(
            imagePath: imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 显示全屏图片查看器
  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(
              imagePath: imagePath,
              heroTag: 'db_viewer_image_$imagePath',
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
