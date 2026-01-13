import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trade_fill.dart';
import '../models/coach_feedback.dart';
import '../models/coach_badge.dart';
import '../services/trader_score_engine.dart';
import '../services/score_engine_config.dart';

/// 트레이더 점수 Provider
/// 
/// 체결 발생 시 자동으로 점수 계산 및 업데이트
class TraderScoreProvider extends ChangeNotifier {
  static const String _storageKey = 'trader_score_v1';
  static const String _historyKey = 'score_history_v1';
  static const int _maxHistoryCount = 100;
  
  final TraderScoreEngine _engine = TraderScoreEngine();
  
  double _currentScore = ScoreEngineConfig.initialScore;
  List<ScoreHistory> _history = [];
  DateTime? _lastHabitAppliedAt;
  bool _loading = false;
  
  // PHASE 2-3-2: 3블록 피드백 + 배지
  CoachFeedback? _lastFeedback;
  CoachBadge _currentBadge = CoachBadge.rookie;
  String _dailyCoachMessage = '';
  DateTime? _dailyCoachAt;
  String _weeklyCoachMessage = '';
  DateTime? _weeklyCoachAt;
  
  double get currentScore => _currentScore;
  String get currentStage => ScoreEngineConfig.getStage(_currentScore);
  List<ScoreHistory> get history => List.unmodifiable(_history);
  bool get loading => _loading;
  CoachFeedback? get lastFeedback => _lastFeedback;
  CoachBadge get currentBadge => _currentBadge;
  String get dailyCoachMessage => _dailyCoachMessage;
  DateTime? get dailyCoachAt => _dailyCoachAt;
  String get weeklyCoachMessage => _weeklyCoachMessage;
  DateTime? get weeklyCoachAt => _weeklyCoachAt;
  
  /// 로드
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 현재 점수
      _currentScore = prefs.getDouble(_storageKey) ?? ScoreEngineConfig.initialScore;
      
      // 이력
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(historyJson);
        _history = list.map((json) => ScoreHistory.fromJson(json)).toList();
      }
      
      // 마지막 habit 적용 시각
      final lastAppliedTimestamp = prefs.getInt('last_habit_applied');
      if (lastAppliedTimestamp != null) {
        _lastHabitAppliedAt = DateTime.fromMillisecondsSinceEpoch(lastAppliedTimestamp);
      }
      
      print('[TraderScoreProvider] Loaded: score=$_currentScore, stage=$currentStage');
    } catch (e) {
      print('[TraderScoreProvider] Error loading: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  /// 저장
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_storageKey, _currentScore);
      
      // 이력 저장
      final historyJson = jsonEncode(_history.map((h) => h.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
      
      // 마지막 habit 적용 시각
      if (_lastHabitAppliedAt != null) {
        await prefs.setInt('last_habit_applied', _lastHabitAppliedAt!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('[TraderScoreProvider] Error saving: $e');
    }
  }
  
  /// 체결 발생 시 점수 업데이트
  /// 
  /// PortfolioProvider에서 호출됨
  Future<double> onTradeFilled({
    required TradeFill fill,
    required List<TradeFill> trades30d,
  }) async {
    final scoreBefore = _currentScore;
    
    // TradeScore 계산
    final newScore = _engine.updateScoreOnTrade(
      currentScore: _currentScore,
      newTrade: fill,
      trades30d: trades30d,
    );
    
    final delta = newScore - scoreBefore;
    
    // 이력 추가
    _history.insert(0, ScoreHistory(
      timestamp: DateTime.now(),
      scoreBefore: scoreBefore,
      scoreAfter: newScore,
      delta: delta,
      tradeScore: fill.tradeScore ?? 0,
      habitScoreContribution: 0, // 거래 시에는 hab it 미반영
      confidenceFactor: ScoreEngineConfig.getConfidenceFactor(trades30d.length),
      capApplied: ScoreEngineConfig.getStageCap(scoreBefore),
      reason: 'Trade: ${fill.side} ${fill.base}',
      tradeId: fill.id,
    ));
    
    // 최대 개수 제한
    if (_history.length > _maxHistoryCount) {
      _history = _history.sublist(0, _maxHistoryCount);
    }
    
    _currentScore = newScore;
    
    // PHASE 2-3-2: 3블록 피드백 생성
    _lastFeedback = _generateFeedback(fill, delta, scoreBefore, trades30d);
    
    await _save();
    notifyListeners();
    
    print('[TraderScoreProvider] Score updated: $scoreBefore → $newScore (Δ${delta.toStringAsFixed(1)})');
    
    return newScore;
  }
  
  /// 3블록 피드백 생성 (룰 기반)
  CoachFeedback _generateFeedback(TradeFill fill, double delta, double scoreBefore, List<TradeFill> trades30d) {
    final tradeScore = fill.tradeScore ?? 0;
    final stage = ScoreEngineConfig.getStage(scoreBefore);
    final confidenceFactor = ScoreEngineConfig.getConfidenceFactor(trades30d.length);
    
    String title;
    List<String> bullets = [];
    String nextAction;
    String toneTag = stage;
    
    // Title 생성
    if (tradeScore > 5) {
      title = '✅ 훌륭한 거래입니다 (+${delta.toStringAsFixed(1)})';
    } else if (tradeScore > 2) {
      title = '👍 좋은 거래였습니다 (+${delta.toStringAsFixed(1)})';
    } else if (tradeScore > -2) {
      title = '➡️ 평범한 거래였습니다 (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)})';
    } else if (tradeScore > -5) {
      title = '⚠️ 개선이 필요합니다 (${delta.toStringAsFixed(1)})';
    } else {
      title = '🚨 주의가 필요합니다 (${delta.toStringAsFixed(1)})';
    }
    
    // Bullets 생성 (근거)
    if (fill.entryAccuracyPercent != null && fill.entryAccuracyPercent! > 0) {
      bullets.add('진입 역방향 ${fill.entryAccuracyPercent!.toStringAsFixed(1)}% (${fill.entryAccuracyPercent! < 3 ? '우수' : '보통'})');
    }
    
    if (fill.rrRatio != null && fill.rrRatio! > 0) {
      bullets.add('RR 비율 ${fill.rrRatio!.toStringAsFixed(1)} (${fill.rrRatio! > 2 ? '우수' : '보통'})');
    } else if (fill.stopLossPrice == null) {
      bullets.add('손절/목표 미설정: 이번 거래는 중립 처리');
    }
    
    if (fill.stopLossFollowed == false) {
      bullets.add('❌ 손절 계획 미준수로 감점');
    } else if (fill.stopLossFollowed == true) {
      bullets.add('✅ 손절 계획 준수');
    }
    
    if (confidenceFactor < 1.0) {
      bullets.add('거래 횟수 ${trades30d.length}회: ConfidenceFactor ${confidenceFactor.toStringAsFixed(2)} 적용');
    }
    
    final stageCap = ScoreEngineConfig.getStageCap(scoreBefore);
    if (stageCap < 10) {
      bullets.add('$stage 구간: 점수 변동 제한 (Cap ${stageCap.toStringAsFixed(1)})');
    }
    
    // NextAction 생성
    if (fill.stopLossPrice == null) {
      nextAction = '다음 거래는 손절가 1개만 먼저 입력하세요 (점수 상승 속도 ↑)';
    } else if (fill.rrRatio != null && fill.rrRatio! < 1.5) {
      nextAction = 'RR 비율 1.5 이상을 목표로 진입하세요 (보상↑ 위험↓)';
    } else if (fill.stopLossFollowed == false) {
      nextAction = '손절선을 반드시 지키세요. 이것이 점수 유지의 핵심입니다';
    } else {
      nextAction = '이대로 계속하세요. 계획을 세우고 실행하는 거래를 유지하세요';
    }
    
    return CoachFeedback(
      title: title,
      bullets: bullets.take(3).toList(),
      nextAction: nextAction,
      toneTag: toneTag,
      timestamp: DateTime.now(),
    );
  }
  
  /// 매일 자정 Habit Score 자동 조정
  /// 
  /// 앱 실행 시 체크하거나, 체결 시 날짜 변경 체크
  Future<void> applyDailyHabitAdjustmentIfNeeded({
    required List<TradeFill> trades30d,
    required List<TradeFill> trades7d,
    required double mdd30d,
    required double mdd7d,
  }) async {
    final now = DateTime.now();
    
    // 이미 오늘 적용했으면 스킵
    if (_lastHabitAppliedAt != null &&
        _lastHabitAppliedAt!.year == now.year &&
        _lastHabitAppliedAt!.month == now.month &&
        _lastHabitAppliedAt!.day == now.day) {
      return;
    }
    
    final scoreBefore = _currentScore;
    
    final newScore = _engine.applyDailyHabitAdjustment(
      currentScore: _currentScore,
      trades30d: trades30d,
      trades7d: trades7d,
      mdd30d: mdd30d,
      mdd7d: mdd7d,
    );
    
    final delta = newScore - scoreBefore;
    
    if (delta.abs() > 0.01) {
      // 이력 추가
      _history.insert(0, ScoreHistory(
        timestamp: now,
        scoreBefore: scoreBefore,
        scoreAfter: newScore,
        delta: delta,
        tradeScore: 0,
        habitScoreContribution: delta, // habit 조정
        confidenceFactor: ScoreEngineConfig.getConfidenceFactor(trades30d.length),
        capApplied: ScoreEngineConfig.getStageCap(scoreBefore),
        reason: 'Daily Habit Adjustment',
        tradeId: null,
      ));
      
      _currentScore = newScore;
      _lastHabitAppliedAt = now;
      
      // PHASE 2-3-2: 배지 재계산 및 Daily 메시지 생성
      _currentBadge = _calculateBadge(trades30d, trades7d);
      _dailyCoachMessage = _generateDailyMessage(delta, trades30d, trades7d);
      _dailyCoachAt = now;
      
      await _save();
      notifyListeners();
      
      print('[TraderScoreProvider] Daily Habit: $scoreBefore → $newScore (Δ${delta.toStringAsFixed(1)}), Badge: ${_currentBadge.displayName}');
    }
  }
  
  /// 배지 계산 (최근 30일 기준)
  CoachBadge _calculateBadge(List<TradeFill> trades30d, List<TradeFill> trades7d) {
    if (trades30d.isEmpty) return CoachBadge.rookie;
    
    // 손절 설정 비율
    final stopLossSetCount = trades30d.where((t) => t.stopLossPrice != null).length;
    final stopLossSetRatio = stopLossSetCount / trades30d.length;
    
    // 손절 준수 비율
    final stopLossFollowedCount = trades30d.where((t) => t.stopLossFollowed == true).length;
    final stopLossReachedCount = trades30d.where((t) => t.stopLossReached == true).length;
    final stopLossFollowRatio = stopLossReachedCount > 0 ? stopLossFollowedCount / stopLossReachedCount : 1.0;
    
    // 평균 RR 비율
    final rrRatios = trades30d.where((t) => t.rrRatio != null).map((t) => t.rrRatio!).toList();
    final avgRR = rrRatios.isNotEmpty ? rrRatios.reduce((a, b) => a + b) / rrRatios.length : 0.0;
    
    // 평균 진입 정확도
    final accuracies = trades30d.where((t) => t.entryAccuracyPercent != null && t.entryAccuracyPercent! > 0)
        .map((t) => t.entryAccuracyPercent!).toList();
    final avgAccuracy = accuracies.isNotEmpty ? accuracies.reduce((a, b) => a + b) / accuracies.length : 0.0;
    
    // 과매매 체크 (7일 평균)
    final avgTrades7d = trades7d.length / 7.0;
    
    // 배지 우선순위 결정
    if (stopLossSetRatio < 0.5) {
      return CoachBadge.stopLossBuilder;
    } else if (avgTrades7d > 10) {
      return CoachBadge.overtradeBreaker;
    } else if (avgAccuracy > 0 && avgAccuracy < 3.0) {
      return CoachBadge.entrySniper;
    } else if (avgRR > 2.0) {
      return CoachBadge.rrArchitect;
    } else if (stopLossFollowRatio > 0.8 && stopLossSetRatio > 0.7) {
      return CoachBadge.habitMaster;
    }
    
    return CoachBadge.rookie;
  }
  
  /// Daily 메시지 생성
  String _generateDailyMessage(double delta, List<TradeFill> trades30d, List<TradeFill> trades7d) {
    if (delta > 0) {
      return '📌 오늘의 습관 점수: +${delta.toStringAsFixed(1)} / 좋은 거래 습관이 점수 상승으로 이어지고 있습니다';
    } else if (delta < 0) {
      final badge = _currentBadge;
      return '📌 오늘의 습관: ${badge.description} / ${badge.displayName} 목표로 개선하세요';
    }
    return '📌 오늘의 습관: 거래 패턴을 유지하세요';
  }
  
  /// Weekly 메시지 생성 (추후 확장)
  void updateWeeklyMessage(List<TradeFill> trades7d) {
    if (trades7d.isEmpty) return;
    
    final delta7d = history.where((h) => 
      h.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).fold(0.0, (sum, h) => sum + h.delta);
    
    _weeklyCoachMessage = '📈 이번 주 점수 ${delta7d >= 0 ? '+' : ''}${delta7d.toStringAsFixed(1)} / '
        '거래 ${trades7d.length}회 / 다음 주: ${_currentBadge.displayName} 목표';
    _weeklyCoachAt = DateTime.now();
    notifyListeners();
  }
  
  /// 점수 리셋 (테스트용)
  Future<void> resetScore() async {
    _currentScore = ScoreEngineConfig.initialScore;
    _history.clear();
    _lastHabitAppliedAt = null;
    await _save();
    notifyListeners();
    print('[TraderScoreProvider] Score reset to ${ScoreEngineConfig.initialScore}');
  }
}

/// 점수 이력 모델
class ScoreHistory {
  final DateTime timestamp;
  final double scoreBefore;
  final double scoreAfter;
  final double delta;
  final double tradeScore;
  final double habitScoreContribution;
  final double confidenceFactor;
  final double capApplied;
  final String reason;
  final String? tradeId;
  
  ScoreHistory({
    required this.timestamp,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.delta,
    required this.tradeScore,
    required this.habitScoreContribution,
    required this.confidenceFactor,
    required this.capApplied,
    required this.reason,
    this.tradeId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'delta': delta,
      'tradeScore': tradeScore,
      'habitScoreContribution': habitScoreContribution,
      'confidenceFactor': confidenceFactor,
      'capApplied': capApplied,
      'reason': reason,
      'tradeId': tradeId,
    };
  }
  
  factory ScoreHistory.fromJson(Map<String, dynamic> json) {
    return ScoreHistory(
      timestamp: DateTime.parse(json['timestamp']),
      scoreBefore: (json['scoreBefore'] as num).toDouble(),
      scoreAfter: (json['scoreAfter'] as num).toDouble(),
      delta: (json['delta'] as num).toDouble(),
      tradeScore: (json['tradeScore'] as num?)?.toDouble() ?? 0,
      habitScoreContribution: (json['habitScoreContribution'] as num?)?.toDouble() ?? 0,
      confidenceFactor: (json['confidenceFactor'] as num?)?.toDouble() ?? 1.0,
      capApplied: (json['capApplied'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String,
      tradeId: json['tradeId'] as String?,
    );
  }
}
