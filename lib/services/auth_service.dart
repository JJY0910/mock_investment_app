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
    print('[AuthService] signInWithKakao ENTER');
    
    try {
      // Phase 3-10: Use SDK's OAuth flow (SDK manages PKCE internally)
      const redirectUrl = 'https://www.trader-lab.cloud';
      
      print('[AuthService] ===== OAuth START =====');
      print('[AuthService] Redirect URL (hardcoded): $redirectUrl');
      print('[AuthService] Using SDK signInWithOAuth (SDK manages PKCE)...');
      
      // Let SDK handle PKCE generation, storage, and navigation
      // Web platform: SDK uses window.location.assign automatically
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
      );
      
      print('[AuthService] signInWithOAuth completed (navigation should happen)');
      print('[AuthService] signInWithKakao EXIT');
      return true;
    } catch (e, stackTrace) {
      print('[AuthService] EXCEPTION in signInWithKakao: $e');
      print('[AuthService] Stack trace: $stackTrace');
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
