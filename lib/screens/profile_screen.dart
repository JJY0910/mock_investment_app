import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
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
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          final authUser = Supabase.instance.client.auth.currentUser;

          // 로딩 중이면 로딩 표시
          if (userProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // OnboardingGate가 이미 체크했으므로, 여기 도달하면 user가 있어야 함
          // 그래도 방어적으로 체크
          if (user == null) {
            return const Center(child: Text('사용자 정보를 불러오는 중...'));
          }

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
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authUser?.email ?? user.email ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
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
                        const SizedBox(height: 8),
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
                const SizedBox(height: 24),

                // 닉네임 변경 섹션
                Text(
                  '닉네임 변경',
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
                              const Text(
                                '닉네임 변경은 1회만 가능합니다.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isChanging = true;
                                    });
                                  },
                                  child: const Text('닉네임 변경하기'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
