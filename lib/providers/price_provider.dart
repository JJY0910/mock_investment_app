import 'dart:async';
import 'package:flutter/material.dart';
import '../services/price_service.dart';
import '../config/constants.dart';

// 시세 데이터 상태 관리 Provider
class PriceProvider with ChangeNotifier {
  final PriceService _priceService = PriceService();
  
  // 현재 시세 데이터 (심볼 -> 가격 정보)
  final Map<String, AssetPrice> _prices = {};
  
  // 로딩 상태
  bool _isLoading = false;
  
  // 에러 메시지
  String? _errorMessage;

  // Periodic update control
  StreamSubscription? _periodicSubscription;
  bool _isPeriodicUpdateActive = false;

  // Getters
  Map<String, AssetPrice> get prices => _prices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Balance getters (mock data for now)
  double get totalAssets => 10000.0;
  double get cash => 5000.0;
  double get estimatedValue {
    // Calculate total value of crypto holdings
    double total = 0.0;
    _prices.forEach((symbol, assetPrice) {
      // Mock: assume 0.1 BTC, 1 ETH, 1000 XRP
      if (symbol == 'BTCUSDT') total += 0.1 * assetPrice.price;
      if (symbol == 'ETHUSDT') total += 1.0 * assetPrice.price;
      if (symbol == 'XRPUSDT') total += 1000.0 * assetPrice.price;
    });
    return total;
  }

  // Get price for symbol
  double? getPrice(String symbol) {
    return _prices[symbol]?.price;
  }

  // Get 24h change for symbol
  double? get24hChange(String symbol) {
    return _prices[symbol]?.change;
  }

  // 특정 심볼의 가격 조회
  AssetPrice? getPriceBySymbol(String symbol) {
    return _prices[symbol];
  }

  // 여러 종목의 시세 업데이트
  Future<void> updatePrices(Map<String, String> symbolsWithTypes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPrices = await _priceService.fetchMultiplePrices(symbolsWithTypes);
      _prices.clear();
      _prices.addAll(newPrices);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '시세 업데이트 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 단일 종목 시세 업데이트
  Future<void> updateSinglePrice(String symbol, String assetType) async {
    try {
      final price = await _priceService.fetchPrice(symbol, assetType);
      if (price != null) {
        _prices[symbol] = price;
        notifyListeners();
      }
    } catch (e) {
      print('시세 업데이트 오류 ($symbol): $e');
    }
  }

  // 주기적 시세 업데이트 시작 (중복 방지)
  void startPeriodicUpdate(Map<String, String> symbolsWithTypes) {
    print('[PriceProvider] startPeriodicUpdate called, active=$_isPeriodicUpdateActive');
    
    // 이미 실행 중이면 중복 시작 방지
    if (_isPeriodicUpdateActive) {
      print('[PriceProvider] Periodic update already active, skipping');
      return;
    }

    _isPeriodicUpdateActive = true;
    
    // 즉시 한 번 업데이트
    print('[PriceProvider] Initial updatePrices');
    updatePrices(symbolsWithTypes);
    
    // 주기적으로 업데이트 (10초마다)
    _periodicSubscription = Stream.periodic(
      const Duration(seconds: AppConstants.priceUpdateIntervalSeconds),
    ).listen((_) {
      print('[PriceProvider] tick updatePrices');
      updatePrices(symbolsWithTypes);
    });
  }

  // 주기적 업데이트 중지
  void stopPeriodicUpdate() {
    print('[PriceProvider] stopPeriodicUpdate called');
    _periodicSubscription?.cancel();
    _periodicSubscription = null;
    _isPeriodicUpdateActive = false;
  }

  @override
  void dispose() {
    stopPeriodicUpdate();
    super.dispose();
  }
}
