import 'package:supabase_flutter/supabase_flutter.dart';

/// 인증 서비스 (카카오 로그인)
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// 현재 사용자
  User? get currentUser => _supabase.auth.currentUser;
  
  /// 인증 상태 스트림
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// 카카오 로그인
  Future<bool> signInWithKakao() async {
    try {
      final redirectUrl = Uri.base.origin;
      print('[AuthService] Redirect URL: $redirectUrl');
      
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
        scopes: 'profile_nickname account_email',
      );
      return true;
    } catch (e) {
      print('[AuthService] Kakao login error: $e');
      return false;
    }
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  /// 사용자 프로필 생성/업데이트
  Future<void> upsertUserProfile(User user) async {
    try {
      final username = user.userMetadata?['name'] as String? ?? 'User';
      
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'username': username,
        'balance': 100000000.0,
        'initial_balance': 100000000.0,
      });
    } catch (e) {
      print('[AuthService] Profile error: $e');
    }
  }
}
