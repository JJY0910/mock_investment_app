import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// User Provider (닉네임 온보딩 시스템)
class UserProvider extends ChangeNotifier {
  static const String _storageKey = 'user_v1';
  
  User? _currentUser;
  bool _loading = false;
  
  User? get currentUser => _currentUser;
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;
  bool get needsNickname => _currentUser != null && !_currentUser!.nicknameSet;
  
  /// 로드
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString);
        _currentUser = User.fromJson(json);
        print('[UserProvider] Loaded user: ${_currentUser!.id}, nickname: ${_currentUser!.nickname}');
      }
    } catch (e) {
      print('[UserProvider] Error loading user: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  /// 저장
  Future<void> _save() async {
    if (_currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_currentUser!.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('[UserProvider] Error saving user: $e');
    }
  }
  
  /// OAuth 로그인 후 User 생성 또는 로드
  Future<User> loginWithOAuth({
    required String provider,
    required String providerUserId,
    String? email,
  }) async {
    // 기존 user가 있으면 lastLoginAt 업데이트
    if (_currentUser != null && _currentUser!.providerUserId == providerUserId) {
      _currentUser = _currentUser!.copyWith(
        lastLoginAt: DateTime.now(),
      );
    } else {
      // 새 user 생성
      _currentUser = User.create(
        provider: provider,
        providerUserId: providerUserId,
        email: email,
      );
    }
    
    await _save();
    notifyListeners();
    
    print('[UserProvider] Login: ${_currentUser!.id}, needsNickname: $needsNickname');
    return _currentUser!;
  }
  
  /// 세션 기반 동기화 (AuthGate에서 호출)
  Future<void> syncFromSession(String userId, String? email, Map<String, dynamic>? metadata) async {
    _loading = true;
    notifyListeners();
    
    try {
      final authService = AuthService();
      final profile = await authService.fetchProfile(userId);
      
      String provider = 'email';
      String providerUserId = userId;
      
      if (metadata != null) {
        provider = metadata['provider'] ?? 'email';
        providerUserId = metadata['provider_id'] ?? userId;
      }
      
      if (profile != null) {
        // 기존 프로필 존재 -> 로드
        final nickname = profile['nickname'] as String?;
        final isNicknameSet = nickname != null && nickname.isNotEmpty;
        
        // 기존 정보 유지하면서 업데이트 or 새로 생성
        _currentUser = User(
          id: userId,
          provider: provider,
          providerUserId: providerUserId,
          email: email,
          nickname: nickname ?? '',
          nicknameSet: isNicknameSet,
          createdAt: _currentUser?.createdAt ?? DateTime.parse(profile['created_at'] ?? DateTime.now().toIso8601String()),
          lastLoginAt: DateTime.now(),
        );
        
        print('[UserProvider] Synced existing user: $nickname (Set: $isNicknameSet)');
      } else {
        // 프로필 없음 -> 신규 유저 취급
        _currentUser = User.create(
          provider: provider,
          providerUserId: providerUserId,
          email: email,
        );
        print('[UserProvider] Created fresh user state (needs nickname)');
      }
      
      await _save();
      
    } catch (e) {
      print('[UserProvider] Sync error: $e');
      // 에러 시에도 최소한의 유저 상태는 생성해서 무한 로딩 방지
      if (_currentUser == null) {
         _currentUser = User.create(
          provider: 'unknown',
          providerUserId: userId,
          email: email,
        );
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  /// 닉네임 설정 (Supabase profiles에 저장)
  Future<bool> setNickname(String nickname) async {
    if (_currentUser == null) return false;
    
    try {
      final authService = AuthService();
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      
      if (supabaseUser == null) {
        print('[UserProvider] No Supabase user found');
        throw Exception('로그인 세션이 만료되었습니다');
      }
      
      // Supabase profiles에 저장 (DB 트리거가 규칙 체크)
      await authService.upsertUserProfile(
        userId: supabaseUser.id,
        nickname: nickname,
        email: supabaseUser.email,
      );
      
      // 로컬 업데이트
      _currentUser = _currentUser!.copyWith(
        nickname: nickname,
        nicknameSet: true,
      );
      
      await _save();
      notifyListeners();
      
      print('[UserProvider] Nickname set: $nickname');
      return true;
    } catch (e) {
      print('[UserProvider] Nickname set error: $e');
      rethrow; // Let caller handle the error
    }
  }
  
  /// 로그아웃
  Future<void> logout() async {
    _currentUser = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('[UserProvider] Error during logout: $e');
    }
    
    notifyListeners();
    print('[UserProvider] Logged out');
  }
  
  /// 닉네임 유효성 검사
  static String? validateNickname(String nickname) {
    // 길이 체크
    if (nickname.length < 2) {
      return '닉네임은 최소 2자 이상이어야 합니다';
    }
    if (nickname.length > 12) {
      return '닉네임은 최대 12자까지 가능합니다';
    }
    
    // 문자 체크 (한글, 영문, 숫자, 언더스코어만)
    final validPattern = RegExp(r'^[가-힣a-zA-Z0-9_]+$');
    if (!validPattern.hasMatch(nickname)) {
      return '한글, 영문, 숫자, 언더스코어(_)만 사용 가능합니다';
    }
    
    // 욕설 필터 (간단한 blacklist)
    final blacklist = ['시발', 'fuck', '개새끼', 'admin', 'administrator'];
    final lowerNickname = nickname.toLowerCase();
    for (final word in blacklist) {
      if (lowerNickname.contains(word)) {
        return '사용할 수 없는 단어가 포함되어 있습니다';
      }
    }
    
    return null; // 유효함
  }
  
  /// 닉네임 중복 체크 (Supabase profiles)
  Future<bool> checkNicknameDuplicate(String nickname) async {
    try {
      final authService = AuthService();
      return await authService.checkNicknameDuplicate(nickname);
    } catch (e) {
      print('[UserProvider] Duplicate check error: $e');
      return false;
    }
  }
}
