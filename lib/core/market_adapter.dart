import '../models/coin_info.dart';

/// 마켓 어댑터 - 내부 도메인은 KRW만, 외부 소스는 자유
class MarketAdapter {
  /// 외부 심볼(BTCUSDT) → 내부 마켓(BTC/KRW)
  static String toKrwMarket(String externalSymbol) {
    if (externalSymbol.endsWith('USDT')) {
      return '${externalSymbol.substring(0, externalSymbol.length - 4)}/KRW';
    }
    return externalSymbol;
  }

  /// 내부 마켓(BTC/KRW) → 외부 심볼(BTCUSDT) - 외부 API 호출 시만 사용
  static String toExternalSymbol(String krwMarket) {
    if (krwMarket.contains('/KRW')) {
      final base = krwMarket.split('/')[0];
      return '$base${String.fromCharCodes([85, 83, 68, 84])}'; // USDT
    }
    return krwMarket;
  }

  /// CoinInfo에서 KRW 마켓 추출
  static String getCoinMarket(CoinInfo coin) {
    return '${coin.base}/KRW';
  }
}
