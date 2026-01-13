// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/trader_score_provider.dart';
import '../providers/user_provider.dart';
import '../services/disclaimer_service.dart';
import '../widgets/disclaimer_dialog.dart';

/// Hub screen with navigation to Trade and Rank sections
class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({Key? key}) : super(key: key);

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDisclaimer();
    });
  }

  Future<void> _checkDisclaimer() async {
    final accepted = await DisclaimerService.isAccepted();
    if (!accepted && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DisclaimerDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'Trader Lab',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: Colors.orange.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.orange.withOpacity(0.5)),
                         ),
                         child: const Text(
                           '모의투자 플랫폼',
                           style: TextStyle(
                             fontSize: 14,
                             color: Colors.orange,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                      ),
                      const SizedBox(height: 24),
              
              // PHASE 2-3-2: 트레이더 상태 카드
              Consumer2<TraderScoreProvider, UserProvider>(
                builder: (context, scoreProvider, userProvider, child) {
                  return _buildTraderStatusCard(context, scoreProvider, userProvider);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Action Cardsing Button
                      _buildNavigationCard(
                        context,
                        icon: Icons.trending_up,
                        iconColor: const Color(0xFF10b981),
                        title: '모의투자 시작',
                        description: '실시간 차트와 함께 거래를 시작하세요',
                        onTap: () => Navigator.pushNamed(context, '/trade'),
                      ),
                      const SizedBox(height: 20),

                      // Ranking Button
                      _buildNavigationCard(
                        context,
                        icon: Icons.leaderboard,
                        iconColor: Colors.blue,
                        title: '자산 랭킹',
                        description: '투자자 순위를 확인하세요',
                        onTap: () => Navigator.pushNamed(context, '/rank'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Theme toggle button in top-right
            Positioned(
              top: 16,
              right: 16,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onPressed: () => themeProvider.toggle(),
                    tooltip: themeProvider.isDark ? '라이트 모드' : '다크 모드',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).textTheme.bodySmall?.color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 트레이더 상태 카드
  Widget _buildTraderStatusCard(BuildContext context, TraderScoreProvider scoreProvider, UserProvider userProvider) {
    final score = scoreProvider.currentScore;
    final stage = scoreProvider.currentStage;
    final badge = scoreProvider.currentBadge;
    final nickname = userProvider.currentUser?.nickname ?? '트레이더';
    
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final delta7d = scoreProvider.history
        .where((h) => h.timestamp.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, h) => sum + h.delta);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/trade'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$stage • ${badge.displayName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem('현재 점수', score.toStringAsFixed(1), Colors.blue),
                  _buildStatusItem('7일 변화', '${delta7d >= 0 ? '+' : ''}${delta7d.toStringAsFixed(1)}', 
                      delta7d >= 0 ? Colors.green : Colors.red),
                  _buildStatusItem('거래', '${scoreProvider.history.length}회', Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '모의투자 하러가기 →',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
