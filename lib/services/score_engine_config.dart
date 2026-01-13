/// 점수 엔진 설정 상수
class ScoreEngineConfig {
  // 시작 점수 (나중에 A/B 테스트 가능하도록 분리)
  static const double initialScore = 500.0;
  
  // TradeScore 범위
  static const double tradeScoreMin = -8.0;
  static const double tradeScoreMax = 8.0;
  
  //HabitScore 범위
  static const double habitScoreMin = -40.0;
  static const double habitScoreMax = 40.0;
  
  // ConfidenceFactor 테이블
  static double getConfidenceFactor(int trades30dCount) {
    if (trades30dCount < 5) return 0.20;
    if (trades30dCount < 10) return 0.30;
    if (trades30dCount < 20) return 0.50;
    if (trades30dCount < 30) return 0.70;
    if (trades30dCount < 50) return 0.85;
    return 1.00;
  }
  
  // StageCap (검증 보고서 반영)
  static double getStageCap(double currentScore) {
    if (currentScore < 300) return 12.0; // Rookie
    if (currentScore < 500) return 10.0; // Trader
    if (currentScore < 650) return 7.0; // Advanced
    if (currentScore < 800) return 5.0; // Pro
    if (currentScore < 900) return 3.0; // Master
    return 2.0; // Elite
  }
  
  // Stage 이름
  static String getStage(double score) {
    if (score >= 900) return 'Elite';
    if (score >= 800) return 'Master';
    if (score >= 650) return 'Pro';
    if (score >= 500) return 'Advanced';
    if (score >= 300) return 'Trader';
    return 'Rookie';
  }
  
  // HabitScore 회복: 최근 7일 가중치 (검증 보고서 반영)
  static const double habit7dWeight = 0.7;
  static const double habit30dWeight = 0.3;
}
