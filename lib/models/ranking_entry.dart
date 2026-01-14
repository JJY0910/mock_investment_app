/// 랭킹 엔트리 모델
/// 총자산 랭킹 또는 수익률 랭킹에서 사용
class RankingEntry {
  final String odId;
  final String nickname;
  final double value;   // 총자산(원) 또는 수익률(%)
  final int rank;
  final String? avatarUrl;
  
  const RankingEntry({
    required this.odId,
    required this.nickname,
    required this.value,
    required this.rank,
    this.avatarUrl,
  });
  
  /// JSON에서 생성 (Supabase 응답용)
  factory RankingEntry.fromJson(Map<String, dynamic> json, int rank) {
    return RankingEntry(
      odId: json['user_id'] ?? json['id'] ?? '',
      nickname: json['nickname'] ?? 'Unknown',
      value: (json['total_assets'] ?? json['profit_percent'] ?? 0).toDouble(),
      rank: rank,
      avatarUrl: json['avatar_url'],
    );
  }
  
  /// 내 랭킹인지 확인
  bool isMe(String? currentUserId) => odId == currentUserId;
}
