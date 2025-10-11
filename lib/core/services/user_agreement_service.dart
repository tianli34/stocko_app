import 'package:shared_preferences/shared_preferences.dart';

class UserAgreementService {
  static const String _keyAgreementAccepted = 'user_agreement_accepted';
  static const String _keyAgreementVersion = 'user_agreement_version';
  static const String currentVersion = '1.0.0'; // 协议版本号

  /// 检查用户是否已同意当前版本的协议
  Future<bool> hasAcceptedAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_keyAgreementAccepted) ?? false;
    final version = prefs.getString(_keyAgreementVersion) ?? '';
    
    // 只有同意过且版本匹配才返回true
    return accepted && version == currentVersion;
  }

  /// 保存用户同意状态
  Future<void> acceptAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAgreementAccepted, true);
    await prefs.setString(_keyAgreementVersion, currentVersion);
  }

  /// 清除同意状态（用于测试或重置）
  Future<void> clearAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAgreementAccepted);
    await prefs.remove(_keyAgreementVersion);
  }
}
