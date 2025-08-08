import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stocko - 首页')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '欢迎使用 Stocko 库存管理系统',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '请选择功能模块',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.products),
                    child: const Text('产品管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.categories),
                    child: const Text('类别管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inventory),
                    child: const Text('库存管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inboundCreate),
                    child: const Text('新建入库单'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.purchase),
                    child: const Text('采购管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.sales),
                    child: const Text('销售管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.saleCreate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('收银台'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.customers),
                    child: const Text('客户管理'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('设置'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.push(AppRoutes.databaseManagement),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('数据库管理'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.push(AppRoutes.databaseViewer),
                    child: const Text('数据库查看器'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.push(AppRoutes.categoryTest),
                    child: const Text('类别管理测试'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}