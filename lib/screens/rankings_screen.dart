// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../models/plan_tier.dart';
import '../models/ranking_entry.dart';
import '../services/ranking_service.dart';
import '../utils/formatters.dart';

/// 랭킹 화면
/// 총자산 랭킹과 수익률 랭킹을 탭으로 구분
class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _profitSubTabController;
  
  final RankingService _rankingService = RankingService();
  
  List<RankingEntry> _totalAssetsLeaderboard = [];
  RankingEntry? _myTotalAssetsRank;
  
  List<RankingEntry> _profitLeaderboard = [];
  RankingEntry? _myProfitRank;
  
  bool _loadingTotalAssets = false;
  bool _loadingProfit = false;
  String _selectedProfitTimeframe = '24h';
  
  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _profitSubTabController = TabController(length: 4, vsync: this);
    
    _mainTabController.addListener(_onMainTabChanged);
    _profitSubTabController.addListener(_onProfitSubTabChanged);
    
    // 초기 데이터 로드
    _loadTotalAssetsLeaderboard();
  }
  
  @override
  void dispose() {
    _mainTabController.dispose();
    _profitSubTabController.dispose();
    super.dispose();
  }
  
  void _onMainTabChanged() {
    if (_mainTabController.index == 1 && _profitLeaderboard.isEmpty) {
      _loadProfitLeaderboard(_selectedProfitTimeframe);
    }
  }
  
  void _onProfitSubTabChanged() {
    final timeframes = ['24h', '7d', '30d', 'all'];
    if (_profitSubTabController.index < timeframes.length) {
      _selectedProfitTimeframe = timeframes[_profitSubTabController.index];
      _loadProfitLeaderboard(_selectedProfitTimeframe);
    }
  }
  
  Future<void> _loadTotalAssetsLeaderboard() async {
    setState(() => _loadingTotalAssets = true);
    
    try {
      final leaderboard = await _rankingService.fetchTotalAssetsLeaderboard(limit: 50);
      final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
      
      RankingEntry? myRank;
      if (userId != null) {
        myRank = await _rankingService.fetchMyTotalAssetsRank(userId);
      }
      
      setState(() {
        _totalAssetsLeaderboard = leaderboard;
        _myTotalAssetsRank = myRank;
        _loadingTotalAssets = false;
      });
    } catch (e) {
      print('[RankingsScreen] Error loading total assets: $e');
      setState(() => _loadingTotalAssets = false);
    }
  }
  
  Future<void> _loadProfitLeaderboard(String timeframe) async {
    setState(() => _loadingProfit = true);
    
    try {
      final leaderboard = await _rankingService.fetchProfitLeaderboard(
        timeframe: timeframe,
        limit: 50,
      );
      final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
      
      RankingEntry? myRank;
      if (userId != null) {
        myRank = await _rankingService.fetchMyProfitRank(userId: userId, timeframe: timeframe);
      }
      
      setState(() {
        _profitLeaderboard = leaderboard;
        _myProfitRank = myRank;
        _loadingProfit = false;
      });
    } catch (e) {
      print('[RankingsScreen] Error loading profit: $e');
      setState(() => _loadingProfit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final currentTier = subscriptionProvider.currentTier;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('자산 랭킹'),
            bottom: TabBar(
              controller: _mainTabController,
              tabs: [
                const Tab(text: '총자산'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('수익률'),
                      if (!currentTier.canViewProfitTabs) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _mainTabController,
            children: [
              // 총자산 탭
              _buildTotalAssetsTab(currentTier),
              
              // 수익률 탭
              _buildProfitTab(currentTier),
            ],
          ),
        );
      },
    );
  }
  
  /// 총자산 랭킹 탭
  Widget _buildTotalAssetsTab(PlanTier currentTier) {
    if (_loadingTotalAssets) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadTotalAssetsLeaderboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 내 순위 카드 (항상 표시)
          if (_myTotalAssetsRank != null)
            _buildMyRankCard(_myTotalAssetsRank!, isProfit: false),
          
          const SizedBox(height: 16),
          
          // 랭킹 리스트
          ..._buildTotalAssetsRankingList(currentTier),
        ],
      ),
    );
  }
  
  /// 총자산 랭킹 리스트 생성
  List<Widget> _buildTotalAssetsRankingList(PlanTier currentTier) {
    final widgets = <Widget>[];
    final canViewTop10 = currentTier.canViewTop10TotalAssets;
    
    // Top 10 영역 (Free는 잠금)
    if (!canViewTop10) {
      widgets.add(_buildLockedSection(
        title: 'Top 1~10',
        message: 'Pro 플랜으로 업그레이드하여 Top 10을 확인하세요!',
      ));
    } else {
      // Pro/Max: Top 10 표시
      final top10 = _totalAssetsLeaderboard.where((e) => e.rank <= 10).toList();
      for (final entry in top10) {
        widgets.add(_buildRankingTile(entry, isProfit: false));
      }
    }
    
    widgets.add(const Divider(height: 32));
    
    // 11~50위 (모든 플랜)
    final rank11to50 = _totalAssetsLeaderboard.where((e) => e.rank >= 11 && e.rank <= 50).toList();
    for (final entry in rank11to50) {
      widgets.add(_buildRankingTile(entry, isProfit: false));
    }
    
    if (rank11to50.isEmpty && !canViewTop10) {
      widgets.add(const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('아직 랭킹 데이터가 없습니다.', style: TextStyle(color: Colors.grey)),
        ),
      ));
    }
    
    return widgets;
  }
  
  /// 수익률 탭
  Widget _buildProfitTab(PlanTier currentTier) {
    // Free 플랜: 잠금
    if (!currentTier.canViewProfitTabs) {
      return _buildFullLockedTab(
        title: '수익률 랭킹',
        message: '수익률 랭킹은 Pro 플랜 이상에서 확인할 수 있습니다.',
        icon: Icons.trending_up,
      );
    }
    
    return Column(
      children: [
        // 서브 탭 (24h, 7d, 30d, ALL)
        TabBar(
          controller: _profitSubTabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '24시간'),
            Tab(text: '7일'),
            Tab(text: '30일'),
            Tab(text: '전체'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _profitSubTabController,
            children: [
              _buildProfitContent('24h'),
              _buildProfitContent('7d'),
              _buildProfitContent('30d'),
              _buildProfitContent('all'),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 수익률 컨텐츠
  Widget _buildProfitContent(String timeframe) {
    if (_loadingProfit) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: () => _loadProfitLeaderboard(timeframe),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 내 순위 카드
          if (_myProfitRank != null)
            _buildMyRankCard(_myProfitRank!, isProfit: true),
          
          const SizedBox(height: 16),
          
          // 랭킹 리스트
          if (_profitLeaderboard.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('수익률 데이터가 부족합니다.\n거래를 시작하면 랭킹에 표시됩니다.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._profitLeaderboard.map((e) => _buildRankingTile(e, isProfit: true)),
        ],
      ),
    );
  }
  
  /// 내 순위 카드
  Widget _buildMyRankCard(RankingEntry entry, {required bool isProfit}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 순위
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 닉네임
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 순위',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  entry.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // 값
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isProfit ? '수익률' : '총자산',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                isProfit
                    ? '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(2)}%'
                    : CoinFormatters.formatKrw(entry.value),
                style: TextStyle(
                  color: isProfit
                      ? (entry.value >= 0 ? Colors.greenAccent : Colors.redAccent)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 랭킹 타일
  Widget _buildRankingTile(RankingEntry entry, {required bool isProfit}) {
    final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
    final isMe = entry.isMe(userId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isMe ? Border.all(color: Colors.blue, width: 1) : null,
      ),
      child: ListTile(
        leading: _buildRankBadge(entry.rank),
        title: Text(
          entry.nickname,
          style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
        ),
        trailing: Text(
          isProfit
              ? '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(2)}%'
              : CoinFormatters.formatKrw(entry.value),
          style: TextStyle(
            color: isProfit
                ? (entry.value >= 0 ? Colors.green : Colors.red)
                : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  /// 순위 배지
  Widget _buildRankBadge(int rank) {
    Color? badgeColor;
    IconData? icon;
    
    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400];
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300];
      icon = Icons.emoji_events;
    }
    
    if (icon != null) {
      return CircleAvatar(
        backgroundColor: badgeColor,
        radius: 18,
        child: Icon(icon, color: Colors.white, size: 18),
      );
    }
    
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      radius: 18,
      child: Text(
        '$rank',
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  /// 잠금 섹션
  Widget _buildLockedSection({required String title, required String message}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/pricing'),
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }
  
  /// 전체 잠금 탭
  Widget _buildFullLockedTab({required String title, required String message, required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Icon(Icons.lock, size: 24, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pricing'),
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Pro 플랜 업그레이드'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
