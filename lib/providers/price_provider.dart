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

  // Getters
  Map<String, AssetPrice> get prices => _prices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // 주기적 시세 업데이트 시작
  void startPeriodicUpdate(Map<String, String> symbolsWithTypes) {
    // 즉시 한 번 업데이트
    updatePrices(symbolsWithTypes);
    
    // 주기적으로 업데이트 (10초마다)
    Stream.periodic(
      const Duration(seconds: AppConstants.priceUpdateIntervalSeconds),
    ).listen((_) {
      updatePrices(symbolsWithTypes);
    });
  }
}
