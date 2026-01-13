/// 코인 정보 모델
/// base: 기초 자산 (예: BTC)
/// quote: 견적 자산 (예: USDT, KRW)
class CoinInfo {
  final String base;
  final String quote;
  final String displayName;
  final double? currentPrice;
  final double? change24h;
  final int priceDecimals; // 가격 표시 소수점 자리수

  CoinInfo({
    required this.base,
    required this.quote,
    required this.displayName,
    this.currentPrice,
    this.change24h,
    this.priceDecimals = 2, // 기본값 2자리
  });

  /// Pair key for unique identification (e.g., "BTCUSDT")
  String get pairKey => '$base$quote';

  /// Symbol for API requests (e.g., "BTCUSDT")
  String get symbol => pairKey;

  /// Copy with updated price/change
  CoinInfo copyWith({
    double? currentPrice,
    double? change24h,
  }) {
    return CoinInfo(
      base: base,
      quote: quote,
      displayName: displayName,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoinInfo && other.pairKey == pairKey;
  }

  @override
  int get hashCode => pairKey.hashCode;
}
