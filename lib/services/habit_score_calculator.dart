import '../models/trade_fill.dart';
import 'score_engine_config.dart';

/// HabitScore 계산 서비스
class HabitScoreCalculator {
  /// 최근 30일 습관 점수 계산
  /// 
  /// 검증 보고서 반영:
  /// - 최근 7일 가중치 70%, 30일 가중치 30%
  /// - 회복 가능성 제공
  double calculate30DayHabitScore({
    required List<TradeFill> trades30d,
    required List<TradeFill> trades7d,
    required double mdd30d,
    required double mdd7d,
  }) {
    final habit30d = _calculateHabitScore(
      trades: trades30d,
      mdd: mdd30d,
      days: 30,
    );
    
    final habit7d = _calculateHabitScore(
      trades: trades7d,
      mdd: mdd7d,
      days: 7,
    );
    
    // 최근 7일에 더 높은 가중치
    final weighted = habit7d * ScoreEngineConfig.habit7dWeight +
        habit30d * ScoreEngineConfig.habit30dWeight;
    
    return weighted.clamp(
      ScoreEngineConfig.habitScoreMin,
      ScoreEngineConfig.habitScoreMax,
    );
  }
  
  double _calculateHabitScore({
    required List<TradeFill> trades,
    required double mdd,
    required int days,
  }) {
    if (trades.isEmpty) return 0;
    
    double score = 0;
    
    // 1. 손절가 설정 비율 (±15)
    final stopLossSetRatio = _calculateStopLossSetRatio(trades);
    if (stopLossSetRatio >= 0.90) {
      score += 15;
    } else if (stopLossSetRatio >= 0.70) {
      score += 5;
    } else if (stopLossSetRatio >= 0.50) {
      score += -5;
    } else {
      score += -15;
    }
    
    // 2. 손절 준수율 (±15)
    final stopLossComplianceRatio = _calculateStopLossCompliance(trades);
    if (stopLossComplianceRatio >= 0.95) {
      score += 15;
    } else if (stopLossComplianceRatio >= 0.80) {
      score += 5;
    } else if (stopLossComplianceRatio >= 0.60) {
      score += -5;
    } else {
      score += -15;
    }
    
    // 3. 과매매 방지 (±10)
    final avgDailyTrades = trades.length / days;
    if (avgDailyTrades >= 1 && avgDailyTrades <= 3) {
      score += 10;
    } else if (avgDailyTrades >= 4 && avgDailyTrades <= 7) {
      score += 0;
    } else if (avgDailyTrades >= 8 && avgDailyTrades <= 15) {
      score += -10;
    } else {
      score += -15;
    }
    
    // 4. 휴식일 패턴 (+5)
    // TODO: 거래 날짜 기준 휴식일 계산
    // 현재는 생략
    
    // 5. 동일 실수 반복 (-10)
    // TODO: 실수 패턴 감지
    // 현재는 생략
    
    // 6. MDD 관리 (±10)
    if (mdd < 5.0) {
      score += 10;
    } else if (mdd < 10.0) {
      score += 5;
    } else if (mdd < 15.0) {
      score += 0;
    } else if (mdd < 20.0) {
      score += -5;
    } else {
      score += -10;
    }
    
    return score;
  }
  
  double _calculateStopLossSetRatio(List<TradeFill> trades) {
    if (trades.isEmpty) return 0;
    // TODO: TradeFill에 stopLossPrice 필드 추가 필요
    // 현재는 임시값
    return 0.8;
  }
  
  double _calculateStopLossCompliance(List<TradeFill> trades) {
    if (trades.isEmpty) return 0;
    // TODO: 손절 준수 여부 추적 필요
    // 현재는 임시값
    return 0.9;
  }
}
