import '../models/coin_info.dart';

/// 코인 데이터 포맷 유틸리티
/// UI 표시 일관성을 위한 포맷 규칙 제공
class CoinFormatters {
  /// 가격 포맷 (소수점 자리수 기준)
  /// 예: formatPrice(12345.6789, decimals: 2) → "12,345.68"
  static String formatPrice(num? value, {required int decimals}) {
    if (value == null) return '0.00';
    
    final rounded = value.toStringAsFixed(decimals);
    final parts = rounded.split('.');
    final intPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Add thousand separators
    final intWithCommas = _addThousandSeparators(intPart);
    
    return decimals > 0 ? '$intWithCommas.$decimalPart' : intWithCommas;
  }

  /// 등락률 포맷
  /// 예: formatPercent(2.35) → "+2.35%"
  static String formatPercent(num? value) {
    if (value == null) return '0.00%';
    
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// 심볼 포맷 (표시용)
  /// 예: formatSymbol(CoinInfo) → "BTC/USDT" 또는 "BTC"
  static String formatSymbol(CoinInfo coin, {bool showQuote = false}) {
    if (showQuote) {
      return '${coin.base}/${coin.quote}';
    }
    return coin.base;
  }

  /// CoinInfo 기반 가격 포맷 (priceDecimals 사용)
  static String formatCoinPrice(CoinInfo coin) {
    return formatPrice(coin.currentPrice, decimals: coin.priceDecimals);
  }

  /// KRW 전용 포맷
  /// 예: formatKrw(1234567) → "₩1,234,567"
  static String formatKrw(num? value) {
    if (value == null) return '₩0';
    // 반올림하여 정수로 변환
    final rounded = value.round();
    final withCommas = _addThousandSeparators(rounded.toString());
    return '₩$withCommas';
  }

  /// 수량 포맷
  /// 예: formatQuantity(0.005, decimals: 6) → "0.005000"
  static String formatQuantity(num? value, {int decimals = 6}) {
    if (value == null) return '0.000000';
    return value.toStringAsFixed(decimals);
  }

  /// 천 단위 구분자 추가
  static String _addThousandSeparators(String number) {
    final isNegative = number.startsWith('-');
    final cleaned = isNegative ? number.substring(1) : number;
    
    if (cleaned.length <= 3) return number;
    
    final reversed = cleaned.split('').reversed.join('');
    final withCommas = <String>[];
    
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withCommas.add(',');
      }
      withCommas.add(reversed[i]);
    }
    
    final result = withCommas.reversed.join('');
    return isNegative ? '-$result' : result;
  }
}
