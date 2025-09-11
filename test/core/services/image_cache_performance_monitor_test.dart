import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/services/image_cache_performance_monitor.dart';

void main() {
  group('ImageCachePerformanceMonitor', () {
    test('记录命中/未命中与命中率', () {
      final m = ImageCachePerformanceMonitor();
      m.initialize();
      m.recordCacheHit('a/b/c1.png');
      m.recordCacheHit('a/b/c2.png');
      m.recordCacheMiss('a/b/c3.png');

      expect(m.getCacheHitRate(), closeTo(2 / 3, 1e-6));
      final report = m.getPerformanceReport();
      expect(report['totalRequests'], 3);
      expect(report['cacheHits'], 2);
      expect(report['cacheMisses'], 1);
    });

    test('记录加载时间并获取统计', () async {
      final m = ImageCachePerformanceMonitor();
      m.initialize();
      m.recordLoadTime(const Duration(milliseconds: 120));
      m.recordLoadTime(const Duration(milliseconds: 80));
      m.recordLoadTime(const Duration(milliseconds: 200));

      expect(m.getAverageLoadTime().inMilliseconds, 133);
      expect(m.getFastestLoadTime().inMilliseconds, 80);
      expect(m.getSlowestLoadTime().inMilliseconds, 200);
    });

    test('最常请求图片列表按频次排序', () {
      final m = ImageCachePerformanceMonitor();
      m.initialize();
      for (int i = 0; i < 5; i++) {
        m.recordCacheHit('images/a.png');
      }
      for (int i = 0; i < 3; i++) {
        m.recordCacheMiss('images/b.png');
      }
      m.recordCacheHit('images/c.png');

      final top = m.getMostRequestedImages(limit: 2);
      expect(top.length, 2);
      expect(top.first.key, 'a.png');
      expect(top.first.value, 5);
    });

    test('性能等级依据命中率与平均耗时', () {
      final m = ImageCachePerformanceMonitor();
      m.initialize();
      // 命中率 1.0
      for (int i = 0; i < 10; i++) {
        m.recordCacheHit('x$i');
        m.recordLoadTime(const Duration(milliseconds: 50));
      }
      expect(m.getPerformanceGrade(), anyOf('A+', 'A'));

      m.reset();
      for (int i = 0; i < 10; i++) {
        if (i.isEven) {
          m.recordCacheHit('y$i');
        } else {
          m.recordCacheMiss('y$i');
        }
        m.recordLoadTime(const Duration(milliseconds: 400));
      }
      // 命中率约 0.5 且耗时较长 -> D
      expect(m.getPerformanceGrade(), 'D');
    });
  });
}
