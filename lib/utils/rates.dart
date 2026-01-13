/// 환율 상수 및 환산 유틸리티
class ExchangeRates {
  /// 고정 환율: 1 USDT = 1350 KRW (임시)
  /// 실제 환율 API 연동은 추후 단계에서 진행
  static const double USDT_TO_KRW = 1350.0;

  /// USDT를 KRW로 환산
  static double usdtToKrw(double usdt) {
    return usdt * USDT_TO_KRW;
  }

  /// KRW를 USDT로 환산
  static double krwToUsdt(double krw) {
    return krw / USDT_TO_KRW;
  }
}
