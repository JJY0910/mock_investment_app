import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/price_provider.dart';
import 'providers/theme_provider.dart'; // Theme provider
import 'providers/favorites_provider.dart'; // Favorites provider
import 'providers/market_quotes_provider.dart'; // Market quotes provider
import 'providers/exchange_rate_provider.dart'; // Exchange rate provider
import 'providers/portfolio_provider.dart'; // Portfolio provider
import 'providers/selected_coin_provider.dart'; // Selected coin provider
import 'providers/orders_provider.dart'; // Orders provider
import 'providers/trade_history_provider.dart'; // Trade history provider
import 'providers/trader_score_provider.dart'; // Trader score provider (PHASE 2-1)
import 'providers/user_provider.dart'; // User provider (PHASE 2-2)
import 'providers/subscription_provider.dart'; // PHASE 3
import 'theme/app_theme.dart'; // Theme definitions
import 'screens/login_screen.dart';
import 'screens/home_hub_screen.dart';
import 'screens/history_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/wallet_screen.dart'; // Wallet screen
import 'screens/rank_screen.dart';
import 'screens/nickname_screen.dart'; // PHASE 2-2: Nickname onboarding
import 'screens/pricing_screen.dart'; // PHASE 3: Pricing screen
import 'screens/profile_screen.dart'; // Profile screen
import 'services/analytics_service.dart'; // GA4 Analytics

// Import conditional url_helper for web-specific operations
import 'providers/url_helper_stub.dart'
  if (dart.library.html) 'providers/url_helper_web.dart';

void main() async {
  // [CRITICAL] Initialize Flutter FIRST before ANY other operations
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: usePathUrlStrategy() removed - it crashes when URL has query params
  // Will use default hash routing (#/) which is safer for OAuth callbacks
  
  print('=== MINIMAL APP START ===');
  
  // [1] Use platform-neutral Uri.base instead of dart:html
  final uri = Uri.base;
  final rawUrl = uri.toString();
  
  print('BOOT_URL: $rawUrl');
  
  // [2] Detect OAuth parameters
  final hasCode = uri.queryParameters.containsKey('code');
  
  // Phase 3-10: Changed - code alone is sufficient for callback detection
  // DO NOT require 'state' parameter
  final isCallbackCandidate = hasCode;
  
  print('OAuth code present: $hasCode');
  print('IS_CALLBACK_CANDIDATE: $isCallbackCandidate');
  
  // Phase 3-10: CRITICAL - NEVER clear URL before Supabase.initialize()
  // SDK needs to read 'code' parameter for PKCE token exchange
  // URL cleanup will happen AFTER initialize in auth_provider if needed
  
  print('INIT_START');
  
  try {
    // [4] Initialize Supabase with 8-second timeout
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    ).timeout(const Duration(seconds: 8));
    
    print('INIT_OK');
    SupabaseConfig.setInitialized();
    
    runApp(const MyApp());
    
  } catch (e) {
    print('INIT_FAIL: $e');
    
    // [5] On init failure, clear query params if callback candidate
    if (isCallbackCandidate) {
      final cleanUrl = uri.replace(queryParameters: {}).toString();
      replaceHistoryState(cleanUrl); // Use url_helper instead of html.window
      print('QUERY_CLEARED: true (init failed)');
    }
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '로그인 세션이 만료되었습니다.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '다시 시도해주세요.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    redirectToRoot(); // Use url_helper instead of html.window
                  },
                  child: const Text('로그인 화면으로'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Theme provider FIRST
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()), // Load favorites on init
        ChangeNotifierProvider(create: (_) => MarketQuotesProvider()), // Market quotes provider
        ChangeNotifierProvider(create: (_) => ExchangeRateProvider()..loadOnce()), // Load exchange rate on init
        ChangeNotifierProvider(create: (_) => PortfolioProvider()..load()), // Load portfolio on init
        ChangeNotifierProvider(create: (_) => SelectedCoinProvider()..initialize()), // Selected coin provider
        ChangeNotifierProvider(create: (_) => OrdersProvider()..load()), // Orders provider
        ChangeNotifierProvider(create: (_) => TradeHistoryProvider()..load()), // Trade history provider
        ChangeNotifierProvider(create: (_) => TraderScoreProvider()..load()), // PHASE 2-1: Trader score provider
        ChangeNotifierProvider(create: (_) => UserProvider()..load()), // PHASE 2-2: User provider
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..load()), // PHASE 3: Subscription
      ],
      child: const ThemeGate(), // Use ThemeGate to load theme before MaterialApp
    );
  }
}

// ThemeGate: Load theme before rendering MaterialApp
class ThemeGate extends StatelessWidget {
  const ThemeGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Show loading screen until theme is loaded
        if (!themeProvider.isLoaded) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFF9FAFB), // Light scaffold color
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trader Lab',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Initialize AnalyticsService with SubscriptionProvider
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        AnalyticsService.init(subscriptionProvider);

        // Theme loaded, show main app
        return MaterialApp(
          title: 'Trader Lab',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.mode,
          // Phase 3-3: Use AuthGate to handle session-based routing
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const OnboardingGate(child: HomeHubScreen()),
            '/trade': (context) => const OnboardingGate(child: TradeScreen()),
            '/wallet': (context) => const OnboardingGate(child: WalletScreen()),
            '/rank': (context) => const OnboardingGate(child: RankScreen()),
            '/history': (context) => const OnboardingGate(child: HistoryScreen()),
            '/nickname': (context) => const NicknameScreen(),
            '/pricing': (context) => const PricingScreen(), // PHASE 3
            '/profile': (context) => const OnboardingGate(child: ProfileScreen()), // Profile
          },
        );
      },
    );
  }
}

// Phase 3-3: AuthGate separates routing based on session
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final session = authProvider.session;
        
        if (session != null) {
          // Phase 3-3: Logged in → Go to Home Hub
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/home');
          });
        }
        
        // Show Login by default
        return const LoginScreen();
      },
    );
  }
}



// PHASE 2-2: OnboardingGate - 닉네임 미설정 시 강제 이동
class OnboardingGate extends StatefulWidget {
  final Widget child;
  
  const OnboardingGate({Key? key, required this.child}) : super(key: key);
  
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNickname();
    });
  }
  
  void _checkNickname() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.needsNickname) {
      Navigator.pushReplacementNamed(context, '/nickname');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
