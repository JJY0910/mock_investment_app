import 'package:flutter/foundation.dart';

/// GA4 Analytics Service (Universal Stub)
/// 
/// Platform limitations prevented direct use of 'dart:js' without package upgrades.
/// Currently logs events to console for verification.
class AnalyticsService {
  
  /// Sign up event
  static void logSignUp({String method = 'kakao'}) {
    if (kIsWeb) {
      print('[Analytics] sign_up: method=$method (GA4 simulated)');
    }
  }
  
  /// Trade completed event
  static void logTradeCompleted({
    required String symbol,
    required String side,
    required double valueKrw,
    required double scoreDelta,
  }) {
    if (kIsWeb) {
      print('[Analytics] trade_completed: $symbol $side, val=$valueKrw, delta=$scoreDelta (GA4 simulated)');
    }
  }
  
  /// Begin checkout event
  static void logBeginCheckout({
    required String tier,
    required double valueUsd,
  }) {
    if (kIsWeb) {
      print('[Analytics] begin_checkout: tier=$tier, value=$valueUsd (GA4 simulated)');
    }
  }
}
