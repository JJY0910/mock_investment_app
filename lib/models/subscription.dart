import 'plan_tier.dart';

/// 구독 정보 모델
class Subscription {
  final PlanTier tier;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  
  Subscription({
    required this.tier,
    this.startedAt,
    this.expiresAt,
  });
  
  bool get isActive {
    if (tier == PlanTier.free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }
  
  bool get isFree => tier == PlanTier.free;
  bool get isPro => tier == PlanTier.pro && isActive;
  bool get isElite => tier == PlanTier.elite && isActive;
  bool get hasPremium => isPro || isElite;
  
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString().split('.').last,
      'startedAt': startedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
  
  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Safe parsing of tier with fallback
    PlanTier tier = PlanTier.free;
    
    try {
      final tierValue = json['tier'];
      if (tierValue is String) {
        tier = PlanTier.values.firstWhere(
          (t) => t.toString().split('.').last == tierValue,
          orElse: () => PlanTier.free,
        );
      }
    } catch (e) {
      print('[Subscription] Error parsing tier: $e, defaulting to free');
    }
    
    return Subscription(
      tier: tier,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
  
  factory Subscription.free() {
    return Subscription(tier: PlanTier.free);
  }
}
