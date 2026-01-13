import '../models/leaderboard_entry.dart';

/// Leaderboard repository interface
abstract class LeaderboardRepository {
  /// Fetch leaderboard entries
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardSort sort,
    int limit = 50,
    String? cursor,
  });
  
  /// Fetch current user's leaderboard entry
  Future<LeaderboardEntry?> fetchMyEntry();
  
  /// Get my rank position
  Future<int?> fetchMyRank({required LeaderboardSort sort});
}
