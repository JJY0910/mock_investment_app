import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerService {
  static const String _keyDisclaimerV1 = 'disclaimer_accepted_v1';

  /// 고지 동의 여부 확인
  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDisclaimerV1) ?? false;
  }

  /// 고지 동의 저장
  static Future<void> setAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDisclaimerV1, accepted);
  }
}
