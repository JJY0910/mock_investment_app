import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Hub screen with navigation to Trade and Rank sections
class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({Key? key}) : super(key: key);

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
                      Text(
                        '모의투자 플랫폼',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Trading Button
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
}
