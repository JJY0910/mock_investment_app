import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/coin_info.dart';
import '../../../data/coin_registry.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/market_quotes_provider.dart';
import '../../../providers/exchange_rate_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../utils/formatters.dart';

/// 마켓 사이드 패널 (우측)
/// 탭 3개: 원화 / 보유 / 관심
/// 검색, 즐겨찾기 기능 포함
class MarketSidePanel extends StatefulWidget {
  final Function(String)? onCoinSelected;

  const MarketSidePanel({Key? key, this.onCoinSelected}) : super(key: key);

  @override
  State<MarketSidePanel> createState() => _MarketSidePanelState();
}

class _MarketSidePanelState extends State<MarketSidePanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final CoinRegistry _coinRegistry = CoinRegistry();
  
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    
    // 시세 데이터 1회 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quotesProvider = Provider.of<MarketQuotesProvider>(context, listen: false);
      if (quotesProvider.quotesBySymbol.isEmpty && !quotesProvider.loading) {
        quotesProvider.loadOnce();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 탭 바
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
              indicatorColor: Colors.blue,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: '원화'),
                Tab(text: '보유'),
                Tab(text: '관심'),
              ],
            ),
          ),

          // 탭 내용
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKRWMarketList(),
                _buildHoldingsList(),
                _buildFavoritesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 원화 마켓 리스트
  Widget _buildKRWMarketList() {
    return Column(
      children: [
        // 검색 바 + 즐겨찾기 필터
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // 검색 입력
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '코인 검색...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              
              // 즐겨찾기만 보기 토글
              Tooltip(
                message: '즐겨찾기만 보기',
                child: IconButton(
                  icon: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_border,
                    color: _showFavoritesOnly ? Colors.amber : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                  },
                ),
              ),
            ],
          ),
        ),

        // 코인 리스트
        Expanded(
          child: Consumer3<FavoritesProvider, MarketQuotesProvider, ExchangeRateProvider>(
            builder: (context, favoritesProvider, quotesProvider, exchangeRateProvider, child) {
              // 로딩 상태
              if (quotesProvider.loading && quotesProvider.quotesBySymbol.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        '시세 정보를 불러오는 중...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              // 에러 상태
              if (quotesProvider.error != null && quotesProvider.quotesBySymbol.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        quotesProvider.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => quotesProvider.retry(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }

              // 필터링된 코인 목록
              final coins = _getFilteredCoins(favoritesProvider);

              if (coins.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? '검색 결과가 없습니다'
                        : _showFavoritesOnly
                            ? '즐겨찾기한 코인이 없습니다'
                            : '코인 목록이 없습니다',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: coins.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final coin = coins[index];
                  final isFavorite = favoritesProvider.isFavorite(coin.pairKey);
                  
                  // 실제 시세 데이터 가져오기
                  final symbol = '${coin.base}USDT';
                  final quote = quotesProvider.getQuote(symbol);
                  
                  // 가격: 실제 시세가 있으면 USDT→KRW 환산, 없으면 placeholder
                  final displayPrice = quote != null 
                      ? exchangeRateProvider.usdtToKrw(quote.lastPrice) 
                      : coin.currentPrice ?? 0;
                  
                  // 등락률: 실제 시세가 있으면 사용, 없으면 placeholder
                  final changePercent = quote?.priceChangePercent ?? coin.change24h ?? 0;
                  final isPositive = changePercent >= 0;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            coin.displayName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 즐겨찾기 버튼
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.grey,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            favoritesProvider.toggleFavorite(coin.pairKey);
                          },
                        ),
                      ],
                    ),
                    subtitle: Text(
                      coin.base,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₩${CoinFormatters.formatPrice(displayPrice, decimals: 0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          CoinFormatters.formatPercent(changePercent),
                          style: TextStyle(
                            fontSize: 10,
                            color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (widget.onCoinSelected != null) {
                        widget.onCoinSelected!('${coin.base}USDT');
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${coin.displayName} 선택'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 필터링된 코인 목록 가져오기
  List<CoinInfo> _getFilteredCoins(FavoritesProvider favoritesProvider) {
    List<CoinInfo> coins = _coinRegistry.getKrwMarket();

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      coins = coins.where((coin) {
        final searchLower = _searchQuery.toLowerCase();
        return coin.displayName.toLowerCase().contains(searchLower) ||
               coin.base.toLowerCase().contains(searchLower) ||
               coin.symbol.toLowerCase().contains(searchLower);
      }).toList();
    }

    // 즐겨찾기 필터
    if (_showFavoritesOnly) {
      coins = coins.where((coin) => favoritesProvider.isFavorite(coin.pairKey)).toList();
    }

    return coins;
  }

  // 보유 리스트
  Widget _buildHoldingsList() {
    return Consumer3<PortfolioProvider, MarketQuotesProvider, ExchangeRateProvider>(
      builder: (context, portfolioProvider, quotesProvider, exchangeRateProvider, child) {
        final holdings = portfolioProvider.holdings;

        if (holdings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  '보유 중인 자산이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: holdings.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
          itemBuilder: (context, index) {
            final holding = holdings[index];
            
            // 실제 시세 데이터 가져오기
            final symbol = '${holding.base}USDT';
            final quote = quotesProvider.getQuote(symbol);
            final currentPrice = quote != null
                ? exchangeRateProvider.usdtToKrw(quote.lastPrice)
                : holding.avgPriceKrw;

            final evalValue = holding.evaluateKrw(currentPrice);
            final pnl = holding.calculatePnlKrw(currentPrice);
            final pnlPercent = holding.calculatePnlPercent(currentPrice);
            final isPnlPositive = pnl >= 0;

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(
                holding.base,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '수량: ${holding.quantity.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${CoinFormatters.formatPrice(evalValue, decimals: 0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${isPnlPositive ? '+' : ''}${CoinFormatters.formatPercent(pnlPercent)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isPnlPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 관심 리스트 (즐겨찾기한 코인 표시)
  /// [보강 5] 관심 탭에도 실제 시세 표시
  Widget _buildFavoritesList() {
    return Consumer3<FavoritesProvider, MarketQuotesProvider, ExchangeRateProvider>(
      builder: (context, favoritesProvider, quotesProvider, exchangeRateProvider, child) {
        final favoriteCoins = _coinRegistry
            .getKrwMarket()
            .where((coin) => favoritesProvider.isFavorite(coin.pairKey))
            .toList();

        if (favoriteCoins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  '관심 종목이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '원화 탭에서 ⭐ 버튼을 눌러 추가하세요',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: favoriteCoins.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
          itemBuilder: (context, index) {
            final coin = favoriteCoins[index];
            
            // 실제 시세 데이터 가져오기
            final symbol = '${coin.base}USDT';
            final quote = quotesProvider.getQuote(symbol);
            
            // 가격: 실제 시세가 있으면 USDT→KRW 환산, 없으면 placeholder
            final displayPrice = quote != null 
                ? exchangeRateProvider.usdtToKrw(quote.lastPrice) 
                : coin.currentPrice ?? 0;
            
            // 등락률: 실제 시세가 있으면 사용, 없으면 placeholder
            final changePercent = quote?.priceChangePercent ?? coin.change24h ?? 0;
            final isPositive = changePercent >= 0;

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(
                coin.displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                coin.base,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${CoinFormatters.formatPrice(displayPrice, decimals: 0)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CoinFormatters.formatPercent(changePercent),
                    style: TextStyle(
                      fontSize: 11,
                      color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (widget.onCoinSelected != null) {
                  widget.onCoinSelected!('${coin.base}USDT');
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${coin.displayName} 선택'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
class AppColors {
  static const up = Color(0xFF10b981); // Green
  static const down = Color(0xFFef4444); // Red
}
