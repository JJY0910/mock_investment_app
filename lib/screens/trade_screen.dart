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

/// Trading Platform Screen - FIXED LAYOUT
class TradeScreen extends StatefulWidget {
  const TradeScreen({Key? key}) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final priceProvider = Provider.of<PriceProvider>(context, listen: false);
      priceProvider.startPeriodicUpdate({
        'BTCUSDT': 'crypto',
        'ETHUSDT': 'crypto',
        'XRPUSDT': 'crypto',
      });
    });
  }

  void _onSymbolChanged(String? usdtSymbol) {
    if (usdtSymbol != null) {
      final selectedCoinProvider = Provider.of<SelectedCoinProvider>(context, listen: false);
      selectedCoinProvider.selectByUsdtSymbol(usdtSymbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedCoinProvider>(
      builder: (context, selectedCoinProvider, child) {
        final selectedCoin = selectedCoinProvider.selectedCoin;
        final selectedSymbol = selectedCoin != null ? '${selectedCoin.base}USDT' : 'BTCUSDT';
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // FIXED: SafeArea + ListView replaces problematic Column+Expanded+SingleChildScrollView combo
          body: SafeArea(
            child: ListView(
              children: [
                // 상단: AppHeader
                const AppHeader(),
                
                // 헤더 아래: MarketSummaryBar
                const MarketSummaryBar(),
                
                // 타임프레임 바
                const TimeframeBar(),
                
                // 시세/정보 탭 + 4지표
                const MarketInfoTabs(),
                
                // Main content: TradeLayout (fixed height)
                SizedBox(
                  height: 800, // Fixed height container
                  child: TradeLayout(
                    selectedSymbol: selectedSymbol,
                    onCoinSelected: _onSymbolChanged,
                    chartPanel: const ChartPanel(),
                    orderPanel: const OrderPanel(),
                    bottomTabs: const BottomTabs(),
                  ),
                ),
                
                // 호가+주문 패널
                const TradeBottomSection(),
                
                // AI 코치 카드
                const SizedBox(height: 16),
                const AICoachCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
