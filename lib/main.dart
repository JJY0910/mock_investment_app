import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/price_provider.dart';
import 'providers/theme_provider.dart'; // Theme provider
import 'theme/app_theme.dart'; // Theme definitions
import 'screens/login_screen.dart';
import 'screens/home_hub_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/rank_screen.dart';

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
            '/home': (context) => const HomeHubScreen(),
            '/trade': (context) => const TradeScreen(),
            '/rank': (context) => const RankScreen(),
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


