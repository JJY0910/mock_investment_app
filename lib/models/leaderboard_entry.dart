/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final double score; // 0-1000 실력 점수
  final String stage; // Rookie, Trader, Advanced, Pro, Master, Elite
  final double assetKrw; // 총 자산 (KRW)
  final double delta7dScore; // 최근 7일 점수 변화
  final double delta7dAsset; // 최근 7일 자산 변화
  final int trades30dCount; // 최근 30일 거래 수
  final DateTime updatedAt;
  
  LeaderboardEntry({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.score,
    required this.stage,
    required this.assetKrw,
    this.delta7dScore = 0.0,
    this.delta7dAsset = 0.0,
    this.trades30dCount = 0,
    required this.updatedAt,
  });
  
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      nickname: json['nickname'],
      avatarUrl: json['avatarUrl'],
      score: (json['score'] ?? 500.0).toDouble(),
      stage: json['stage'] ?? 'Trader',
      assetKrw: (json['assetKrw'] ?? 10000000.0).toDouble(),
      delta7dScore: (json['delta7dScore'] ?? 0.0).toDouble(),
      delta7dAsset: (json['delta7dAsset'] ?? 0.0).toDouble(),
      trades30dCount: json['trades30dCount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'score': score,
      'stage': stage,
      'assetKrw': assetKrw,
      'delta7dScore': delta7dScore,
      'delta7dAsset': delta7dAsset,
      'trades30dCount': trades30dCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Leaderboard sort options
enum LeaderboardSort {
  byScore, // 실력 점수 기준
  byAsset, // 자산 기준
}
