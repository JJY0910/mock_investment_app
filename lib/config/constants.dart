// 앱 전역 상수 정의
class AppConstants {
  // 초기 자산
  static const double initialBalance = 100000000.0; // 1억 원
  
  // 광고 리셋 임계값
  static const double adResetThreshold = 100000000.0; // 1억 원 미만
  
  // 시세 업데이트 주기 (초)
  static const int priceUpdateIntervalSeconds = 10;
  
  // API 관련
  static const String yahooFinanceBaseUrl = 'https://query1.finance.yahoo.com';
  static const String upbitBaseUrl = 'https://api.upbit.com';
  
  // 자산 유형
  static const String assetTypeStock = 'STOCK';
  static const String assetTypeCrypto = 'CRYPTO';
  
  // 거래 유형
  static const String transactionTypeBuy = 'BUY';
  static const String transactionTypeSell = 'SELL';
  
  // 통화 포맷
  static const String currencySymbol = '₩';
  
  // 페이지 라우트
  static const String homeRoute = '/';
  static const String tradingRoute = '/trading';
  static const String leaderboardRoute = '/leaderboard';
}
