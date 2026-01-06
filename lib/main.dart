import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/price_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  SupabaseConfig.setInitialized();
  
  // OAuth 콜백 에러 확인 및 로깅
  _checkOAuthErrors();

  runApp(const MyApp());
}

/// OAuth 콜백 에러를 확인하고 콘솔에 출력
void _checkOAuthErrors() {
  final uri = Uri.parse(html.window.location.href);
  
  if (uri.queryParameters.containsKey('error')) {
    final error = uri.queryParameters['error'];
    final errorCode = uri.queryParameters['error_code'];
    final errorDescription = uri.queryParameters['error_description'];
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔴 OAuth Callback Error Detected!');
    print('Error: $error');
    print('Error Code: $errorCode');
    print('Description: $errorDescription');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // URL에서 에러 파라미터 제거
    html.window.history.replaceState(null, '', '/');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
      ],
      child: MaterialApp(
        title: 'Trader Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // 로그인 상태에 따라 화면 전환
            if (authProvider.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
