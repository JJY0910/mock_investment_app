import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

import 'url_helper_stub.dart'
  if (dart.library.html) 'url_helper_web.dart';

// URL cleanup is now handled by conditional import
// Web: url_helper_web.dart (uses dart:html)
// Non-web: url_helper_stub.dart (no-op)

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
    bool hasOAuthParams = false;
    try {
      final uri = Uri.base;
      hasOAuthParams = uri.queryParameters.containsKey('code') && 
                       uri.queryParameters.containsKey('state');
      
      final session = Supabase.instance.client.auth.currentSession;
      _currentUser = session?.user;
      addLog('Initial Session: ${_currentUser != null ? "Found (${_currentUser!.email})" : "None"}');
      
      if (_currentUser != null) {
        // 이미 세션이 있으면 URL 정리 한 번 시도 (재진입 시)
        clearOAuthQueryFromUrl();
      } else if (hasOAuthParams) {
        // Phase 3-4: OAuth callback but no session yet - wait briefly for SDK to process
        addLog('OAuth params detected, waiting for token exchange...');
        Future.delayed(const Duration(seconds: 2), () {
          final newSession = Supabase.instance.client.auth.currentSession;
          if (newSession == null) {
            // Token exchange failed (401)
            print('AUTH_EXCHANGE_FAIL: 401 Unauthorized (or timeout)');
            addLog('AUTH_EXCHANGE_FAIL: Token exchange failed');
            _error = '로그인에 실패했습니다. 다시 시도해주세요.';
            clearOAuthQueryFromUrl();
            notifyListeners();
          }
        });
      }
    } catch (e) {
      addLog('Error checking initial session: $e');
    }

    // 2. Auth State 변경 리스너
    _authService.authStateChanges.listen((AuthState state) async {
      print('[AuthProvider] ===== AUTH STATE CHANGE =====');
      print('[AuthProvider] Event: ${state.event}');
      addLog('Auth Event: ${state.event}');
      
      final session = state.session;
      final previousUser = _currentUser;
      _currentUser = session?.user;
      
      // Phase 3-9: Comprehensive session logging
      print('[AuthProvider] Current User: ${_currentUser?.email ?? "None"}');
      print('[AuthProvider] Session exists: ${session != null}');
      if (session != null) {
        print('[AuthProvider] Session.accessToken exists: ${session.accessToken.isNotEmpty}');
        print('[AuthProvider] Session.user.id: ${session.user?.id}');
      }
      
      // LocalStorage keys dump removed (requires dart:html)
      
      addLog('Current User: ${_currentUser?.email ?? "None"}');
      
      if (state.event == AuthChangeEvent.signedIn || state.event == AuthChangeEvent.initialSession) {
        print('[AuthProvider] SIGNED_IN detected!');
        addLog('Signed In / Initial Session detected');
        
        if (_currentUser != null) {
          // Success! Clear any previous error
          _error = null;
          
          // URL 정리 (성공 시)
          print('[AuthProvider] Clearing OAuth query params from URL...');
          clearOAuthQueryFromUrl();
          
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
        
        // Phase 3-4: If signedOut event during OAuth callback, it indicates failure
        if (hasOAuthParams && previousUser == null) {
          print('AUTH_EXCHANGE_FAIL: SignedOut event during OAuth callback');
          addLog('AUTH_EXCHANGE_FAIL: SignedOut during callback');
          _error = '로그인에 실패했습니다. 다시 시도해주세요.';
          clearOAuthQueryFromUrl();
        }
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
