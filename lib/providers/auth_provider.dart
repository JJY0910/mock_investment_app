import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// 인증 상태 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  AuthProvider() {
    print('--- [AuthProvider] Initializing ---');
    _init();
  }
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  
  /// 초기화
  void _init() {
    // 1. 초기 세션 확인 (약간의 딜레이 후 확인하여 URL 처리 시간 확보)
    Future.delayed(const Duration(milliseconds: 100), () {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        print('--- [AuthProvider] Delayed check: Session found for ${session.user.email} ---');
        _currentUser = session.user;
        notifyListeners();
      } else {
        print('--- [AuthProvider] Delayed check: No session found ---');
      }
    });
    
    // 2. 인증 상태 변경 감지
    _authService.authStateChanges.listen((AuthState state) async {
      print('--- [AuthProvider] AuthState Changed: ${state.event} ---');
      
      final session = state.session;
      _currentUser = session?.user;
      
      if (_currentUser != null) {
        print('--- [AuthProvider] User active: ${_currentUser!.email} ---');
        
        // 로그인 성공 시 프로필 생성 시도
        if (state.event == AuthChangeEvent.signedIn || state.event == AuthChangeEvent.initialSession) {
          try {
            print('--- [AuthProvider] Attempting profile upsert ---');
            await _authService.upsertUserProfile(_currentUser!);
            print('--- [AuthProvider] Profile upsert successful ---');
          } catch (e) {
            print('--- [AuthProvider] Profile upsert failed: $e ---');
            // 프로필 생성 실패해도 로그인은 유지되도록 에러만 기록
            _error = '프로필 설정 중 오류가 발생했습니다.';
          }
        }
      } else {
        print('--- [AuthProvider] No user active ---');
      }
      
      notifyListeners();
    });
  }
  
  /// 카카오 로그인
  Future<void> signInWithKakao() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithKakao();
    } catch (e) {
      _error = '로그인 실패: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = '로그아웃 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
