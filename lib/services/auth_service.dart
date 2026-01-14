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
  
  /// 사용자 프로필 생성/업데이트 (Supabase profiles 테이블)
  Future<void> upsertUserProfile({
    required String userId,
    required String nickname,
    String? email,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'email': email ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('[AuthService] Profile upserted: $nickname');
    } catch (e) {
      print('[AuthService] Profile upsert error: $e');
      rethrow;
    }
  }
  
  /// 닉네임 중복 체크
  Future<bool> checkNicknameDuplicate(String nickname) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('nickname')
          .eq('nickname', nickname)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('[AuthService] Nickname check error: $e');
      return false;
    }
  }
  
  /// Map DB exception to user-friendly error message
  String _mapDbErrorToMessage(dynamic error) {
    final errorStr = error.toString();
    
    // PostgreSQL unique violation
    if (errorStr.contains('duplicate key') || errorStr.contains('unique')) {
      return '이미 사용 중인 닉네임입니다';
    }
    
    // DB trigger exceptions
    if (errorStr.contains('NICKNAME_LENGTH_INVALID')) {
      return '닉네임은 2~16자여야 합니다';
    }
    if (errorStr.contains('NICKNAME_CHARS_INVALID')) {
      return '한글, 영문, 숫자, 언더스코어(_)만 사용 가능합니다';
    }
    if (errorStr.contains('NICKNAME_BANNED')) {
      return '사용할 수 없는 단어가 포함되어 있습니다';
    }
    if (errorStr.contains('NICKNAME_ALREADY_CHANGED')) {
      return '닉네임은 1회만 변경 가능합니다';
    }
    
    // Default
    return '닉네임 처리 중 오류가 발생했습니다';
  }
  
  /// 닉네임 변경 (1회 제한)
  Future<bool> updateNickname({
    required String userId,
    required String newNickname,
  }) async {
    try {
      // 1. 중복 체크 (앱 선검사)
      final isDuplicate = await checkNicknameDuplicate(newNickname);
      if (isDuplicate) {
        throw Exception('이미 사용 중인 닉네임입니다');
      }
      
      // 2. 업데이트 (DB 트리거가 1회 제한, 금칙어, 형식 체크)
      await _supabase.from('profiles').update({
        'nickname': newNickname,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      print('[AuthService] Nickname updated: $newNickname');
      return true;
    } catch (e) {
      print('[AuthService] Nickname update error: $e');
      // Map DB error to user-friendly message
      final userMessage = _mapDbErrorToMessage(e);
      throw Exception(userMessage);
    }
  }
}
