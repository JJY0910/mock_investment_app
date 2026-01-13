import 'dart:async';
import 'package:flutter/material.dart';
import '../services/exchange_rate_api.dart';

/// 환율 정보 Provider
/// USD→KRW 환율을 1회 로드 (USDT≈USD 가정)
class ExchangeRateProvider extends ChangeNotifier {
  final ExchangeRateApiService _api = ExchangeRateApiService();

  static const double _defaultRate = 1350.0; // Fallback 환율

  double _usdtToKrwRate = _defaultRate;
  bool _loading = false;
  String? _error;

  /// 현재 USDT→KRW 환율 (default 또는 실제 로드값)
  double get usdtToKrwRate => _usdtToKrwRate;

  /// 로딩 상태
  bool get loading => _loading;

  /// 에러 (내부용, UI 최소 노출)
  String? get error => _error;

  /// 환율이 로드되었는지 (default가 아닌 실제값)
  bool get isLoaded => _usdtToKrwRate != _defaultRate;

  /// 1회 로드 (중복 호출 방지)
  Future<void> loadOnce({bool forceReload = false}) async {
    // 이미 로딩 중이면 무시
    if (_loading) {
      print('[ExchangeRateProvider] Already loading, skipping');
      return;
    }

    // 이미 로드되었고 강제 새로고침이 아니면 무시
    if (isLoaded && !forceReload) {
      print('[ExchangeRateProvider] Already loaded, skipping');
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('[ExchangeRateProvider] Loading USD→KRW rate...');

      final rate = await _api.fetchUsdToKrw();

      if (rate != null) {
        _usdtToKrwRate = rate;
        _error = null;
        print('[ExchangeRateProvider] Successfully loaded rate: $rate');
      } else {
        // API 실패 시 fallback 유지
        _error = '환율 정보를 불러오지 못했습니다. 기본값을 사용합니다.';
        print('[ExchangeRateProvider] Failed to load, using fallback: $_defaultRate');
      }

      notifyListeners();
    } catch (e) {
      // 예상치 못한 에러 시 fallback 유지
      _error = '환율 정보를 불러오지 못했습니다. 기본값을 사용합니다.';
      print('[ExchangeRateProvider] Unexpected error: $e');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// USDT를 KRW로 환산
  double usdtToKrw(double usdt) {
    return usdt * _usdtToKrwRate;
  }

  /// KRW를 USDT로 환산
  double krwToUsdt(double krw) {
    return krw / _usdtToKrwRate;
  }
}
