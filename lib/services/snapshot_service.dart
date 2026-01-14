import 'package:supabase_flutter/supabase_flutter.dart';

/// 스냅샷 서비스
/// 사용자의 총자산을 일일 스냅샷으로 기록
class SnapshotService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// 일일 스냅샷 기록 (하루 1회 upsert)
  /// 오늘 날짜에 이미 스냅샷이 있으면 업데이트, 없으면 생성
  Future<bool> ensureDailySnapshot({
    required String userId,
    required double totalAssets,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      await _supabase.from('portfolio_snapshots').upsert({
        'user_id': userId,
        'snapshot_date': today,
        'total_assets': totalAssets,
      }, onConflict: 'user_id, snapshot_date');
      
      print('[SnapshotService] Daily snapshot saved: $userId, $today, $totalAssets');
      return true;
    } catch (e) {
      print('[SnapshotService] Error saving snapshot: $e');
      return false;
    }
  }
  
  /// 특정 날짜의 스냅샷 조회
  Future<double?> getSnapshotForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('portfolio_snapshots')
          .select('total_assets')
          .eq('user_id', userId)
          .eq('snapshot_date', dateStr)
          .maybeSingle();
      
      if (response != null) {
        return (response['total_assets'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      print('[SnapshotService] Error getting snapshot: $e');
      return null;
    }
  }
  
  /// N일 전 스냅샷 조회 (수익률 계산용)
  Future<double?> getSnapshotDaysAgo({
    required String userId,
    required int daysAgo,
  }) async {
    final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
    return getSnapshotForDate(userId: userId, date: targetDate);
  }
}
