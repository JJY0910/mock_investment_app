import 'dart:async';
import 'package:flutter/material.dart';
import '../models/market_quote.dart';
import '../services/binance_api.dart';
import '../data/coin_registry.dart';

/// 시장 시세 정보 Provider
/// 1회 로드만 지원 (실시간 폴링 금지)
class MarketQuotesProvider extends ChangeNotifier {
  final BinanceApiService _api = BinanceApiService();
  final CoinRegistry _registry = CoinRegistry();

  Map<String, MarketQuote> _quotesBySymbol = {};
  bool _loading = false;
  String? _error;
  DateTime? _lastRetryTime; // retry 연타 방지용

  /// 심볼별 시세 정보
  Map<String, MarketQuote> get quotesBySymbol => Map.unmodifiable(_quotesBySymbol);

  /// 로딩 상태
  bool get loading => _loading;

  /// 에러 메시지
  String? get error => _error;

  /// 특정 심볼의 시세 가져오기
  MarketQuote? getQuote(String symbol) {
    return _quotesBySymbol[symbol];
  }

  /// CoinInfo의 symbol로 시세 가져오기
  MarketQuote? getQuoteForCoin(String base) {
    final symbol = '$base' 'USDT'; // BTCUSDT 형태
    return _quotesBySymbol[symbol];
  }

  /// 1회 로드 (모든 코인 시세)
  /// [보강 1] 중복 호출 방지 가드
  Future<void> loadOnce({bool forceReload = false}) async {
    // 이미 로딩 중이면 무시
    if (_loading) {
      print('[MarketQuotesProvider] Already loading, skipping');
      return;
    }

    // 이미 quotes가 있고 강제 새로고침이 아니면 무시
    if (_quotesBySymbol.isNotEmpty && !forceReload) {
      print('[MarketQuotesProvider] Quotes already loaded, skipping');
      return;
    }

    // [보강 2] 시작 시 notify
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // [보강 3] CoinRegistry에서 직접 가져오기 (소스 고정)
      final coins = _registry.getKrwMarket();
      final symbols = coins.map((coin) => '${coin.base}USDT').toList();

      print('[MarketQuotesProvider] Loading quotes for ${symbols.length} symbols');

      // Binance API 호출
      final quotes = await _api.fetchTickers(symbols);

      _quotesBySymbol = quotes;
      _error = null;

      print('[MarketQuotesProvider] Successfully loaded ${_quotesBySymbol.length} quotes');

      // [보강 2] 성공 시 notify
      notifyListeners();
    } on TimeoutException {
      // [보강 6] 에러 메시지 품질 개선
      _error = '시세 조회 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.';
      print('[MarketQuotesProvider] Timeout error');
      notifyListeners();
    } catch (e) {
      // [보강 6] 일반 에러는 사용자 친화적으로 변환
      if (e.toString().contains('네트워크')) {
        _error = '네트워크 연결을 확인해주세요.';
      } else if (e.toString().contains('ClientException')) {
        _error = '서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
      } else {
        _error = '시세 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.';
      }

      print('[MarketQuotesProvider] Error loading quotes: $e');
      notifyListeners();
    } finally {
      // [보강 1] finally로 loading=false 보장
      _loading = false;
      notifyListeners();
    }
  }

  /// 재시도 (에러 상태에서 호출)
  /// [보강 4] retry 연타 방지 (1초 디바운스)
  Future<void> retry() async {
    // 로딩 중이면 무시
    if (_loading) {
      print('[MarketQuotesProvider] Already loading, retry ignored');
      return;
    }

    // 1초 이내 재호출 방지
    final now = DateTime.now();
    if (_lastRetryTime != null && now.difference(_lastRetryTime!).inSeconds < 1) {
      print('[MarketQuotesProvider] Retry too soon, ignored');
      return;
    }

    _lastRetryTime = now;
    print('[MarketQuotesProvider] Retrying...');
    await loadOnce(forceReload: true);
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
