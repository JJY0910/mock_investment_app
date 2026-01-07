import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../services/auth_service.dart';

// URL 쿼리 파라미터 제거나 (OAuth Code 등)
void clearOAuthQueryFromUrl() {
  final uri = Uri.base;
  if (uri.queryParameters.containsKey('code') || 
      uri.queryParameters.containsKey('error') ||
      uri.queryParameters.containsKey('state')) {
    
    // 쿼리 파라미터가 제거된 깨끗한 URL 생성
    final newUrl = uri.origin + uri.path;
    print('[Auth] Clearing OAuth params. New URL: $newUrl');
    
    // 히스토리 교체 (리로드 없음)
    html.window.history.replaceState(null, '', newUrl);
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final List<String> _logs = [];

  AuthProvider() {
    addLog('AuthProvider initialized');
    addLog('URL: ${Uri.base.toString()}');
    addLog('Origin: ${Uri.base.origin}');
    
    // 초기화 시 바로 리스너 연결
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  List<String> get logs => _logs;

  void addLog(String message) {
    // 시간을 포함한 로그 추가
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 12);
    final logMsg = '[$timestamp] $message';
    print(logMsg);
    _logs.add(logMsg);
    // UI 업데이트 (로그 표시용)
    notifyListeners();
  }

  void _init() {
    // 1. 초기 세션 확인
    try {
      final session = Supabase.instance.client.auth.currentSession;
      _currentUser = session?.user;
      addLog('Initial Session: ${_currentUser != null ? "Found (${_currentUser!.email})" : "None"}');
      
      if (_currentUser != null) {
        // 이미 세션이 있으면 URL 정리 한 번 시도 (재진입 시)
        clearOAuthQueryFromUrl();
      }
    } catch (e) {
      addLog('Error checking initial session: $e');
    }

    // 2. Auth State 변경 리스너
    _authService.authStateChanges.listen((AuthState state) async {
      addLog('Auth Event: ${state.event}');
      
      final session = state.session;
      _currentUser = session?.user;
      addLog('Current User: ${_currentUser?.email ?? "None"}');
      
      if (state.event == AuthChangeEvent.signedIn || state.event == AuthChangeEvent.initialSession) {
        addLog('Signed In / Initial Session detected');
        // 여기서 URL 정리는 라우팅 직후에 하는게 더 안전할 수 있으나, 
        // 상태 변경 시점에도 체크
        if (_currentUser != null) {
           // 프로필 생성 시도
           try {
             addLog('Upserting profile...');
             await _authService.upsertUserProfile(_currentUser!);
             addLog('Profile upserted.');
           } catch(e) {
             addLog('Profile upsert error: $e');
           }
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        addLog('User signed out.');
      }
      
      notifyListeners();
    });
  }

  Future<void> signInWithKakao() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      addLog('Calling signInWithKakao...');
      print('[$DateTime.now()] [Auth] OAuth START');
      await _authService.signInWithKakao();
      addLog('signInWithKakao returned (Web flow might redirect)');
    } catch (e) {
      addLog('Login Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      addLog('Signing out...');
      await _authService.signOut();
      _currentUser = null; 
      addLog('Sign out complete');
    } catch (e) {
      addLog('Sign out error: $e');
    }
    notifyListeners();
  }
}
