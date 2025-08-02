import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// 图片缓存管理页面
/// 提供缓存状态查看和管理功能
class ImageCacheManagementScreen extends StatefulWidget {
  const ImageCacheManagementScreen({super.key});

  @override
  State<ImageCacheManagementScreen> createState() =>
      _ImageCacheManagementScreenState();
}

class _ImageCacheManagementScreenState
    extends State<ImageCacheManagementScreen> {
  final ImageCacheService _cacheService = ImageCacheService();
  Map<String, dynamic>? _cacheStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStatus();
  }

  Future<void> _loadCacheStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = _cacheService.getCacheStatus();
      setState(() {
        _cacheStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(context, message: '获取缓存状态失败: $e', isError: true);
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await _showConfirmDialog(
      '清理所有缓存',
      '确定要清理所有图片缓存吗？这个操作不可恢复。',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _cacheService.clearAllCache();
        await _loadCacheStatus();
        showAppSnackBar(context, message: '缓存清理完成');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showAppSnackBar(context, message: '清理缓存失败: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片缓存管理'),
        actions: [
          IconButton(
            onPressed: _loadCacheStatus,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_cacheStatus == null) {
      return const Center(child: Text('无法获取缓存状态'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCacheOverviewCard(),
          const SizedBox(height: 16),
          _buildCacheDetailsCard(),
          const SizedBox(height: 16),
          _buildActionsCard(),
          const SizedBox(height: 16),
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildCacheOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cached, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '缓存概览',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    '内存缓存',
                    '${_cacheStatus!['memoryCount']}/${_cacheStatus!['maxMemorySize']}',
                    Colors.blue,
                    Icons.memory,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusItem(
                    '字节缓存',
                    '${_cacheStatus!['byteCount']}/${_cacheStatus!['maxByteSize']}',
                    Colors.green,
                    Icons.storage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '缓存详情',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              '缩略图缓存目录',
              _cacheStatus!['thumbnailCacheDir'] ?? '未设置',
              Icons.folder,
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              '内存缓存使用率',
              '${((_cacheStatus!['memoryCount'] as int) / (_cacheStatus!['maxMemorySize'] as int) * 100).toStringAsFixed(1)}%',
              Icons.pie_chart,
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              '字节缓存使用率',
              '${((_cacheStatus!['byteCount'] as int) / (_cacheStatus!['maxByteSize'] as int) * 100).toStringAsFixed(1)}%',
              Icons.donut_small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '缓存操作',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllCache,
                icon: const Icon(Icons.clear_all),
                label: const Text('清理所有缓存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadCacheStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新缓存状态'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '缓存说明',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• 内存缓存：存储已解码的图片对象，访问速度最快\n'
              '• 字节缓存：存储图片字节数据，减少磁盘读取\n'
              '• 磁盘缓存：存储优化后的缩略图，持久化存储\n'
              '• 缓存会自动管理，无需手动清理\n'
              '• 清理缓存会释放内存并删除磁盘文件',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(value),
          icon: const Icon(Icons.copy, size: 16),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(context, message: '已复制到剪贴板');
  }

}
