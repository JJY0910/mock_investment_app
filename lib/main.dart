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

  void _initAuthListener() {
    final supabase = Supabase.instance.client;

    // 1) 앱 시작 시점 세션 확인 (PostFrame으로 안전하게 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
        // 세션이 있어서 홈으로 바로 갈 때도 URL 정리 한 번 수행
        clearOAuthQueryFromUrl();
      } else {
        // 세션 없으면 로그인 화면으로
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    });

    // 2) 인증 상태 변경 리스너
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession)) {
        // 로그인 성공 -> 홈으로
        navigatorKey.currentState?.pushReplacementNamed('/home')?.then((_) {
           clearOAuthQueryFromUrl();
        });
      } else if (event == AuthChangeEvent.signedOut) {
        // 로그아웃 -> 로그인 화면으로
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
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
