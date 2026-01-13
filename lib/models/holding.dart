/// 보유 자산 (코인)
class Holding {
  final String pairKey; // BTC_KRW
  final String base; // BTC
  final String quote; // KRW
  final double quantity; // 보유 수량
  final double avgPriceKrw; // 평균 매입가 (KRW)
  final DateTime updatedAt;

  Holding({
    required this.pairKey,
    required this.base,
    required this.quote,
    required this.quantity,
    required this.avgPriceKrw,
    required this.updatedAt,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'pairKey': pairKey,
      'base': base,
      'quote': quote,
      'quantity': quantity,
      'avgPriceKrw': avgPriceKrw,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON에서 생성
  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      pairKey: json['pairKey'] as String,
      base: json['base'] as String,
      quote: json['quote'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      avgPriceKrw: (json['avgPriceKrw'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 평가금액 계산 (현재가 필요)
  double evaluateKrw(double currentPriceKrw) {
    return quantity * currentPriceKrw;
  }

  /// 평가손익 계산
  double calculatePnlKrw(double currentPriceKrw) {
    return evaluateKrw(currentPriceKrw) - (quantity * avgPriceKrw);
  }

  /// 수익률 계산 (%)
  double calculatePnlPercent(double currentPriceKrw) {
    if (avgPriceKrw == 0) return 0;
    return ((currentPriceKrw - avgPriceKrw) / avgPriceKrw) * 100;
  }

  @override
  String toString() {
    return 'Holding($pairKey, qty: $quantity, avg: ₩$avgPriceKrw)';
  }
}
