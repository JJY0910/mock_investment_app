import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/price_provider.dart';
import '../features/home/widgets/chart_panel.dart';
import '../features/home/widgets/trading_top_bar.dart';
import '../features/home/widgets/compact_balance_card.dart';
import '../features/home/widgets/order_panel.dart';
import '../features/home/widgets/bottom_tabs.dart';

/// Trading Platform Screen with Chart, Orders, and Balance
class TradeScreen extends StatefulWidget {
  const TradeScreen({Key? key}) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  String _selectedSymbol = 'BTCUSDT';

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

  void _onSymbolChanged(String? symbol) {
    if (symbol != null) {
      setState(() => _selectedSymbol = symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              // Top Bar
              TradingTopBar(
                selectedSymbol: _selectedSymbol,
                onSymbolChanged: _onSymbolChanged,
              ),

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

                // Order Panel
                const OrderPanel(),
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
          TradingTopBar(
            selectedSymbol: _selectedSymbol,
            onSymbolChanged: _onSymbolChanged,
          ),

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
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: OrderPanel(),
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
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/rank'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '내 순위',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
      ),
    );
  }
}
