import 'package:flutter/material.dart';

/// 全屏图片查看器演示页面
class FullScreenImageViewerDemo extends StatelessWidget {
  const FullScreenImageViewerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全屏图片查看器演示'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 演示说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '全屏图片查看器功能演示',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '此演示页面展示了全屏图片查看器的完整功能：\n'
                      '• 支持缩放操作（0.5x - 4x）\n'
                      '• 支持平移手势\n'
                      '• 支持双击缩放\n'
                      '• 提供缩放控制按钮\n'
                      '• 显示当前缩放级别\n'
                      '• 平滑的动画过渡效果',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 功能说明
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '操作说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 单击图片：在产品详情页、列表页或对话框中点击图片\n'
                      '• 长按缩略图：在产品列表中长按缩略图快速查看\n'
                      '• 双指缩放：放大或缩小图片\n'
                      '• 拖拽平移：移动放大后的图片\n'
                      '• 底部按钮：使用控制按钮进行精确操作\n'
                      '• 点击关闭：点击左上角关闭按钮或返回键退出',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 功能特性
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '功能特性',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Hero动画：提供流畅的过渡动画效果\n'
                      '• 手势控制：支持单指和双指手势操作\n'
                      '• 缩放限制：最小0.5倍，最大4倍缩放\n'
                      '• 动画控制：平滑的缩放和重置动画\n'
                      '• 状态指示：实时显示当前缩放级别\n'
                      '• 沉浸体验：自动隐藏状态栏和导航栏\n'
                      '• 错误处理：图片加载失败时的友好提示',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 使用场景
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.apps, color: Colors.purple.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '使用场景',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 产品详情页：点击产品图片查看大图\n'
                      '• 产品列表：长按缩略图快速预览\n'
                      '• 快速对话框：点击对话框中的产品图片\n'
                      '• 数据库查看器：点击头像图片查看\n'
                      '• 任何需要放大查看图片的场景',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 返回按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
