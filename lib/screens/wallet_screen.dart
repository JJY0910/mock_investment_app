// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_quotes_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';

/// 모의지갑 화면
class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '모의지갑',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '※ 본 자산은 모의투자용 가상 자산이며, 실제 금전적 가치가 없습니다.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildHoldingsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 요약 카드 (총자산, 현금, 평가손익)
  Widget _buildSummaryCards() {
    return Consumer3<PortfolioProvider, MarketQuotesProvider, ExchangeRateProvider>(
      builder: (context, portfolioProvider, quotesProvider, exchangeRateProvider, child) {
        // 현재가 맵 생성 (USDT → KRW 환산)
        final priceMap = <String, double>{};
        for (var holding in portfolioProvider.holdings) {
          final symbol = '${holding.base}USDT';
          final quote = quotesProvider.getQuote(symbol);
          if (quote != null) {
            priceMap[holding.pairKey] = exchangeRateProvider.usdtToKrw(quote.lastPrice);
          }
        }

        final totalValue = portfolioProvider.getTotalValueKrw(priceMap);
        final cash = portfolioProvider.cashKrw;
        final pnl = portfolioProvider.getTotalPnlKrw(priceMap);
        final pnlPercent = portfolioProvider.getTotalPnlPercent(priceMap);
        final isPnlPositive = pnl >= 0;

        return Column(
          children: [
            // 총자산
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('총자산', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      CoinFormatters.formatKrw(totalValue),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 현금 & 평가손익
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('보유 현금', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            CoinFormatters.formatKrw(cash),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('평가손익', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                CoinFormatters.formatKrw(pnl), // pnl.abs() 제거 가능, 음수면 -₩, formatKrw가 알아서 함. 하지만 formatKrw는 -부호 처리. 사용자 요청 pnl.abs() 였나? 
                                // 기존 코드는 pnl.abs() 였음. '₩' + abs() 하고 색상으로 구분.
                                // formatKrw는 음수면 '-₩1,000'.
                                // 여기서는 색상이 있으므로 부호 없이 숫자만? 아니면 부호 포함?
                                // 보통 PNL은 +₩1,000 / -₩1,000 이렇게 씀.
                                // formatKrw는 음수 부호를 앞에 붙임.
                                // 기존 코드: Text('₩' + pnl.abs ... color: red) -> 빨간색으로 ₩1,000 
                                // 이렇게 하면 마이너스 부호가 표시 안됨 (색상으로만).
                                // 일반적으로는 -₩1,000 라고 쓰는게 명확함.
                                // formatKrw 사용하면 됨.
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isPnlPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CoinFormatters.formatPercent(pnlPercent),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isPnlPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reset 버튼
            ElevatedButton.icon(
              onPressed: () => _showResetDialog(context, portfolioProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('모의지갑 초기화'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 보유 코인 리스트
  Widget _buildHoldingsList() {
    return Consumer3<PortfolioProvider, MarketQuotesProvider, ExchangeRateProvider>(
      builder: (context, portfolioProvider, quotesProvider, exchangeRateProvider, child) {
        final holdings = portfolioProvider.holdings;

        if (holdings.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      '보유 중인 자산이 없습니다',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"/trade" 화면에서 가상 매수/매도를 진행하세요',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보유 자산',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holdings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final holding = holdings[index];
                final symbol = '${holding.base}USDT';
                final quote = quotesProvider.getQuote(symbol);
                final currentPrice = quote != null
                    ? exchangeRateProvider.usdtToKrw(quote.lastPrice)
                    : holding.avgPriceKrw;

                final evalValue = holding.evaluateKrw(currentPrice);
                final pnl = holding.calculatePnlKrw(currentPrice);
                final pnlPercent = holding.calculatePnlPercent(currentPrice);
                final isPnlPositive = pnl >= 0;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        holding.base.substring(0, 1),
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      holding.base,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '수량: ${CoinFormatters.formatQuantity(holding.quantity)} | 평단: ${CoinFormatters.formatKrw(holding.avgPriceKrw)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CoinFormatters.formatKrw(evalValue),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${CoinFormatters.formatKrw(pnl)} (${CoinFormatters.formatPercent(pnlPercent)})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPnlPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// 초기화 확인 다이얼로그
  void _showResetDialog(BuildContext context, PortfolioProvider portfolioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모의지갑 초기화'),
        content: const Text('모든 보유 자산과 거래 내역이 삭제되고\n초기 자본금(₩1,000,000)으로 복구됩니다.\n\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              portfolioProvider.resetToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모의지갑이 초기화되었습니다')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
