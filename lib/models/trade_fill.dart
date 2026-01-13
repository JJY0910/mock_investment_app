/// 체결 내역 모델 (확장: 점수 계산용 필드 포함)
class TradeFill {
  final String id;
  final DateTime time;
  final String pairKey; // e.g., BTC_KRW
  final String base;    // e.g., BTC
  final String side;    // 'buy' or 'sell'
  final double priceKrw;   // 체결가
  final double quantity;   // 체결 수량
  final double amountKrw;  // 체결 금액
  final double feeKrw;     // 수수료 (KRW)
  final String source;     // 'market' or 'limit'
  final String? note;      // 비고
  
  // 점수 계산용 필드 (PHASE 2-1 추가)
  final double? stopLossPrice;    // 손절가
  final double? takeProfitPrice;  // 목표가
  final double? rrRatio;          // RR 비율 (계산된 값)
  final double? entryAccuracyPercent; // 진입 정확도 (역방향 변동 %)
  final bool? stopLossReached;    // 손절가 도달 여부
  final bool? stopLossFollowed;   // 손절 준수 여부
  final double? tradeScore;       // 이 거래의 점수
  final String? scoreReason;      // 점수 이유

  TradeFill({
    required this.id,
    required this.time,
    required this.pairKey,
    required this.base,
    required this.side,
    required this.priceKrw,
    required this.quantity,
    required this.amountKrw,
    this.feeKrw = 0,
    required this.source,
    this.note,
    // 점수 필드
    this.stopLossPrice,
    this.takeProfitPrice,
    this.rrRatio,
    this.entryAccuracyPercent,
    this.stopLossReached,
    this.stopLossFollowed,
    this.tradeScore,
    this.scoreReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'pairKey': pairKey,
      'base': base,
      'side': side,
      'priceKrw': priceKrw,
      'quantity': quantity,
      'amountKrw': amountKrw,
      'feeKrw': feeKrw,
      'source': source,
      'note': note,
      // 점수 필드
      'stopLossPrice': stopLossPrice,
      'takeProfitPrice': takeProfitPrice,
      'rrRatio': rrRatio,
      'entryAccuracyPercent': entryAccuracyPercent,
      'stopLossReached': stopLossReached,
      'stopLossFollowed': stopLossFollowed,
      'tradeScore': tradeScore,
      'scoreReason': scoreReason,
    };
  }

  factory TradeFill.fromJson(Map<String, dynamic> json) {
    return TradeFill(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      pairKey: json['pairKey'] as String,
      base: json['base'] as String,
      side: json['side'] as String,
      priceKrw: (json['priceKrw'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      amountKrw: (json['amountKrw'] as num).toDouble(),
      feeKrw: (json['feeKrw'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String,
      note: json['note'] as String?,
      // 점수 필드 (backward compatibility)
      stopLossPrice: (json['stopLossPrice'] as num?)?.toDouble(),
      takeProfitPrice: (json['takeProfitPrice'] as num?)?.toDouble(),
      rrRatio: (json['rrRatio'] as num?)?.toDouble(),
      entryAccuracyPercent: (json['entryAccuracyPercent'] as num?)?.toDouble(),
      stopLossReached: json['stopLossReached'] as bool?,
      stopLossFollowed: json['stopLossFollowed'] as bool?,
      tradeScore: (json['tradeScore'] as num?)?.toDouble(),
      scoreReason: json['scoreReason'] as String?,
    );
  }

  @override
  String toString() {
    return 'TradeFill($time, $side $base, price: $priceKrw, qty: $quantity, fee: $feeKrw, score: $tradeScore)';
  }
  
  /// TradeFill을 점수 필드와 함께 복사
  TradeFill copyWith({
    String? id,
    DateTime? time,
    String? pairKey,
    String? base,
    String? side,
    double? priceKrw,
    double? quantity,
    double? amountKrw,
    double? feeKrw,
    String? source,
    String? note,
    double? stopLossPrice,
    double? takeProfitPrice,
    double? rrRatio,
    double? entryAccuracyPercent,
    bool? stopLossReached,
    bool? stopLossFollowed,
    double? tradeScore,
    String? scoreReason,
  }) {
    return TradeFill(
      id: id ?? this.id,
      time: time ?? this.time,
      pairKey: pairKey ?? this.pairKey,
      base: base ?? this.base,
      side: side ?? this.side,
      priceKrw: priceKrw ?? this.priceKrw,
      quantity: quantity ?? this.quantity,
      amountKrw: amountKrw ?? this.amountKrw,
      feeKrw: feeKrw ?? this.feeKrw,
      source: source ?? this.source,
      note: note ?? this.note,
      stopLossPrice: stopLossPrice ?? this.stopLossPrice,
      takeProfitPrice: takeProfitPrice ?? this.takeProfitPrice,
      rrRatio: rrRatio ?? this.rrRatio,
      entryAccuracyPercent: entryAccuracyPercent ?? this.entryAccuracyPercent,
      stopLossReached: stopLossReached ?? this.stopLossReached,
      stopLossFollowed: stopLossFollowed ?? this.stopLossFollowed,
      tradeScore: tradeScore ?? this.tradeScore,
      scoreReason: scoreReason ?? this.scoreReason,
    );
  }
}
