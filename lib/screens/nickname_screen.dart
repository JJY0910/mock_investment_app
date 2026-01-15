import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/analytics_service.dart'; // GA4

/// 닉네임 설정 화면 (온보딩)
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({Key? key}) : super(key: key);

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  bool _isChecking = false;
  bool _isSaving = false;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _checkAndSave() async {
    final nickname = _controller.text.trim();
    
    // 유효성 검사
    final validationError = UserProvider.validateNickname(nickname);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }
    
    // 저장 (DB 트리거 및 RPC가 규칙 체크)
    setState(() {
      _isChecking = false;
      _isSaving = true;
    });
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.setNickname(nickname);
      
      if (mounted) {
        // GA4: sign_up event
        AnalyticsService.logSignUp(method: 'nickname_onboarding');
        
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      print('[NicknameScreen] RPC FAILED: $errorMsg');
      
      setState(() {
        _isSaving = false;
        _errorMessage = errorMsg;
      });
      
      // [HARDENING] Show explicit SnackBar for immediate UX feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  void _setRandomNickname() {
    final random = Random();
    final adjectives = ['빠른', '강한', '똑똑한', '용감한', '현명한', '멋진'];
    final nouns = ['트레이더', '투자자', '매수왕', '수익러', '가즈아'];
    
    final nickname = '${adjectives[random.nextInt(adjectives.length)]}${nouns[random.nextInt(nouns.length)]}${random.nextInt(9999)}';
    
    _controller.text = nickname;
    setState(() {
      _errorMessage = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      '닉네임 설정',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      '닉네임은 랭킹과 점수에 표시됩니다\n한글, 영문, 숫자, 언더스코어(_) 사용 가능 (2-12자)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        hintText: '닉네임을 입력하세요',
                        errorText: _errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      maxLength: 12,
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                      onSubmitted: (_) => _checkAndSave(),
                    ),
                    const SizedBox(height: 12),
                    
                    TextButton.icon(
                      onPressed: _setRandomNickname,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('랜덤 닉네임 추천'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: (_isChecking || _isSaving) ? null : _checkAndSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isChecking || _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '시작하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
