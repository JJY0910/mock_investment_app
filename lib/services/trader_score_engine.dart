import '../models/trade_fill.dart';
import 'score_engine_config.dart';
import 'trade_score_calculator.dart';
import 'habit_score_calculator.dart';

/// 통합 점수 엔진
/// 
/// 검증 보고서 반영:
/// 1. HabitScore는 매일 자정 자동 조정 (거래마다 X)
/// 2. ConfidenceFactor는 HabitScore에만 적용 (TradeScore는 100%)
/// 3. StageCap 튜닝 (Rookie ±12, Pro ±5 등)
class TraderScoreEngine {
  final TradeScoreCalculator _tradeCalc = TradeScoreCalculator();
  final HabitScoreCalculator _habitCalc = HabitScoreCalculator();
  
  DateTime? _lastHabitAppliedAt;
  
  /// 거래 발생 시 점수 업데이트
  /// 
  /// TradeScore만 즉시 반영
  double updateScoreOnTrade({
    required double currentScore,
    required TradeFill newTrade,
    required List<TradeFill> trades30d,
  }) {
    // TradeScore 계산 (신뢰도 100%)
    final tradeScore = _tradeCalc.calculateTradeScore(
      rrRatio: newTrade.rrRatio,
      entryAccuracyPercent: newTrade.entryAccuracyPercent ?? 0,
      stopLossReached: newTrade.stopLossReached ?? false,
      stopLossFollowed: newTrade.stopLossFollowed ?? false,
    );
    
    // StageCap 적용
    final cap = ScoreEngineConfig.getStageCap(currentScore);
    final cappedChange = tradeScore.clamp(-cap, cap);
    
    final newScore = (currentScore + cappedChange).clamp(0.0, 1000.0);
    
    return newScore;
  }
  
  /// 매일 자정 HabitScore 자동 조정
  /// 
  /// 검증 보고서 권장안:
  /// - 거래마다 0.1 곱해서 반영 X
  /// - 매일 자정 1회 조정
  double applyDailyHabitAdjustment({
    required double currentScore,
    required List<TradeFill> trades30d,
    required List<TradeFill> trades7d,
    required double mdd30d,
    required double mdd7d,
  }) {
    // 이미 오늘 적용했으면 스킵
    final now = DateTime.now();
    if (_lastHabitAppliedAt != null &&
        _lastHabitAppliedAt!.year == now.year &&
        _lastHabitAppliedAt!.month == now.month &&
        _lastHabitAppliedAt!.day == now.day) {
      return currentScore;
    }
    
    // HabitScore 계산 (최근 7일 가중치 70%, 30일 30%)
    final habitScore = _habitCalc.calculate30DayHabitScore(
      trades30d: trades30d,
      trades7d: trades7d,
      mdd30d: mdd30d,
      mdd7d: mdd7d,
    );
    
    // 30일에 걸쳐 분산 (하루치)
    final dailyAdjustment = habitScore / 30.0;
    
    // ConfidenceFactor 적용 (HabitScore에만)
    final confidenceFactor = ScoreEngineConfig.getConfidenceFactor(trades30d.length);
    final adjustedDaily = dailyAdjustment * confidenceFactor;
    
    // StageCap 적용
    final cap = ScoreEngineConfig.getStageCap(currentScore);
    final cappedChange = adjustedDaily.clamp(-cap, cap);
    
    final newScore = (currentScore + cappedChange).clamp(0.0, 1000.0);
    
    _lastHabitAppliedAt = now;
    return newScore;
  }
  
  /// 점수 설명 생성
  Map<String, dynamic> explainScoreChange({
    required double scoreBefore,
    required double scoreAfter,
    required double tradeScore,
    required double habitScore,
    required double confidenceFactor,
    required bool capApplied,
  }) {
    final delta = scoreAfter - scoreBefore;
    
    return {
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'delta': delta,
      'tradeScore': tradeScore,
      'habitScore': habitScore,
      'confidenceFactor': confidenceFactor,
      'capApplied': capApplied,
      'stage': ScoreEngineConfig.getStage(scoreAfter),
    };
  }
}
