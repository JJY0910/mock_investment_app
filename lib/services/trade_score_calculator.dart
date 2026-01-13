import 'score_engine_config.dart';

/// TradeScore 계산 서비스
class TradeScoreCalculator {
  /// 거래 1건의 점수 계산
  /// 
  /// 검증 보고서 반영:
  /// - TradeScore는 신뢰도 100% (ConfidenceFactor 적용 안 함)
  /// - 범위: -8 ~ +8
  /// - 손절 미입력은 중립(0점)
  double calculateTradeScore({
    double? rrRatio,
    required double entryAccuracyPercent,
    required bool stopLossReached,
    required bool stopLossFollowed,
  }) {
    double score = 0;
    
    // 1. RR 비율 (40%)
    if (rrRatio == null) {
      // 손절 미입력: 중립 (HabitScore에서 평가)
      score += 0;
    } else if (rrRatio >= 3.0) {
      score += 5 * 0.4;
    } else if (rrRatio >= 2.0) {
      score += 3 * 0.4;
    } else if (rrRatio >= 1.5) {
      score += 2 * 0.4;
    } else if (rrRatio >= 1.0) {
      score += 0;
    } else {
      score += -2 * 0.4;
    }
    
    // 2. 진입 정확도 (40%)
    if (entryAccuracyPercent < 2.0) {
      score += 3 * 0.4;
    } else if (entryAccuracyPercent < 5.0) {
      score += 2 * 0.4;
    } else if (entryAccuracyPercent < 10.0) {
      score += 0;
    } else if (entryAccuracyPercent < 15.0) {
      score += -2 * 0.4;
    } else {
      score += -4 * 0.4;
    }
    
    // 3. 손절 준수 (20%)
    if (stopLossReached && stopLossFollowed) {
      score += 2 * 0.2;
    } else if (stopLossReached && !stopLossFollowed) {
      score += -5 * 0.2;
    } else {
      score += 0; // 미도달/미설정: 중립
    }
    
    return score.clamp(
      ScoreEngineConfig.tradeScoreMin,
      ScoreEngineConfig.tradeScoreMax,
    );
  }
}
