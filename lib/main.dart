import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'config/supabase_config.dart';
import 'providers/price_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// 전역 네비게이터 키
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Supabase 초기화 (PKCE Flow 고정)
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  SupabaseConfig.setInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initAuthListener();
  }

  bool _isNavigating = false;

  void _initAuthListener() {
    final supabase = Supabase.instance.client;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = Uri.base;
      final bool isCallback = uri.queryParameters.containsKey('code') || 
                              uri.queryParameters.containsKey('error') ||
                              uri.queryParameters.containsKey('state');

      print('[$DateTime.now()] [Auth] App Start. Callback Detected: $isCallback');
      print('[$DateTime.now()] [Auth] Current URL: $uri');

      // 1) 콜백 처리 (Supabase SDK가 이미 처리 중일 수 있으므로 세션 대기)
      if (isCallback) {
        print('[$DateTime.now()] [Auth] OAuth Callback processing...');
      }

      final session = supabase.auth.currentSession;
      if (session != null) {
        print('[$DateTime.now()] [Auth] Session Found: ${session.user.email}');
        _navigateToHome();
      } else {
        print('[$DateTime.now()] [Auth] No Session. Staying at Login.');
        // 명시적으로 로그인 화면 이동 (이미 /login 라우트라면 무시됨)
        if (uri.path != '/login') {
           navigatorKey.currentState?.pushReplacementNamed('/login');
        }
      }
    });

    // 2) 인증 상태 변경 리스너
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      print('[$DateTime.now()] [AuthEvent] $event. Session: ${session != null}');

      if (session != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession)) {
        if (!_isNavigating) {
          _navigateToHome();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _isNavigating = false;
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    });
  }

  void _navigateToHome() {
    if (_isNavigating) return;
    _isNavigating = true;

    // URL 정리 (콜백 쿼리 파라미터 제거)
    clearOAuthQueryFromUrl();

    print('[$DateTime.now()] [Auth] Navigating to Home...');
    navigatorKey.currentState?.pushReplacementNamed('/home')?.then((_) {
      _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
      ],
      child: MaterialApp(
        title: 'Trader Lab',
        navigatorKey: navigatorKey, // 전역 키 연결
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // 초기 라우트: 스플래시(로딩) 화면
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        routes: {
          // Splash에서 결정 후 이동할 목적지들
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
