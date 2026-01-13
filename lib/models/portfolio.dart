import 'holding.dart';

/// 포트폴리오 (모의지갑)
class Portfolio {
  final double cashKrw; // 보유 현금 (KRW)
  final List<Holding> holdings; // 보유 코인 목록

  Portfolio({
    required this.cashKrw,
    required this.holdings,
  });

  /// 기본값 (초기 자산)
  static Portfolio defaultPortfolio() {
    return Portfolio(
      cashKrw: 1000000.0, // 초기 현금: 100만원
      holdings: [],
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'cashKrw': cashKrw,
      'holdings': holdings.map((h) => h.toJson()).toList(),
    };
  }

  /// JSON에서 생성
  factory Portfolio.fromJson(Map<String, dynamic> json) {
    try {
      return Portfolio(
        cashKrw: (json['cashKrw'] as num?)?.toDouble() ?? 1000000.0,
        holdings: (json['holdings'] as List<dynamic>?)
                ?.map((h) => Holding.fromJson(h as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      print('[Portfolio] Error parsing JSON: $e');
      // 파싱 실패 시 기본값 반환 (크래시 방지)
      return Portfolio.defaultPortfolio();
    }
  }

  /// 특정 코인 보유 여부
  bool hasHolding(String pairKey) {
    return holdings.any((h) => h.pairKey == pairKey);
  }

  /// 특정 코인 보유량 조회
  Holding? getHolding(String pairKey) {
    try {
      return holdings.firstWhere((h) => h.pairKey == pairKey);
    } catch (e) {
      return null;
    }
  }

  /// 보유 코인 총 평가금액 계산 (현재가 맵 필요)
  /// priceMap: {pairKey: currentPriceKrw}
  double getTotalHoldingsValueKrw(Map<String, double> priceMap) {
    double total = 0;
    for (var holding in holdings) {
      final currentPrice = priceMap[holding.pairKey] ?? holding.avgPriceKrw;
      total += holding.evaluateKrw(currentPrice);
    }
    return total;
  }

  /// 총자산 (현금 + 보유평가)
  double getTotalValueKrw(Map<String, double> priceMap) {
    return cashKrw + getTotalHoldingsValueKrw(priceMap);
  }

  /// 총 평가손익 (KRW)
  double getTotalPnlKrw(Map<String, double> priceMap) {
    double pnl = 0;
    for (var holding in holdings) {
      final currentPrice = priceMap[holding.pairKey] ?? holding.avgPriceKrw;
      pnl += holding.calculatePnlKrw(currentPrice);
    }
    return pnl;
  }

  /// 총 수익률 (%)
  /// (총자산 - 초기자산) / 초기자산 * 100
  double getTotalPnlPercent(Map<String, double> priceMap) {
    const initialCash = 1000000.0; // 초기 현금
    final totalValue = getTotalValueKrw(priceMap);
    
    if (initialCash == 0) return 0;
    return ((totalValue - initialCash) / initialCash) * 100;
  }

  @override
  String toString() {
    return 'Portfolio(cash: ₩$cashKrw, holdings: ${holdings.length})';
  }
}
