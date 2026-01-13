// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../repositories/mock_leaderboard_repository.dart';
import '../utils/formatters.dart';
import '../providers/trader_score_provider.dart'; // PHASE 2-1: 실점수 연동
import '../providers/user_provider.dart'; // PHASE 2-2: 닉네임

/// 리더보드 화면 - 제품화 버전 (실점수 연동)
class RankScreen extends StatefulWidget {
  const RankScreen({Key? key}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockLeaderboardRepository _repository = MockLeaderboardRepository(currentUserId: 'current_user');
  
  List<LeaderboardEntry>? _entries;
  int? _myRank;
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final sort = _tabController.index == 0 
          ? LeaderboardSort.byScore 
          : LeaderboardSort.byAsset;
      
      final results = await Future.wait([
        _repository.fetchLeaderboard(sort: sort, limit: 50),
        _repository.fetchMyRank(sort: sort),
      ]);
      
      if (mounted) {
        setState(() {
          _entries = results[0] as List<LeaderboardEntry>;
          _myRank = results[1] as int?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('랭킹'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '실력 랭킹'),
            Tab(text: '자산 랭킹'),
          ],
        ),
      ),
      body: Column(
        children: [
          //내 순위 고정 영역 (PHASE 2-1: 실점수 기반)
          Consumer<TraderScoreProvider>(
            builder: (context, scoreProvider, child) {
              return _buildMyRankSection(scoreProvider);
            },
          ),
          
          // PHASE 2-3-2: 내 성장 요약
          Consumer<TraderScoreProvider>(
            builder: (context, scoreProvider, child) {
              return _buildGrowthSummary(scoreProvider);
            },
          ),
          
          // 리스트
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
  
  /// 내 순위 섹션 (PHASE 2-1: TraderScoreProvider 기반)
  Widget _buildMyRankSection(TraderScoreProvider scoreProvider) {
    final isScoreTab = _tabController.index == 0;
    final currentScore = scoreProvider.currentScore;
    final currentStage = scoreProvider.currentStage;
    
    // TODO: 실제 자산 정보는 PortfolioProvider에서 가져와야 함
    final assetKrw = 12500000.0; // 임시
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 순위
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _myRank != null ? '#$_myRank' : '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_myRank != null)
                      Text(
                        '상위 ${(_myRank! / 500 * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 정보
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final nickname = userProvider.currentUser?.nickname ?? '(닉네임 없음)';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentStage • ${scoreProvider.history.length}거래',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // 점수/자산
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isScoreTab 
                      ? currentScore.toStringAsFixed(0)
                      : CoinFormatters.formatKrw(assetKrw),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _buildDeltaChip(
                  isScoreTab ? _calculateRecentDelta(scoreProvider) : 0,
                  isScore: isScoreTab,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  double _calculateRecentDelta(TraderScoreProvider scoreProvider) {
    if (scoreProvider.history.isEmpty) return 0;
    
    // 최근 7일 delta 합계
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final recentHistory = scoreProvider.history.where(
      (h) => h.timestamp.isAfter(sevenDaysAgo)
    );
    
    return recentHistory.fold(0.0, (sum, h) => sum + h.delta);
  }
  
  Widget _buildDeltaChip(double delta, {required bool isScore}) {
    final isPositive = delta > 0;
    final text = isScore 
        ? '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}'
        : '${isPositive ? '+' : ''}${CoinFormatters.formatKrw(delta)}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive 
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPositive ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '랭킹 집계 중...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('랭킹을 불러올 수 없습니다'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    if (_entries == null || _entries!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '아직 랭킹 데이터가 없습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _entries!.length,
        itemBuilder: (context, index) {
          return _buildRankCard(_entries![index], index + 1);
        },
      ),
    );
  }
  
  Widget _buildRankCard(LeaderboardEntry entry, int rank) {
    final isScoreTab = _tabController.index == 0;
    
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.grey[600]!;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 순위 배지
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 트레이더 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.nickname,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStageColor(entry.stage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.stage,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStageColor(entry.stage),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isScoreTab
                        ? '${entry.score.toStringAsFixed(0)}점'
                        : CoinFormatters.formatKrw(entry.assetKrw),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // 변화량
            _buildDeltaChip(
              isScoreTab ? entry.delta7dScore : entry.delta7dAsset,
              isScore: isScoreTab,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStageColor(String stage) {
    switch (stage) {
      case 'Elite':
        return Colors.purple;
      case 'Master':
        return Colors.deepOrange;
      case 'Pro':
        return Colors.blue;
      case 'Advanced':
        return Colors.green;
      case 'Trader':
        return Colors.teal;
      case 'Rookie':
      default:
        return Colors.grey;
    }
  }
  
  /// 성장 요약 섹션
  Widget _buildGrowthSummary(TraderScoreProvider scoreProvider) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final delta7d = scoreProvider.history
        .where((h) => h.timestamp.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, h) => sum + h.delta);
    
    final habitContribution = scoreProvider.history
        .where((h) => h.timestamp.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, h) => sum + h.habitScoreContribution);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 내 성장 요약',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGrowthItem('7일 점수 변화', '${delta7d >= 0 ? '+' : ''}${delta7d.toStringAsFixed(1)}', 
                  delta7d >= 0 ? Colors.green : Colors.red),
              _buildGrowthItem('습관 점수', '${habitContribution >= 0 ? '+' : ''}${habitContribution.toStringAsFixed(1)}',
                  habitContribution >= 0 ? Colors.blue : Colors.orange),
              _buildGrowthItem('현재 배지', scoreProvider.currentBadge.displayName, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGrowthItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
