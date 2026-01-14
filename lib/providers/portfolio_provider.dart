import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/coin_info.dart';
import '../models/trade_fill.dart';
import '../services/trade_engine.dart';
import '../config/trading_fees.dart';
import 'trade_history_provider.dart';
import 'trader_score_provider.dart'; // PHASE 2-1: 점수 계산
import '../services/analytics_service.dart'; // GA4: 점수 계산

/// 포트폴리오 Provider
/// shared_preferences로 영구 저장
class PortfolioProvider extends ChangeNotifier {
  static const String _storageKey = 'portfolio_v2';

  Portfolio _portfolio = Portfolio.defaultPortfolio();
  bool _loading = false;
  String? _lastError;

  /// 현재 포트폴리오
  Portfolio get portfolio => _portfolio;

  /// 로딩 상태
  bool get loading => _loading;

  /// 마지막 에러
  String? get lastError => _lastError;

  /// 현금
  double get cashKrw => _portfolio.cashKrw;

  /// 보유 코인 목록
  List<Holding> get holdings => _portfolio.holdings;

  /// 특정 코인 보유 여부
  bool hasHolding(String pairKey) => _portfolio.hasHolding(pairKey);

  /// 특정 코인 조회
  Holding? getHolding(String pairKey) => _portfolio.getHolding(pairKey);

  /// 총자산 (현재가 맵 필요)
  double getTotalValueKrw(Map<String, double> priceMap) {
    return _portfolio.getTotalValueKrw(priceMap);
  }

  /// 총 평가손익
  double getTotalPnlKrw(Map<String, double> priceMap) {
    return _portfolio.getTotalPnlKrw(priceMap);
  }

  /// 총 수익률
  double getTotalPnlPercent(Map<String, double> priceMap) {
    return _portfolio.getTotalPnlPercent(priceMap);
  }

  /// 로드 (shared_preferences에서)
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _portfolio = Portfolio.fromJson(jsonData);
        print('[PortfolioProvider] Loaded portfolio: $_portfolio');
      } else {
        print('[PortfolioProvider] No saved data, using default');
        _portfolio = Portfolio.defaultPortfolio();
      }
    } catch (e) {
      print('[PortfolioProvider] Error loading portfolio: $e');
      // 로드 실패 시 기본값 사용 (크래시 방지)
      _portfolio = Portfolio.defaultPortfolio();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 저장 (shared_preferences에)
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_portfolio.toJson());
      await prefs.setString(_storageKey, jsonString);
      print('[PortfolioProvider] Saved portfolio: $_portfolio');
    } catch (e) {
      print('[PortfolioProvider] Error saving portfolio: $e');
    }
  }

  /// 초기화 (기본값으로 복구)
  Future<void> resetToDefault() async {
    _portfolio = Portfolio.defaultPortfolio();
    await save();
    notifyListeners();
    print('[PortfolioProvider] Reset to default: $_portfolio');
  }

  /// 시장가 매수
  Future<bool> marketBuy({
    required CoinInfo coin,
    required double krwAmount,
    required double priceKrw,
    required TradeHistoryProvider historyProvider,
    TraderScoreProvider? scoreProvider, // PHASE 2-1: 점수 계산 옵션
    String source = 'market',
  }) async {
    _lastError = null;
    
    try {
      // 수수료 계산 (반올림)
      final fee = (krwAmount * kTradingFeeRate).roundToDouble();
      
      print('[PortfolioProvider] Buy ($source): ${coin.base} amount=₩$krwAmount price=₩$priceKrw fee=₩$fee');
      
      final newPortfolio = TradeEngine.marketBuy(
        coin: coin,
        krwAmount: krwAmount,
        priceKrw: priceKrw,
        portfolio: _portfolio,
        fee: fee,
      );

      _portfolio = newPortfolio;
      await save();
      
      // 히스토리 기록
      final buyQty = krwAmount / priceKrw;
      
      // PHASE 2-1: 점수 계산용 필드 (임시로 기본값)
      // 실제로는 주문 시 설정한 손절가/목표가를 사용해야 함
      double? rrRatio;
      double? stopLossPrice;
      double? takeProfitPrice;
      
      // 시장가 매수는 손절가/목표가 없음 (향후 로직 개선)
      // rrRatio는 진입 후 청산 시점에서 계산됨
      
      final fill = TradeFill(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        time: DateTime.now(),
        pairKey: coin.pairKey,
        base: coin.base,
        side: 'buy',
        priceKrw: priceKrw,
        quantity: buyQty,
        amountKrw: krwAmount,
        feeKrw: fee,
        source: source,
        // 점수 필드
        stopLossPrice: stopLossPrice,
        takeProfitPrice: takeProfitPrice,
        rrRatio: rrRatio,
        entryAccuracyPercent: 0, // 진입 시에는 0
        stopLossReached: false,
        stopLossFollowed: null, // 아직 미정
      );
      
      await historyProvider.addFill(fill);

      // PHASE 2-1: 점수 업데이트 (체결 직후)
      if (scoreProvider != null) {
        final trades30d = historyProvider.fills.where((f) =>
          f.time.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).toList();
        
        final scoreDelta = await scoreProvider.onTradeFilled(
          fill: fill,
          trades30d: trades30d,
        ) - scoreProvider.currentScore;
        
        // GA4: trade_completed event
        AnalyticsService.logTradeCompleted(
          tradeType: 'buy',
          symbol: coin.symbol,
          amount: quantity, // 수량
        );
      }

      notifyListeners();
      
      print('[PortfolioProvider] Buy success: ${_portfolio.holdings.length} holdings');
      return true;
    } catch (e) {
      _lastError = e.toString();
      print('[PortfolioProvider] Buy failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 시장가 매도
  Future<bool> marketSell({
    required CoinInfo coin,
    required double quantity,
    required double priceKrw,
    required TradeHistoryProvider historyProvider,
    TraderScoreProvider? scoreProvider, // PHASE 2-1: 점수 계산 옵션
    String source = 'market',
  }) async {
    _lastError = null;
    
    try {
      final sellAmount = quantity * priceKrw;
      // 수수료 계산 (반올림)
      final fee = (sellAmount * kTradingFeeRate).roundToDouble();
      
      print('[PortfolioProvider] Sell ($source): ${coin.base} qty=$quantity price=₩$priceKrw fee=₩$fee');
      
      final newPortfolio = TradeEngine.marketSell(
        coin: coin,
        quantity: quantity,
        priceKrw: priceKrw,
        portfolio: _portfolio,
        fee: fee,
      );

      _portfolio = newPortfolio;
      await save();

      // 히스토리 기록
      final fill = TradeFill(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        time: DateTime.now(),
        pairKey: coin.pairKey,
        base: coin.base,
        side: 'sell',
        priceKrw: priceKrw,
        quantity: quantity,
        amountKrw: sellAmount,
        feeKrw: fee,
        source: source,
        // 점수 필드
        stopLossPrice: null,
        takeProfitPrice: null,
        rrRatio: null, // 청산 시점에서 계산 (향후 개선)
        entryAccuracyPercent: 0,
        stopLossReached: false,
        stopLossFollowed: null,
      );
      
      await historyProvider.addFill(fill);
      
      // PHASE 2-1: 점수 업데이트 (체결 직후)
      if (scoreProvider != null) {
        final trades30d = historyProvider.fills.where((f) =>
          f.time.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).toList();
        
        final scoreDelta = await scoreProvider.onTradeFilled(
          fill: fill,
          trades30d: trades30d,
        ) - scoreProvider.currentScore;
        
        // GA4: trade_completed event
        AnalyticsService.logTradeCompleted(
          tradeType: 'sell',
          symbol: coin.symbol,
          amount: quantity, // 수량
        );
      }

      notifyListeners();
      
      print('[PortfolioProvider] Sell success: ${_portfolio.holdings.length} holdings');
      return true;
    } catch (e) {
      _lastError = e.toString();
      print('[PortfolioProvider] Sell failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
