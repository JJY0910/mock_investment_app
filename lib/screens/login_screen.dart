import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Phase 3-1: Required logging
    print('LOGIN SCREEN RENDERED');
    // URL logging removed (requires dart:html)
    
    // Phase 3-4: Show SnackBar when error is set
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF0d47a1),
              Color(0xFF01579b),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                Icon(
                  Icons.show_chart,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 24),
                
                // 앱 이름
                Text(
                  'Trader Lab',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                
                // 설명
                Text(
                  '모의 투자로 실력을 키우세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 64),
                
                // 카카오 로그인 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    }
                    
                    return ElevatedButton(
                      onPressed: () async {
                        print('[UI] Kakao button tapped');
                        
                        // Phase 3-3: Enable real OAuth flow
                        try {
                          await authProvider.signInWithKakao();
                        } catch (e) {
                          print('[UI] Exception from authProvider.signInWithKakao: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('로그인 실패: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        
                        print('[UI] Kakao handler finished');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE812), // 카카오 노란색
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble, size: 24),
                          SizedBox(width: 12),
                          Text(
                            '카카오로 로그인',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // 에러 메시지
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      children: [
                        if (authProvider.error != null)
                          Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(color: Colors.red[300], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // 화면 디버그 로그 표시
                        SizedBox(height: 20),
                        Container(
                          height: 150,
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ListView.builder(
                            itemCount: authProvider.logs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                authProvider.logs[index],
                                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
