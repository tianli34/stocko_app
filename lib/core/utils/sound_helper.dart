import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// 音效播放工具类
class SoundHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// 播放扫码成功音效
  static Future<void> playSuccessSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/scan_success2.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('播放音效失败，使用系统音效: $e');
      }
      SystemSound.play(SystemSoundType.click);
    }
  }
}