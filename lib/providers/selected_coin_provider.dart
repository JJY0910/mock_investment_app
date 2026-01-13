import 'package:flutter/material.dart';
import '../models/coin_info.dart';
import '../data/coin_registry.dart';

/// 선택된 코인 Provider
/// TradeScreen에서 선택된 코인을 전역적으로 관리
class SelectedCoinProvider extends ChangeNotifier {
  final CoinRegistry _registry = CoinRegistry();
  
  CoinInfo? _selectedCoin;

  /// 현재 선택된 코인
  CoinInfo? get selectedCoin => _selectedCoin;

  /// 초기화 (기본 BTC 선택)
  void initialize() {
    if (_selectedCoin == null) {
      final btc = _registry.getKrwMarket().firstWhere(
        (coin) => coin.base == 'BTC',
        orElse: () => _registry.getKrwMarket().first,
      );
      _selectedCoin = btc;
      notifyListeners();
    }
  }

  /// 코인 선택 (base symbol 기준)
  void selectByBase(String base) {
    try {
      final coin = _registry.getKrwMarket().firstWhere(
        (coin) => coin.base == base,
      );
      _selectedCoin = coin;
      notifyListeners();
      print('[SelectedCoinProvider] Selected: ${coin.displayName} (${coin.base})');
    } catch (e) {
      print('[SelectedCoinProvider] Error selecting coin: $e');
    }
  }

  /// 코인 선택 (pairKey 기준)
  void selectByPairKey(String pairKey) {
    try {
      final coin = _registry.getKrwMarket().firstWhere(
        (coin) => coin.pairKey == pairKey,
      );
      _selectedCoin = coin;
      notifyListeners();
      print('[SelectedCoinProvider] Selected: ${coin.displayName} (${coin.pairKey})');
    } catch (e) {
      print('[SelectedCoinProvider] Error selecting coin: $e');
    }
  }

  /// USDT 심볼 기준 선택 (BTCUSDT → BTC)
  void selectByUsdtSymbol(String usdtSymbol) {
    if (usdtSymbol.endsWith('USDT')) {
      final base = usdtSymbol.substring(0, usdtSymbol.length - 4);
      selectByBase(base);
    }
  }
}
