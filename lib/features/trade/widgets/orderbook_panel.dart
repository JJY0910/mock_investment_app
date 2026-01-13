import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/coin_info.dart';
import '../../../providers/selected_coin_provider.dart';
import '../../../providers/exchange_rate_provider.dart';
import '../../../core/color_utils.dart';
import '../../../services/binance_rest_service.dart';

/// 호가 패널 - 시장 호가 데이터 표시
class OrderbookPanel extends StatefulWidget {
  const OrderbookPanel({Key? key}) : super(key: key);

  @override
  State<OrderbookPanel> createState() => _OrderbookPanelState();
}

class _OrderbookPanelState extends State<OrderbookPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BinanceRestService _binanceRest = BinanceRestService();
  
  OrderBook? _orderBook;
  String? _currentSymbol;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchOrderBookData(String symbol) async {
    if (_currentSymbol == symbol || _isLoading) return;
    
    setState(() {
      _currentSymbol = symbol;
      _isLoading = true;
    });

    try {
      final orderBook = await _binanceRest.fetchOrderBook(
        symbol: symbol,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _orderBook = orderBook;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[OrderbookPanel] Error fetching order book: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedCoinProvider, ExchangeRateProvider>(
      builder: (context, selectedCoin, exchangeRate, _) {
        final coin = selectedCoin.selectedCoin;
        
        // 코인 변경 시 order book 데이터 요청
        if (coin != null) {
          final symbol = '${coin.base}USDT';
          if (_currentSymbol != symbol) {
            Future.microtask(() => _fetchOrderBookData(symbol));
          }
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 탭 바
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue,
                  indicatorWeight: 2,
                  tabs: const [
                    Tab(text: '일반호가'),
                    Tab(text: '누적호가'),
                    Tab(text: '호가주문'),
                    Tab(text: '모아보기'),
                  ],
                ),
              ),
              
              // 호가 리스트 영역 (고정 높이 + 내부 스크롤)
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildOrderbookList(coin, exchangeRate),
                    _buildCumulativeOrderbook(coin, exchangeRate),
                    const Center(child: Text('호가주문 (TODO)', style: TextStyle(color: Colors.grey))),
                    const Center(child: Text('모아보기 (TODO)', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 일반호가 리스트
  Widget _buildOrderbookList(CoinInfo? coin, ExchangeRateProvider exchangeRate) {
    if (coin == null) {
      return Center(
        child: Text(
          '코인을 선택하세요',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (_orderBook == null) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(color: Colors.grey[600], fontSize: 24),
        ),
      );
    }

    // 매도 호가 (asks) - 가격 오름차순 (낮은 가격부터)
    final asks = _orderBook!.asks.take(10).toList();
    // 매수 호가 (bids) - 가격 내림차순 (높은 가격부터)
    final bids = _orderBook!.bids.take(10).toList();
    
    // 매도 + 매수 합치기 (매도 역순으로 표시)
    final combinedOrders = [
      ...asks.reversed.map((ask) => {'entry': ask, 'isAsk': true}),
      ...bids.map((bid) => {'entry': bid, 'isAsk': false}),
    ];

    return ListView.builder(
      itemCount: combinedOrders.length,
      itemBuilder: (context, index) {
        final order = combinedOrders[index];
        final entry = order['entry'] as OrderBookEntry;
        final isAsk = order['isAsk'] as bool;
        
        // USDT → KRW 환산
        final priceKrw = exchangeRate.usdtToKrw(entry.price);
        final quantity = entry.quantity;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isAsk 
              ? withOpacityCompat(Colors.red, 0.05)
              : withOpacityCompat(Colors.blue, 0.05),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              // 가격 (KRW)
              Expanded(
                flex: 2,
                child: Text(
                  '₩${priceKrw.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: TextStyle(
                    color: isAsk ? const Color(0xFFD24F45) : const Color(0xFF1261C4),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // 수량
              Expanded(
                flex: 1,
                child: Text(
                  quantity.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 누적호가 (TODO)
  Widget _buildCumulativeOrderbook(CoinInfo? coin, ExchangeRateProvider exchangeRate) {
    return Center(
      child: Text(
        '누적호가 (TODO)',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}
