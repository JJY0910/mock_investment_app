/// 시장 시세 정보
class MarketQuote {
  final String symbol; // BTCUSDT
  final double lastPrice; // 마지막 거래 가격 (USDT)
  final double priceChangePercent; // 24시간 등락률 (%)
  final DateTime timestamp;

  MarketQuote({
    required this.symbol,
    required this.lastPrice,
    required this.priceChangePercent,
    required this.timestamp,
  });

  /// JSON에서 MarketQuote 생성 (Binance ticker/24hr 응답 파싱)
  factory MarketQuote.fromBinanceJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: json['symbol'] as String,
      lastPrice: double.tryParse(json['lastPrice']?.toString() ?? '0') ?? 0,
      priceChangePercent: double.tryParse(json['priceChangePercent']?.toString() ?? '0') ?? 0,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MarketQuote(symbol: $symbol, lastPrice: $lastPrice, change: $priceChangePercent%)';
  }
}
