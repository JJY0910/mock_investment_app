import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import '../services/ranking_service.dart';
import '../models/ranking_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// 내정보 화면
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isChanging = false;
  bool _isLoading = false;
  String? _error;
  
  // 랭킹 정보 (별도 로드)
  RankingEntry? _myRank;
  bool _isLoadingRank = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 랭킹 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyRank();
    });
  }
  
  Future<void> _loadMyRank() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return;
    
    if (mounted) setState(() => _isLoadingRank = true);
    
    try {
      final rankingService = RankingService();
      // 내 수익률 랭킹 조회 (전기간)
      final rankEntry = await rankingService.fetchMyProfitRank(
        userId: user.id,
        timeframe: 'all',
      );
      
      if (mounted) {
        setState(() {
          _myRank = rankEntry;
          _isLoadingRank = false;
        });
      }
    } catch (e) {
      print('[ProfileScreen] Rank load error: $e');
      if (mounted) setState(() => _isLoadingRank = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _changeNickname() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return;

    final newNickname = _nicknameController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      final success = await authService.updateNickname(
        userId: user.id,
        newNickname: newNickname,
      );

      if (success) {
        // Update local user
        await userProvider.setNickname(newNickname);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('닉네임이 변경되었습니다')),
          );
          setState(() {
            _isChanging = false;
            _nicknameController.clear();
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await authProvider.signOut();
      await userProvider.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내정보'),
        elevation: 0,
      ),
      // Consumer2를 사용하여 UserProvider와 SubscriptionProvider 동시 사용
      body: Consumer2<UserProvider, SubscriptionProvider>(
        builder: (context, userProvider, subProvider, child) {
          final user = userProvider.currentUser;
          final authUser = Supabase.instance.client.auth.currentUser;

          // 1. 유저 정보 로딩 중이면 스피너 표시
          if (userProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. 유저 정보가 없으면 에러/재시도 화면 (무한 로딩 방지)
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('사용자 정보를 불러오지 못했습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        userProvider.syncFromSession(
                          session.user.id,
                          session.user.email,
                          session.user.appMetadata,
                        );
                      } else {
                         Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    child: const Text('재시도'),
                  ),
                ],
              ),
            );
          }

          // 3. 정상: 프로필 UI 렌더링
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 카드
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue,
                              child: Text(
                                user.nickname.isNotEmpty
                                    ? user.nickname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.nickname,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authUser?.email ?? user.email ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // 플랜 및 랭킹 정보 추가
                        _buildInfoRow(
                          '현재 플랜', 
                          subProvider.currentTier.displayName,
                          isHighlight: subProvider.isPro || subProvider.isMax
                        ),
                        
                        _buildInfoRow(
                          '수익률 랭킹',
                          _isLoadingRank 
                              ? '로딩 중...' 
                              : (_myRank != null ? '${_myRank!.rank}위' : '순위 없음'),
                          isHighlight: _myRank != null && _myRank!.rank <= 10
                        ),
                        
                        _buildInfoRow(
                          '가입일',
                          _formatDate(user.createdAt),
                        ),
                        
                        _buildInfoRow(
                          '로그인 방식',
                          user.provider == 'kakao' ? '카카오' : user.provider,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 멤버십 업그레이드 유도 (Free 유저인 경우)
                if (subProvider.isFree) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade50, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.indigo, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Pro 멤버십으로 업그레이드',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '실시간 랭킹 확인 및 고급 차트 제공',
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/pricing');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('보기'),
                        )
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),

                // 닉네임 변경 섹션
                Text(
                  '계정 관리',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isChanging
                        ? Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _nicknameController,
                                  decoration: InputDecoration(
                                    labelText: '새 닉네임',
                                    hintText: '2~12자',
                                    border: const OutlineInputBorder(),
                                    errorText: _error,
                                  ),
                                  validator: (value) => UserProvider.validateNickname(value ?? ''),
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '⚠️ 닉네임은 1회만 변경 가능합니다',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  _isChanging = false;
                                                  _nicknameController.clear();
                                                  _error = null;
                                                });
                                              },
                                        child: const Text('취소'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _changeNickname,
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('변경'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('닉네임 변경'),
                                subtitle: const Text('닉네임은 1회만 변경 가능합니다.'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  setState(() {
                                    _isChanging = true;
                                  });
                                },
                              ),
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                                onTap: _logout,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.blue[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
