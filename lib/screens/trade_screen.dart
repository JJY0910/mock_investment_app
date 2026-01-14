import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/price_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../features/home/widgets/chart_panel.dart';
import '../features/home/widgets/order_panel.dart';
import '../features/home/widgets/bottom_tabs.dart';
import '../widgets/app_header.dart';
import '../features/trade/widgets/market_summary_bar.dart';
import '../features/trade/widgets/timeframe_bar.dart';
import '../features/trade/widgets/trade_layout.dart';
import '../features/trade/widgets/trade_bottom_section.dart';
import '../features/trade/widgets/market_info_tabs.dart';
import '../widgets/ai_coach_card.dart';

/// Trading Platform Screen - FIXED LAYOUT with Error Boundary
class TradeScreen extends StatefulWidget {
  const TradeScreen({Key? key}) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  String? _error;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final priceProvider = Provider.of<PriceProvider>(context, listen: false);
        priceProvider.startPeriodicUpdate({
          'BTCUSDT': 'crypto',
          'ETHUSDT': 'crypto',
          'XRPUSDT': 'crypto',
        });
      } catch (e) {
        print('[TradeScreen] Error starting price updates: $e');
        setState(() => _error = 'Failed to start price updates: $e');
      }
    });
  }

  void _onSymbolChanged(String? usdtSymbol) {
    if (usdtSymbol != null) {
      try {
        final selectedCoinProvider = Provider.of<SelectedCoinProvider>(context, listen: false);
        selectedCoinProvider.selectByUsdtSymbol(usdtSymbol);
      } catch (e) {
        print('[TradeScreen] Error changing symbol: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state fallback
    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류 발생: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Consumer<SelectedCoinProvider>(
      builder: (context, selectedCoinProvider, child) {
        try {
          final selectedCoin = selectedCoinProvider.selectedCoin;
          final selectedSymbol = selectedCoin != null ? '${selectedCoin.base}USDT' : 'BTCUSDT';
          
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: ListView(
                children: [
                  const AppHeader(),
                  const MarketSummaryBar(),
                  const TimeframeBar(),
                  const MarketInfoTabs(),
                  SizedBox(
                    height: 800,
                    child: TradeLayout(
                      selectedSymbol: selectedSymbol,
                      onCoinSelected: _onSymbolChanged,
                      chartPanel: const ChartPanel(),
                      orderPanel: const OrderPanel(),
                      bottomTabs: const BottomTabs(),
                    ),
                  ),
                  const TradeBottomSection(),
                  const SizedBox(height: 16),
                  const AICoachCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        } catch (e, stack) {
          print('[TradeScreen] Build error: $e\n$stack');
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('화면을 불러오는 중 오류가 발생했습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('새로고침'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
