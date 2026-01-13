import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/coin_info.dart';

/// 거래 엔진 (체결 로직)
/// UI와 분리하여 순수 비즈니스 로직만 처리
class TradeEngine {
  /// 시장가 매수
  /// krwAmount: 매수할 금액 (KRW)
  /// priceKrw: 현재가 (KRW)
  /// fee: 수수료 (KRW)
  /// 반환: 업데이트된 Portfolio 또는 예외
  static Portfolio marketBuy({
    required CoinInfo coin,
    required double krwAmount,
    required double priceKrw,
    required Portfolio portfolio,
    double fee = 0,
  }) {
    // 입력 검증
    if (krwAmount <= 0) {
      throw Exception('매수 금액은 0보다 커야 합니다');
    }

    if (priceKrw <= 0) {
      throw Exception('가격 정보가 올바르지 않습니다');
    }

    final totalCost = krwAmount + fee;
    if (portfolio.cashKrw < totalCost) {
      throw Exception('현금이 부족합니다 (필요: ₩${totalCost.toStringAsFixed(0)}, 보유: ₩${portfolio.cashKrw.toStringAsFixed(0)})');
    }

    // 매수 수량 계산 (수수료 제외한 순수 매수 금액 기준)
    final buyQty = krwAmount / priceKrw;

    // 현금 차감 (금액 + 수수료)
    final newCash = portfolio.cashKrw - totalCost;

    // 보유 업데이트
    final List<Holding> newHoldings = List.from(portfolio.holdings);
    final existingIndex = newHoldings.indexWhere((h) => h.pairKey == coin.pairKey);

    if (existingIndex >= 0) {
      // 기존 보유가 있으면 평단 계산
      final existing = newHoldings[existingIndex];
      final oldQty = existing.quantity;
      final oldAvg = existing.avgPriceKrw;

      // 평단가 계산 시 수수료 포함 여부? 
      // 통상적으로 매수 평단가는 (총비용 / 총수량)으로 계산하기도 하지만, 
      // 여기서는 심플하게 (순수 매수금액 / 수량) 유지. 
      // 수수료를 평단에 녹이면 복잡해지므로 일단 순수 가격 기준 유지.
      final newQty = oldQty + buyQty;
      final newAvg = (oldQty * oldAvg + buyQty * priceKrw) / newQty;

      newHoldings[existingIndex] = Holding(
        pairKey: coin.pairKey,
        base: coin.base,
        quote: 'KRW',
        quantity: newQty,
        avgPriceKrw: newAvg,
        updatedAt: DateTime.now(),
      );
    } else {
      // 신규 보유
      newHoldings.add(Holding(
        pairKey: coin.pairKey,
        base: coin.base,
        quote: 'KRW',
        quantity: buyQty,
        avgPriceKrw: priceKrw,
        updatedAt: DateTime.now(),
      ));
    }

    return Portfolio(
      cashKrw: newCash,
      holdings: newHoldings,
    );
  }

  /// 시장가 매도
  /// quantity: 매도할 수량
  /// priceKrw: 현재가 (KRW)
  /// fee: 수수료 (KRW)
  /// 반환: 업데이트된 Portfolio 또는 예외
  static Portfolio marketSell({
    required CoinInfo coin,
    required double quantity,
    required double priceKrw,
    required Portfolio portfolio,
    double fee = 0,
  }) {
    // 입력 검증
    if (quantity <= 0) {
      throw Exception('매도 수량은 0보다 커야 합니다');
    }

    if (priceKrw <= 0) {
      throw Exception('가격 정보가 올바르지 않습니다');
    }

    // 보유 확인
    final holding = portfolio.getHolding(coin.pairKey);
    if (holding == null) {
      throw Exception('보유하지 않은 코인입니다');
    }

    if (holding.quantity < quantity) {
      throw Exception('보유 수량이 부족합니다 (보유: ${holding.quantity.toStringAsFixed(6)})');
    }

    // 매도 금액 계산
    final sellAmount = quantity * priceKrw;
    
    // 현금 증가 (매도 금액 - 수수료)
    // 수수료가 매도 금액보다 크면 0원 처리 (방어 코드)
    final actualReceive = (sellAmount - fee) > 0 ? (sellAmount - fee) : 0.0;
    
    final newCash = portfolio.cashKrw + actualReceive;

    // 보유 업데이트
    final List<Holding> newHoldings = List.from(portfolio.holdings);
    final existingIndex = newHoldings.indexWhere((h) => h.pairKey == coin.pairKey);

    if (quantity >= holding.quantity) {
      // 전량 매도: holding 제거
      newHoldings.removeAt(existingIndex);
    } else {
      // 일부 매도: 수량만 감소, 평단 유지
      newHoldings[existingIndex] = Holding(
        pairKey: holding.pairKey,
        base: holding.base,
        quote: holding.quote,
        quantity: holding.quantity - quantity,
        avgPriceKrw: holding.avgPriceKrw,
        updatedAt: DateTime.now(),
      );
    }

    return Portfolio(
      cashKrw: newCash,
      holdings: newHoldings,
    );
  }
}
