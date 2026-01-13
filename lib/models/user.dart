/// User 모델 (닉네임 온보딩 시스템)
class User {
  final String id;
  final String provider; // kakao, apple, email
  final String providerUserId; // OAuth provider user ID
  final String? email;
  final String nickname;
  final bool nicknameSet;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  User({
    required this.id,
    required this.provider,
    required this.providerUserId,
    this.email,
    required this.nickname,
    required this.nicknameSet,
    required this.createdAt,
    required this.lastLoginAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'providerUserId': providerUserId,
      'email': email,
      'nickname': nickname,
      'nicknameSet': nicknameSet,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      provider: json['provider'] as String,
      providerUserId: json['providerUserId'] as String,
      email: json['email'] as String?,
      nickname: json['nickname'] as String? ?? '',
      nicknameSet: json['nicknameSet'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }
  
  /// User를 복사하여 일부 필드 변경
  User copyWith({
    String? id,
    String? provider,
    String? providerUserId,
    String? email,
    String? nickname,
    bool? nicknameSet,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      nicknameSet: nicknameSet ?? this.nicknameSet,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
  
  /// 기본 User 생성 (OAuth 로그인 후)
  factory User.create({
    required String provider,
    required String providerUserId,
    String? email,
  }) {
    final now = DateTime.now();
    return User(
      id: '${provider}_$providerUserId', // 임시 ID 생성
      provider: provider,
      providerUserId: providerUserId,
      email: email,
      nickname: '', // 닉네임 미설정
      nicknameSet: false,
      createdAt: now,
      lastLoginAt: now,
    );
  }
}
