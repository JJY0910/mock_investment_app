import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_entry.dart';

/// 랭킹 서비스
/// 총자산 랭킹과 수익률 랭킹 조회
class RankingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // === 총자산 랭킹 ===
  
  /// 총자산 랭킹 조회
  /// [limit]: 조회할 개수
  /// [offset]: 시작 위치 (0부터)
  Future<List<RankingEntry>> fetchTotalAssetsLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // profiles 테이블에서 랭킹 조회 (total_assets 필드 필요)
      // 실제로는 portfolio_snapshots 또는 별도 집계 테이블 사용
      final response = await _supabase
          .from('profiles')
          .select('id, nickname, total_assets, avatar_url')
          .order('total_assets', ascending: false)
          .range(offset, offset + limit - 1);
      
      final List<RankingEntry> entries = [];
      for (int i = 0; i < response.length; i++) {
        entries.add(RankingEntry.fromJson(
          response[i],
          offset + i + 1, // 1-based rank
        ));
      }
      
      return entries;
    } catch (e) {
      print('[RankingService] Error fetching total assets leaderboard: $e');
      return [];
    }
  }
  
  /// 내 총자산 순위 조회
  Future<RankingEntry?> fetchMyTotalAssetsRank(String userId) async {
    try {
      // RPC 함수 호출 (더 효율적)
      // 또는 COUNT 쿼리로 순위 계산
      final myProfile = await _supabase
          .from('profiles')
          .select('id, nickname, total_assets, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      if (myProfile == null) return null;
      
      final myAssets = (myProfile['total_assets'] ?? 0).toDouble();
      
      // 나보다 높은 자산을 가진 사용자 수 = 내 순위 - 1
      final countAbove = await _supabase
          .from('profiles')
          .select('id')
          .gt('total_assets', myAssets);
      
      final rank = countAbove.length + 1;
      
      return RankingEntry(
        odId: userId,
        nickname: myProfile['nickname'] ?? 'Unknown',
        value: myAssets,
        rank: rank,
        avatarUrl: myProfile['avatar_url'],
      );
    } catch (e) {
      print('[RankingService] Error fetching my rank: $e');
      return null;
    }
  }
  
  // === 수익률 랭킹 ===
  
  /// 수익률 랭킹 조회
  /// [timeframe]: '24h', '7d', '30d', 'all'
  Future<List<RankingEntry>> fetchProfitLeaderboard({
    required String timeframe,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final daysAgo = _timeframeToDays(timeframe);
      if (daysAgo == null) {
        // 'all' timeframe - 첫 스냅샷 대비
        return await _fetchAllTimeProfitLeaderboard(limit: limit, offset: offset);
      }
      
      final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
      final targetDateStr = targetDate.toIso8601String().split('T')[0];
      
      // 스냅샷 기반 수익률 계산
      // 실제로는 SQL 뷰 또는 RPC 함수 사용 권장
      final response = await _supabase
          .rpc('get_profit_leaderboard', params: {
            'p_snapshot_date': targetDateStr,
            'p_limit': limit,
            'p_offset': offset,
          });
      
      final List<RankingEntry> entries = [];
      for (int i = 0; i < (response as List).length; i++) {
        final item = response[i] as Map<String, dynamic>;
        entries.add(RankingEntry(
          odId: item['user_id'] ?? '',
          nickname: item['nickname'] ?? 'Unknown',
          value: (item['profit_percent'] ?? 0).toDouble(),
          rank: offset + i + 1,
          avatarUrl: item['avatar_url'],
        ));
      }
      
      return entries;
    } catch (e) {
      print('[RankingService] Error fetching profit leaderboard: $e');
      // RPC 함수가 없으면 빈 리스트 반환
      return [];
    }
  }
  
  /// 내 수익률 순위 조회
  Future<RankingEntry?> fetchMyProfitRank({
    required String userId,
    required String timeframe,
  }) async {
    try {
      final daysAgo = _timeframeToDays(timeframe);
      if (daysAgo == null) return null;
      
      final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
      final targetDateStr = targetDate.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_my_profit_rank', params: {
            'p_user_id': userId,
            'p_snapshot_date': targetDateStr,
          });
      
      if (response == null) return null;
      
      return RankingEntry(
        odId: userId,
        nickname: response['nickname'] ?? 'Unknown',
        value: (response['profit_percent'] ?? 0).toDouble(),
        rank: response['rank'] ?? 0,
        avatarUrl: response['avatar_url'],
      );
    } catch (e) {
      print('[RankingService] Error fetching my profit rank: $e');
      return null;
    }
  }
  
  /// 전체 기간 수익률 조회 (첫 스냅샷 대비)
  Future<List<RankingEntry>> _fetchAllTimeProfitLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    // 구현 필요 - 첫 스냅샷 대비 수익률 계산
    return [];
  }
  
  /// timeframe 문자열을 일수로 변환
  int? _timeframeToDays(String timeframe) {
    switch (timeframe) {
      case '24h':
        return 1;
      case '7d':
        return 7;
      case '30d':
        return 30;
      case 'all':
        return null; // 전체 기간
      default:
        return 1;
    }
  }
}
