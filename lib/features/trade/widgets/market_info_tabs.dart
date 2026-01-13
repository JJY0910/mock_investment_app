import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/coin_info.dart';
import '../../../providers/selected_coin_provider.dart';
import '../../../providers/exchange_rate_provider.dart';
import '../../../providers/price_provider.dart';
import '../../../utils/formatters.dart';
import '../../../services/binance_rest_service.dart';

/// 시세/정보 탭 + 4지표
class MarketInfoTabs extends StatefulWidget {
  const MarketInfoTabs({Key? key}) : super(key: key);

  @override
  State<MarketInfoTabs> createState() => _MarketInfoTabsState();
}

class _MarketInfoTabsState extends State<MarketInfoTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BinanceRestService _binanceRest = BinanceRestService();
  
  Ticker24h? _ticker24h;
  String? _currentSymbol;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchTickerData(String symbol) async {
    if (_currentSymbol == symbol || _isLoading) return;
    
    setState(() {
      _currentSymbol = symbol;
      _isLoading = true;
    });

    try {
      final ticker = await _binanceRest.fetch24hTicker(symbol);
      if (mounted) {
        setState(() {
          _ticker24h = ticker;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[MarketInfoTabs] Error fetching ticker: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SelectedCoinProvider, ExchangeRateProvider, PriceProvider>(
      builder: (context, selectedCoin, exchangeRate, priceProvider, _) {
        final coin = selectedCoin.selectedCoin;
        
        // 코인 변경 시 ticker 데이터 요청
        if (coin != null) {
          final symbol = '${coin.base}USDT';
          if (_currentSymbol != symbol) {
            Future.microtask(() => _fetchTickerData(symbol));
          }
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 탭 바
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.blue,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: '시세'),
                  Tab(text: '정보'),
                ],
              ),
              
              // 탭 뷰 컨텐츠
              SizedBox(
                height: 80,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMarketStats(coin, exchangeRate),
                    const Center(
                      child: Text(
                        '정보 탭은 추후 확장 예정',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 시세 탭 - 4지표
  Widget _buildMarketStats(
    CoinInfo? coin,
    ExchangeRateProvider exchangeRate,
  ) {
    if (coin == null || _ticker24h == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('고가', '—')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('저가', '—')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('거래량(24H)', '—')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('거래대금(24H)', '—')),
          ],
        ),
      );
    }

    // Binance 24hr Ticker 데이터를 KRW로 환산
    final highKrw = exchangeRate.usdtToKrw(_ticker24h!.highPrice);
    final lowKrw = exchangeRate.usdtToKrw(_ticker24h!.lowPrice);
    final volume24h = _ticker24h!.volume; // BTC 기준
    final quoteVolume = _ticker24h!.highPrice * _ticker24h!.volume; // USDT 기준 거래대금
    final turnover24hKrw = exchangeRate.usdtToKrw(quoteVolume);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('고가', CoinFormatters.formatKrw(highKrw))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('저가', CoinFormatters.formatKrw(lowKrw))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('거래량(24H)', '${volume24h.toStringAsFixed(4)} ${coin.base}')),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('거래대금(24H)', CoinFormatters.formatKrw(turnover24hKrw))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
