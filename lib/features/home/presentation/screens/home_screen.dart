import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/flavor_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/home_stats_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/feature_grid_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flavorConfig = ref.watch(flavorConfigProvider);
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('铺得清'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: '设置',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeStatsProvider);
          await ref.read(homeStatsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日概览区
              _buildSectionTitle(theme, '今日概览', Icons.analytics_outlined),
              const SizedBox(height: 12),
              _buildStatsSection(statsAsync),
              
              const SizedBox(height: 24),
              
              // 快捷操作区
              _buildSectionTitle(theme, '快捷操作', Icons.flash_on_outlined),
              const SizedBox(height: 12),
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // 功能模块区
              _buildSectionTitle(theme, '功能模块', Icons.apps_outlined),
              const SizedBox(height: 12),
              _buildFeatureGrid(statsAsync, flavorConfig),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.065,
        children: [
          StatsCard(
            title: '销售额',
            value: _currencyFormat.format(stats.todaySales),
            subtitle: '${stats.todayOrderCount} 笔订单',
            icon: Icons.trending_up,
            color: Colors.green,
            onTap: () => context.push(AppRoutes.saleRecords),
          ),
          StatsCard(
            title: '利润',
            value: _currencyFormat.format(stats.todayProfit),
            subtitle: stats.todayProfit >= 0 ? '盈利' : '亏损',
            icon: Icons.account_balance_wallet,
            color: stats.todayProfit >= 0 ? Colors.blue : Colors.red,
          ),
          StatsCard(
            title: '顾客数',
            value: stats.todayCustomerCount.toString(),
            subtitle: '今日服务',
            icon: Icons.people,
            color: Colors.orange,
            onTap: () => context.push(AppRoutes.customers),
          ),
          StatsCard(
            title: '库存预警',
            value: stats.lowStockCount.toString(),
            subtitle: stats.lowStockCount > 0 ? '需要补货' : '库存充足',
            icon: Icons.warning_amber,
            color: stats.lowStockCount > 0 ? Colors.red : Colors.grey,
            onTap: () => context.push(AppRoutes.inventoryQuery),
          ),
        ],
      ),
      loading: () => _buildStatsLoading(),
      error: (e, _) => _buildStatsError(e),
    );
  }

  Widget _buildStatsLoading() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: List.generate(4, (_) => _buildShimmerCard()),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildStatsError(Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text('加载失败: $error'),
            TextButton(
              onPressed: () => ref.invalidate(homeStatsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        QuickActionButton(
          label: '收银台',
          icon: Icons.point_of_sale,
          color: Colors.green,
          onTap: () => context.push(AppRoutes.saleCreate),
          isPrimary: true,
        ),
        QuickActionButton(
          label: '采购入库',
          icon: Icons.add_shopping_cart,
          color: Colors.blue,
          onTap: () => context.push(AppRoutes.inboundCreate),
        ),
        QuickActionButton(
          label: '新增货品',
          icon: Icons.add_box,
          color: Colors.teal,
          onTap: () => context.push(AppRoutes.productNew),
        ),
        QuickActionButton(
          label: '库存查询',
          icon: Icons.search,
          color: Colors.purple,
          onTap: () => context.push(AppRoutes.inventoryQuery),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(AsyncValue statsAsync, FlavorConfig flavorConfig) {
    final lowStockCount = statsAsync.valueOrNull?.lowStockCount ?? 0;
    
    final features = <_FeatureItem>[
      _FeatureItem(
        label: '货品管理',
        icon: Icons.inventory_2,
        color: Colors.indigo,
        route: AppRoutes.products,
      ),
      _FeatureItem(
        label: '销售记录',
        icon: Icons.receipt_long,
        color: Colors.green,
        route: AppRoutes.saleRecords,
      ),
      _FeatureItem(
        label: '库存管理',
        icon: Icons.warehouse,
        color: Colors.purple,
        route: AppRoutes.inventory,
        badge: lowStockCount > 0 ? lowStockCount : null,
      ),
      _FeatureItem(
        label: '采购记录',
        icon: Icons.receipt_long,
        color: Colors.blue,
        route: AppRoutes.inventoryPurchaseRecords,
      ),
      _FeatureItem(
        label: '客户管理',
        icon: Icons.people,
        color: Colors.orange,
        route: AppRoutes.customers,
      ),
      _FeatureItem(
        label: '库存盘点',
        icon: Icons.fact_check,
        color: Colors.teal,
        route: AppRoutes.stocktakeList,
      ),
      _FeatureItem(
        label: '产品排行',
        icon: Icons.leaderboard,
        color: Colors.amber.shade700,
        route: AppRoutes.productRanking,
      ),
      _FeatureItem(
        label: '退货管理',
        icon: Icons.assignment_return,
        color: Colors.red.shade400,
        route: AppRoutes.saleReturns,
      ),
    ];

    // 添加调试功能（仅在开发版本）
    if (flavorConfig.featureFlags[Feature.showDatabaseTools] == true) {
      features.addAll([
        _FeatureItem(
          label: '数据库管理',
          icon: Icons.storage,
          color: Colors.grey.shade700,
          route: AppRoutes.databaseManagement,
        ),
        _FeatureItem(
          label: '数据库查看',
          icon: Icons.table_chart,
          color: Colors.grey.shade600,
          route: AppRoutes.databaseViewer,
        ),
      ]);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureGridItem(
          label: feature.label,
          icon: feature.icon,
          color: feature.color,
          badge: feature.badge,
          onTap: () => context.push(feature.route),
        );
      },
    );
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final int? badge;

  _FeatureItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
  });
}
