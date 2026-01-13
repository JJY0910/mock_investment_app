/// 지정가 주문
class LimitOrder {
  final String id;
  final String side; // 'buy' or 'sell'
  final String pairKey; // BTC_KRW
  final String base; // BTC
  final double priceKrw; // 지정가 (KRW)
  final double quantity; // 수량 (매도) 또는 금액(KRW, 매수)
  final bool isBuyOrder; // true: 금액 기준, false: 수량 기준
  final DateTime createdAt;
  String status; // 'open', 'filled', 'canceled'

  LimitOrder({
    required this.id,
    required this.side,
    required this.pairKey,
    required this.base,
    required this.priceKrw,
    required this.quantity,
    required this.isBuyOrder,
    required this.createdAt,
    this.status = 'open',
  });

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'side': side,
      'pairKey': pairKey,
      'base': base,
      'priceKrw': priceKrw,
      'quantity': quantity,
      'isBuyOrder': isBuyOrder,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// JSON에서 생성
  factory LimitOrder.fromJson(Map<String, dynamic> json) {
    return LimitOrder(
      id: json['id'] as String,
      side: json['side'] as String,
      pairKey: json['pairKey'] as String,
      base: json['base'] as String,
      priceKrw: (json['priceKrw'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      isBuyOrder: json['isBuyOrder'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'open',
    );
  }

  @override
  String toString() {
    return 'LimitOrder($side $base @ ₩$priceKrw, qty: $quantity, status: $status)';
  }
}
