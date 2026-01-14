import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/plan_tier.dart';
import '../models/subscription.dart';

/// 구독 관리 Provider
class SubscriptionProvider extends ChangeNotifier {
  static const String _storageKey = 'subscription_v1';
  
  Subscription _subscription = Subscription.free();
  
  Subscription get subscription => _subscription;
  PlanTier get currentTier => _subscription.tier;
  bool get isFree => _subscription.isFree;
  bool get isPro => _subscription.isPro;
  bool get isMax => _subscription.isMax;
  bool get hasPremium => _subscription.hasPremium;
  
  /// 로드
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      
      if (json != null && json.isNotEmpty) {
        final data = jsonDecode(json);
        _subscription = Subscription.fromJson(data);
      } else {
        _subscription = Subscription.free();
      }
      
      notifyListeners();
      print('[SubscriptionProvider] Loaded: ${_subscription.tier.displayName}');
    } catch (e) {
      print('[SubscriptionProvider] Error loading: $e');
      _subscription = Subscription.free();
    }
  }
  
  /// 저장
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_subscription.toJson());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      print('[SubscriptionProvider] Error saving: $e');
    }
  }
  
  /// 플랜 업그레이드 (Mock)
  Future<void> upgradeTo(PlanTier tier) async {
    if (tier == PlanTier.free) {
      _subscription = Subscription.free();
    } else {
      final now = DateTime.now();
      _subscription = Subscription(
        tier: tier,
        startedAt: now,
        expiresAt: now.add(const Duration(days: 30)), // 30일 체험
      );
    }
    
    await _save();
    notifyListeners();
    print('[SubscriptionProvider] Upgraded to: ${tier.displayName}');
  }
  
  /// 플랜 다운그레이드
  Future<void> downgradeToFree() async {
    _subscription = Subscription.free();
    await _save();
    notifyListeners();
    print('[SubscriptionProvider] Downgraded to Free');
  }
  
  /// 구독 만료 체크
  bool isExpiringSoon() {
    if (_subscription.expiresAt == null) return false;
    final daysRemaining = _subscription.expiresAt!.difference(DateTime.now()).inDays;
    return daysRemaining <= 7 && daysRemaining > 0;
  }
  
  /// 남은 일수
  int? getDaysRemaining() {
    if (_subscription.expiresAt == null) return null;
    final days = _subscription.expiresAt!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }
}
