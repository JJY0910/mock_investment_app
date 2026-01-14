import 'package:flutter/foundation.dart';

/// GA4 Analytics Service (Universal Stub)
/// 
/// Platform limitations prevented direct use of 'dart:js' or 'package:web'.
/// The GA4 Tag IS present in index.html, so PageViews are tracked automatically.
/// Event calls are simulated.
class AnalyticsService {
  
  /// 회원가입
  static void logSignUp({String method = 'nickname_onboarding'}) {
    // Avoid unused parameter warning by using it
    debugPrint('[Analytics] sign_up: method=$method');
  }
  
  /// 거래 체결
  static void logTradeCompleted({
    required String tradeType,
    required String symbol,
    required double amount,
  }) {
    debugPrint('[Analytics] trade_completed: type=$tradeType, symbol=$symbol, amount=$amount');
  }
  
  /// 구독 업그레이드
  static void logBeginCheckout({
    required String itemName,
    required double value,
  }) {
    debugPrint('[Analytics] begin_checkout: item=$itemName, val=$value');
  }
}
