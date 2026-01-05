import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mock_investment_app/services/price_service.dart';
import '../providers/price_provider.dart';
import '../widgets/responsive_layout.dart';
import '../config/constants.dart';
import 'package:intl/intl.dart';

// 메인 대시보드 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 감시할 종목 목록 (심볼 -> 자산 유형)
  final Map<String, String> _watchlist = {
    'XRP': AppConstants.assetTypeCrypto,
    'BTC': AppConstants.assetTypeCrypto,
    'SQQQ': AppConstants.assetTypeStock,
    'TQQQ': AppConstants.assetTypeStock,
  };

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 시세 업데이트 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final priceProvider = Provider.of<PriceProvider>(context, listen: false);
      priceProvider.startPeriodicUpdate(_watchlist);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모의 투자 트레이더'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          // 포트폴리오 가치 표시 (추후 구현)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '${AppConstants.currencySymbol}100,000,000',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdResetDialog,
        icon: const Icon(Icons.live_tv),
        label: const Text('광고 보고 리셋'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 모바일 레이아웃 (세로 스크롤)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 20),
          _buildPriceListWidget(),
          const SizedBox(height: 20),
          _buildTopTradersPreview(),
        ],
      ),
    );
  }

  // 데스크톱 레이아웃 (3단 구조)
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 차트 영역 (40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 16),
                Expanded(child: _buildChartPlaceholder()),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // 중앙: 시세 및 호가창 (30%)
          Expanded(
            flex: 3,
            child: _buildPriceListWidget(),
          ),
          const SizedBox(width: 16),
          
          // 오른쪽: 고수 랭킹 (30%)
          Expanded(
            flex: 3,
            child: _buildTopTradersPreview(),
          ),
        ],
      ),
    );
  }

  // 잔고 카드
  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 자산',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '₩100,000,000',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('수익률', '+0.00%', Colors.greenAccent),
                _buildStatItem('현금', '₩100,000,000', Colors.white70),
                _buildStatItem('투자금', '₩0', Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 실시간 시세 리스트
  Widget _buildPriceListWidget() {
    return Consumer<PriceProvider>(
      builder: (context, priceProvider, child) {
        if (priceProvider.isLoading && priceProvider.prices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Card(
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '실시간 시세',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (priceProvider.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _watchlist.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final symbol = _watchlist.keys.elementAt(index);
                    final assetType = _watchlist[symbol]!;
                    final price = priceProvider.getPriceBySymbol(symbol);

                    return _buildPriceListItem(symbol, assetType, price);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceListItem(String symbol, String assetType, AssetPrice? price) {
    final currencyFormat = NumberFormat('#,###');
    final isPositive = (price?.changePercent ?? 0) >= 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: assetType == AppConstants.assetTypeCrypto
            ? Colors.orange.shade100
            : Colors.blue.shade100,
        child: Text(
          symbol.substring(0, 1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: assetType == AppConstants.assetTypeCrypto
                ? Colors.orange
                : Colors.blue,
          ),
        ),
      ),
      title: Text(
        symbol,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        assetType == AppConstants.assetTypeCrypto ? '암호화폐' : '주식',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: price != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppConstants.currencySymbol}${currencyFormat.format(price.price)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${price.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
              ],
            )
          : const Text(
              '로딩 중...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
    );
  }

  // 차트 Placeholder (향후 구현)
  Widget _buildChartPlaceholder() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '차트 영역 (향후 구현)',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // 고수 랭킹 미리보기
  Widget _buildTopTradersPreview() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Text(
              '상위 50% 고수 랭킹',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '상위 트레이더 목록\n(향후 구현)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 광고 리셋 다이얼로그
  void _showAdResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 시청 후 잔고 리셋'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('광고를 시청하면 잔고가 1억 원으로 리셋됩니다.'),
            const SizedBox(height: 16),
            
            // ⭐ Google AdSense Placeholder (실제 광고 영역)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tv, size: 48, color: Colors.orange[700]),
                  const SizedBox(height: 16),
                  Text(
                    '🎬 광고 영역',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google AdSense 스크립트가\n여기에 삽입됩니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '※ 현재는 광고 Placeholder입니다.\nAdSense 승인 후 실제 광고가 표시됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('잔고가 1억 원으로 리셋되었습니다! (시뮬레이션)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('광고 시청 완료'),
          ),
        ],
      ),
    );
  }
}
