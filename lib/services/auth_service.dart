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
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: 'https://trader-lab.cloud/auth/callback',
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
  
  /// 사용자 프로필 생성/업데이트 (첫 로그인 시)
  Future<void> upsertUserProfile(User user) async {
    try {
      // 카카오 정보 추출
      final kakaoId = user.userMetadata?['sub'] as String?;
      final email = user.email;
      final username = user.userMetadata?['name'] as String? ?? 
                       user.userMetadata?['kakao_account']?['profile']?['nickname'] as String? ??
                       'User';
      
      // 프로필 UPSERT
      await _supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            'kakao_id': kakaoId,
            'email': email,
            'username': username,
            'balance': 100000000.00, // 초기 1억
            'initial_balance': 100000000.00,
          }, 
          onConflict: 'id' // id 기준 중복 시 업데이트
      );
      
      print('[AuthService] Profile upserted for user: ${user.id}');
    } catch (e) {
      print('[AuthService] Error upserting profile: $e');
      rethrow;
    }
  }
}
