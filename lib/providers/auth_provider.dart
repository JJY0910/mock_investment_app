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
    _init();
  }
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  
  /// 초기화
  void _init() {
    // 현재 세션 확인
    _currentUser = _authService.currentUser;
    
    // 인증 상태 변경 감지
    _authService.authStateChanges.listen((AuthState state) async {
      _currentUser = state.session?.user;
      
      // 첫 로그인 시 프로필 생성
      if (_currentUser != null && state.event == AuthChangeEvent.signedIn) {
        try {
          await _authService.upsertUserProfile(_currentUser!);
        } catch (e) {
          _error = '프로필 생성 실패: $e';
        }
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
