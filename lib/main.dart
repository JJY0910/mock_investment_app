import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/price_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  SupabaseConfig.setInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 시세 데이터 Provider
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        
        // 향후 추가 Providers (UserProvider, PortfolioProvider 등)
      ],
      child: MaterialApp(
        title: '모의 투자 트레이더',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          fontFamily: 'NotoSans', // 한글 폰트 (웹에서 Google Fonts 사용 가능)
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
