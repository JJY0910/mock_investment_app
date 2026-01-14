import 'package:flutter/material.dart';
import '../models/plan_tier.dart';
import 'subscription_provider.dart';

/// Entitlement Provider
/// 플랜 기반 기능 접근 권한 SSOT (Single Source of Truth)
/// 
/// SubscriptionProvider를 래핑하여 기능별 접근 권한 제공
class EntitlementProvider extends ChangeNotifier {
  final SubscriptionProvider _subscriptionProvider;
  
  EntitlementProvider(this._subscriptionProvider) {
    // SubscriptionProvider 변경 시 알림
    _subscriptionProvider.addListener(_onSubscriptionChanged);
  }
  
  void _onSubscriptionChanged() {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _subscriptionProvider.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
  
  // === 현재 플랜 정보 ===
  
  PlanTier get currentTier => _subscriptionProvider.currentTier;
  bool get isFree => _subscriptionProvider.isFree;
  bool get isPro => _subscriptionProvider.isPro;
  bool get isMax => _subscriptionProvider.isMax;
  bool get hasPremium => _subscriptionProvider.hasPremium;
  
  // === 랭킹 접근 권한 ===
  
  /// Top 10 총자산 랭킹 조회 가능 여부
  bool get canViewTop10TotalAssets => currentTier.canViewTop10TotalAssets;
  
  /// 수익률 탭 접근 가능 여부
  bool get canViewProfitTabs => currentTier.canViewProfitTabs;
  
  /// Free 플랜 랭킹 범위
  int get freeRankStart => PlanTier.freeRankStart;
  int get freeRankEnd => PlanTier.freeRankEnd;
  
  /// 특정 순위 조회 가능 여부
  bool canViewRank(int rank) {
    if (hasPremium) return true;
    // Free 플랜: 11~50위만
    return rank >= freeRankStart && rank <= freeRankEnd;
  }
  
  // === AI 코치 제한 ===
  
  /// 일일 AI 코치 사용 횟수
  int get maxAICoachDaily => currentTier.maxAICoachDaily;
  
  /// AI 코치 무제한 여부
  bool get hasUnlimitedAICoach => currentTier == PlanTier.max;
  
  // === 충전 제한 ===
  
  /// 일일 충전 횟수
  int get maxDailyRecharges => currentTier.maxDailyRecharges;
  
  /// 무제한 충전 여부
  bool get hasUnlimitedRecharges => hasPremium;
  
  // === 광고 ===
  
  /// 광고 표시 여부 (Free만)
  bool get showAds => isFree;
  
  // === 유틸리티 ===
  
  /// 업그레이드 권유 메시지
  String getUpgradeMessage(String feature) {
    switch (feature) {
      case 'top10':
        return 'Top 10 랭킹을 보려면 Pro 플랜으로 업그레이드하세요!';
      case 'profit':
        return '수익률 랭킹을 보려면 Pro 플랜으로 업그레이드하세요!';
      case 'ai_coach':
        return 'AI 코치를 더 많이 사용하려면 Pro 플랜으로 업그레이드하세요!';
      default:
        return 'Pro 플랜으로 업그레이드하여 모든 기능을 이용하세요!';
    }
  }
}
