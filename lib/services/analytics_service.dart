import 'package:flutter/foundation.dart';
import '../providers/subscription_provider.dart';
import 'analytics_helper.dart';

/// GA4 Analytics Service
/// 
/// Sends real GA4 events on web platform via gtag.
/// Automatically enriches all events with common parameters.
/// The GA4 Tag is loaded in web/index.html.
/// PageViews are tracked automatically by gtag.
class AnalyticsService {
  static SubscriptionProvider? _subscriptionProvider;
  static bool _initWarningShown = false;
  
  /// Initialize with SubscriptionProvider for user_tier tracking
  static void init(SubscriptionProvider provider) {
    _subscriptionProvider = provider;
  }
  
  /// Enrich params with common parameters
  static Map<String, Object?> _enrichParams(Map<String, Object?> params) {
    final enriched = <String, Object?>{
      ...params,
      'platform': kIsWeb ? 'web' : 'mobile',
      'app_env': kDebugMode ? 'debug' : 'release',
      'app_version': '1.0.0', // From pubspec.yaml
    };
    
    // Add user_tier from SubscriptionProvider
    if (_subscriptionProvider != null) {
      enriched['user_tier'] = _subscriptionProvider!.currentTier.toString().split('.').last;
    } else {
      enriched['user_tier'] = 'unknown';
      
      // Warn once in debug mode
      if (kDebugMode && !_initWarningShown) {
        debugPrint('[Analytics] WARNING: AnalyticsService.init() not called. user_tier will be "unknown".');
        _initWarningShown = true;
      }
    }
    
    return enriched;
  }
  
  /// 회원가입
  static void logSignUp({String method = 'nickname_onboarding'}) {
    if (kDebugMode) {
      debugPrint('[Analytics] sign_up: method=$method');
    }
    
    sendGtagEvent('sign_up', _enrichParams({
      'method': method,
    }));
  }
  
  /// 거래 체결
  static void logTradeCompleted({
    required String tradeType,
    required String symbol,
    required double amount,
    double? price,
    double? value,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] trade_completed: type=$tradeType, symbol=$symbol, amount=$amount');
    }
    
    final params = <String, Object?>{
      'trade_type': tradeType,
      'symbol': symbol,
      'amount': amount,
      'currency': 'KRW',
    };
    
    if (price != null) params['price'] = price;
    if (value != null) params['value'] = value;
    
    sendGtagEvent('trade_completed', _enrichParams(params));
  }
  
  /// 구독 업그레이드
  static void logBeginCheckout({
    required String itemName,
    required double value,
    String? itemId,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] begin_checkout: item=$itemName, val=$value');
    }
    
    // Generate item_id from itemName if not provided
    final id = itemId ?? itemName.toLowerCase().replaceAll(' ', '_');
    
    sendGtagEvent('begin_checkout', _enrichParams({
      'currency': 'KRW',
      'value': value,
      'items': [
        {
          'item_id': id,
          'item_name': itemName,
          'item_category': 'subscription',
          'price': value,
          'quantity': 1,
        }
      ],
    }));
  }
  
  /// AI 코치 카드 조회
  static void logCoachCardViewed({
    required bool coachLocked,
    double? scoreCurrent,
    int? badgesCount,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] coach_card_viewed: locked=$coachLocked');
    }
    
    final params = <String, Object?>{
      'coach_locked': coachLocked,
    };
    
    if (scoreCurrent != null) params['score_current'] = scoreCurrent;
    if (badgesCount != null) params['badges_count'] = badgesCount;
    
    sendGtagEvent('coach_card_viewed', _enrichParams(params));
  }
  
  /// AI 코치 업그레이드 안내 클릭
  static void logCoachUpgradePromptClick({
    required String entryPoint,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] coach_upgrade_prompt_click: entry=$entryPoint');
    }
    
    sendGtagEvent('coach_upgrade_prompt_click', _enrichParams({
      'entry_point': entryPoint,
      'coach_locked': true,
    }));
  }
  
  /// 배지 획득
  static void logCoachBadgeEarned({
    required String badgeId,
    required String badgeName,
    double? scoreAtEarn,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] coach_badge_earned: $badgeId ($badgeName)');
    }
    
    final params = <String, Object?>{
      'badge_id': badgeId,
      'badge_name': badgeName,
    };
    
    if (scoreAtEarn != null) params['score_at_earn'] = scoreAtEarn;
    
    sendGtagEvent('coach_badge_earned', _enrichParams(params));
  }
}
