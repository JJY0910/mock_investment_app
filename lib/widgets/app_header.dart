import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';

/// 트랩클 메인 헤더
/// Web: 로고 + 메뉴 4개 + 로그아웃/내정보
/// Mobile: 로고 + 햄버거 메뉴
class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: isMobile
              ? _buildMobileHeader(context)
              : _buildDesktopHeader(context),
        );
      },
    );
  }

  // Desktop/Tablet Header
  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        // 좌측: 로고
        _buildLogo(context),
        const SizedBox(width: 40),

        // 중앙: 메뉴 4개
        _buildMenuItem(context, '모의투자', '/trade'),
        const SizedBox(width: 20),
        _buildMenuItem(context, '투자내역', '/history'),
        const SizedBox(width: 20),
        _buildMenuItem(context, '모의지갑', '/wallet'),
        const SizedBox(width: 20),
        _buildMenuItem(context, '코인정보', '/coins'),

        const Spacer(),

        // 우측: 다크모드 토글
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              onPressed: () => themeProvider.toggle(),
              tooltip: themeProvider.isDark ? '라이트 모드' : '다크 모드',
            );
          },
        ),
        const SizedBox(width: 8),

        // 우측: 로그아웃
        _buildIconButton(
          context,
          icon: Icons.logout,
          label: '로그아웃',
          onTap: () => _handleLogout(context),
        ),
        const SizedBox(width: 8),

        // 우측: 내정보
        _buildIconButton(
          context,
          icon: Icons.person_outline,
          label: '내정보',
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  // Mobile Header
  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        // 좌측: 로고
        _buildLogo(context),

        const Spacer(),

        // 우측: 다크모드 토글
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              onPressed: () => themeProvider.toggle(),
              tooltip: themeProvider.isDark ? '라이트 모드' : '다크 모드',
            );
          },
        ),

        // 우측: 로그아웃
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          onPressed: () => _handleLogout(context),
          tooltip: '로그아웃',
        ),

        // 우측: 햄버거 메뉴
        IconButton(
          icon: const Icon(Icons.menu, size: 24),
          onPressed: () => _showMobileMenu(context),
          tooltip: '메뉴',
        ),
      ],
    );
  }

  // 로고
  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/'),
      child: Text(
        '트랩클',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  // 메뉴 아이템
  Widget _buildMenuItem(BuildContext context, String label, String route) {
    final isCurrentRoute = ModalRoute.of(context)?.settings.name == route;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isCurrentRoute ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isCurrentRoute ? FontWeight.w600 : FontWeight.normal,
            color: isCurrentRoute
                ? Colors.blue
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  // 아이콘 버튼
  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // 모바일 메뉴 표시
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMobileMenuItem(context, '모의투자', Icons.trending_up, '/trade'),
            _buildMobileMenuItem(context, '투자내역', Icons.history, '/history'),
            _buildMobileMenuItem(context, '모의지갑', Icons.account_balance_wallet, '/wallet'),
            _buildMobileMenuItem(context, '코인정보', Icons.info, '/coins'),
            const Divider(height: 32),
            _buildMobileMenuItem(context, '내정보', Icons.person, null, onTap: () {
              Navigator.pop(context);
              _handleMyInfo(context);
            }),
          ],
        ),
      ),
    );
  }

  // 모바일 메뉴 아이템
  Widget _buildMobileMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    String? route, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }

  // 로그아웃 처리
  void _handleLogout(BuildContext context) async {
    final authService = AuthService();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await authService.signOut();
    await userProvider.logout();
    
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // 내정보 처리
  void _handleMyInfo(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }
}
