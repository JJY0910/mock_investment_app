import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

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
  
  /// 닉네임 설정
  Future<bool> setNickname(String nickname) async {
    if (_currentUser == null) return false;
    
    // TODO: 서버 API 호출하여 중복 체크 및 저장
    // 현재는 로컬만
    
    _currentUser = _currentUser!.copyWith(
      nickname: nickname,
      nicknameSet: true,
    );
    
    await _save();
    notifyListeners();
    
    print('[UserProvider] Nickname set: $nickname');
    return true;
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
  
  /// 닉네임 중복 체크 (TODO: 서버 API)
  Future<bool> checkNicknameDuplicate(String nickname) async {
    // TODO: 서버 API 호출
    // 현재는 로컬 mock
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 임시로 특정 닉네임만 중복으로 처리
    final reserved = ['관리자', 'admin', 'test', '테스트'];
    return reserved.contains(nickname.toLowerCase());
  }
}
