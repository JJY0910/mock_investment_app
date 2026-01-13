import 'dart:math';
import '../models/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';

/// Mock implementation ofleaderboard repository
class MockLeaderboardRepository implements LeaderboardRepository {
  final String? currentUserId;
  
  MockLeaderboardRepository({this.currentUserId});
  
  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardSort sort,
    int limit = 50,
    String? cursor,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final random = Random();
    final entries = <LeaderboardEntry>[];
    
    for (int i = 0; i < limit; i++) {
      final rank = i + 1;
      final baseScore = sort == LeaderboardSort.byScore
          ? 900 - (rank * 8) - random.nextInt(50)
          : 500 - (rank * 3) - random.nextInt(30);
      
      final baseAsset = 10000000.0 + (random.nextDouble() * 50000000) - (rank * 500000);
      
      entries.add(LeaderboardEntry(
        userId: 'user_$rank',
        nickname: '트레이더 #${rank.toString().padLeft(3, '0')}',
        avatarUrl: null,
        score: baseScore.clamp(0, 1000).toDouble(),
        stage: _getStage(baseScore.clamp(0, 1000).toDouble()),
        assetKrw: baseAsset.clamp(1000000, 100000000).toDouble(),
        delta7dScore: (random.nextDouble() * 40) - 20, // -20 ~ +20
        delta7dAsset: (random.nextDouble() * 2000000) - 1000000, // -1M ~ +1M
        trades30dCount: random.nextInt(80) + 10,
        updatedAt: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
      ));
    }
    
    // Sort based on criteria
    if (sort == LeaderboardSort.byScore) {
      entries.sort((a, b) => b.score.compareTo(a.score));
    } else {
      entries.sort((a, b) => b.assetKrw.compareTo(a.assetKrw));
    }
    
    return entries;
  }
  
  @override
  Future<LeaderboardEntry?> fetchMyEntry() async {
    if (currentUserId == null) {
      return null;
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return mock user entry
    return LeaderboardEntry(
      userId: currentUserId!,
      nickname: '나의 닉네임',
      avatarUrl: null,
      score: 650.0, // Advanced 구간
      stage: 'Advanced',
      assetKrw: 12500000.0,
      delta7dScore: 15.5,
      delta7dAsset: 850000.0,
      trades30dCount: 35,
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  Future<int?> fetchMyRank({required LeaderboardSort sort}) async {
    final myEntry = await fetchMyEntry();
    if (myEntry == null) return null;
    
    // Simulate ranking calculation
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (sort == LeaderboardSort.byScore) {
      // Score 650 = 상위 25% 정도
      return 125; // 총 500명 중 125등
    } else {
      // Asset 12.5M = 상위 30% 정도
      return 150;
    }
  }
  
  String _getStage(double score) {
    if (score >= 900) return 'Elite';
    if (score >= 800) return 'Master';
    if (score >= 650) return 'Pro';
    if (score >= 500) return 'Advanced';
    if (score >= 300) return 'Trader';
    return 'Rookie';
  }
}
