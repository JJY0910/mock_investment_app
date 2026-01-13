import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/price_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../features/home/widgets/chart_panel.dart';
import '../features/trade/widgets/market_summary_bar.dart';
import '../features/home/widgets/compact_balance_card.dart';
import '../features/home/widgets/order_panel.dart';
import '../features/home/widgets/bottom_tabs.dart';

/// Trading Platform Style Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize price updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final priceProvider = Provider.of<PriceProvider>(context, listen: false);
      priceProvider.startPeriodicUpdate({
        'BTCUSDT': 'crypto',
        'ETHUSDT': 'crypto',
        'XRPUSDT': 'crypto',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // Desktop Layout: 2-Column
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (70%)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // Top Bar (MarketSummaryBar replaces TradingTopBar)
              const MarketSummaryBar(),

              // Chart Panel
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ChartPanel(),
                ),
              ),

              // Bottom Tabs
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: BottomTabs(),
              ),
            ],
          ),
        ),

        // Right Column (30%)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Compact Balance Card
                const CompactBalanceCard(),
                const SizedBox(height: 16),

                // Order Panel (Using Provider, no need to pass coin explicitly if it uses Provider internally, 
                // BUT OrderPanel constructor takes selectedCoin. We should pass it or refactor OrderPanel to use Provider strictly.
                // OrderPanel ALREADY uses Provider internally? Let's check OrderPanel definition again.
                // It takes `this.selectedCoin` in constructor. 
                // Ideally it should just listen to provider.
                // For now, I'll pass it from the Consumer above.)
                Consumer<SelectedCoinProvider>(
                  builder: (context, provider, _) => const OrderPanel(),
                ),
                const SizedBox(height: 16),

                // Ranking Card (축소)
                _buildCompactRankingCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Layout: Column
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Bar
          const MarketSummaryBar(),

          // Chart Panel
          const SizedBox(
            height: 400,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ChartPanel(),
            ),
          ),

          // Order Panel (Collapsible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpansionTile(
              title: const Text(
                '주문',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Consumer<SelectedCoinProvider>(
                    builder: (context, provider, _) => const OrderPanel(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Tabs
          const Padding(
            padding: EdgeInsets.all(16),
            child: BottomTabs(),
          ),

          // Compact Balance (mobile)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CompactBalanceCard(),
          ),
        ],
      ),
    );
  }

  // Compact Ranking Card
  Widget _buildCompactRankingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '내 순위',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '상위',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const Text(
                  '50%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
