import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trade_fill.dart';

/// 체결 내역 Provider
/// 최근 500개 유지, shared_preferences 저장
class TradeHistoryProvider extends ChangeNotifier {
  static const String _storageKey = 'trade_history_v1';
  static const int _maxHistoryCount = 500;

  List<TradeFill> _fills = [];
  bool _loading = false;

  /// 체결 내역 (최신순)
  List<TradeFill> get fills => List.unmodifiable(_fills);

  bool get loading => _loading;

  /// 로드
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        // 내림차순 정렬 (최신순) 확인
        _fills = jsonList
            .map((json) => TradeFill.fromJson(json))
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));
        
        print('[TradeHistoryProvider] Loaded ${_fills.length} fills');
      }
    } catch (e) {
      print('[TradeHistoryProvider] Error loading history: $e');
      _fills = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 저장
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _fills.map((f) => f.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('[TradeHistoryProvider] Error saving history: $e');
    }
  }

  /// 체결 내역 추가
  Future<void> addFill(TradeFill fill) async {
    // 최신순 유지를 위해 맨 앞에 추가
    _fills.insert(0, fill);
    
    // 최대 개수 제한
    if (_fills.length > _maxHistoryCount) {
      _fills = _fills.sublist(0, _maxHistoryCount);
      print('[TradeHistoryProvider] Trimmed history to $_maxHistoryCount');
    }

    await save();
    notifyListeners();
    print('[TradeHistoryProvider] Added fill: $fill');
  }

  /// 내역 전체 삭제
  Future<void> clearHistory() async {
    _fills.clear();
    await save();
    notifyListeners();
    print('[TradeHistoryProvider] History cleared');
  }
}
