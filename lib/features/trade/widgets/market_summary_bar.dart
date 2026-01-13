// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/exchange_rate_provider.dart';
import '../../../providers/selected_coin_provider.dart';
import '../../../utils/formatters.dart';

/// 시세 요약 바 (헤더 아래)
/// 선택 코인, 현재가, 등락률, 타임프레임, '모의투자' 배지 표시
/// 마켓인사이트/설정 아이콘 제외
class MarketSummaryBar extends StatelessWidget {
  const MarketSummaryBar({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Consumer3<SelectedCoinProvider, PriceProvider, ExchangeRateProvider>(
      builder: (context, selectedCoinProvider, priceProvider, exchangeRateProvider, _) {
        final selectedCoin = selectedCoinProvider.selectedCoin;
        final selectedSymbol = selectedCoin != null ? '${selectedCoin.base}USDT' : 'BTCUSDT';
        final assetPrice = priceProvider.getPriceBySymbol(selectedSymbol);
        
        // Data Integrity Check
        final hasData = assetPrice != null && assetPrice.price > 0;
        final usdtPrice = assetPrice?.price ?? 0.0;
        final changePercent = assetPrice?.changePercent ?? 0.0;
        final isPositive = changePercent >= 0;
        
        // KRW 변환
        final krwPrice = exchangeRateProvider.usdtToKrw(usdtPrice);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 420;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: isMobile
                  ? _buildMobileLayout(selectedCoin, hasData, krwPrice, changePercent, isPositive)
                  : _buildDesktopLayout(selectedCoin, hasData, krwPrice, changePercent, isPositive),
            );
          },
        );
      },
    );
  }

  // Desktop Layout (업비트 스타일)
  Widget _buildDesktopLayout(dynamic selectedCoin, bool hasData, double price, double changePercent, bool isPositive) {
    final coinName = selectedCoin?.name ?? 'Bitcoin';
    final coinSymbol = selectedCoin?.base ?? 'BTC';
    
    // 등락금액 계산
    final changeAmount = hasData ? (price * changePercent / 100) : 0.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌: 코인명 + 심볼 세로 배치
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              coinName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '$coinSymbol/KRW',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                _buildMockTradingBadge(),
              ],
            ),
          ],
        ),
        const SizedBox(width: 48),

        // 중: 현재가 (가장 크게)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasData ? CoinFormatters.formatKrw(price) : '—',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: hasData 
                    ? (isPositive ? const Color(0xFFD24F45) : const Color(0xFF1261C4))
                    : Colors.grey,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            // 전일대비 텍스트
            if (hasData)
              Row(
                children: [
                  Text(
                    '전일대비',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CoinFormatters.formatPercent(changePercent),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? const Color(0xFFD24F45) : const Color(0xFF1261C4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isPositive ? '+' : ''}${CoinFormatters.formatKrw(changeAmount.abs())}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? const Color(0xFFD24F45) : const Color(0xFF1261C4),
                    ),
                  ),
                ],
              ),
          ],
        ),

        const Spacer(),
      ],
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(dynamic selectedCoin, bool hasData, double price, double changePercent, bool isPositive) {
    final coinName = selectedCoin?.name ?? 'Bitcoin';
    final coinSymbol = selectedCoin?.base ?? 'BTC';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: 코인명 + 심볼 + 배지
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coinName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  coinSymbol,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 12),
            _buildMockTradingBadge(),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Price + Change
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasData ? CoinFormatters.formatKrw(price) : '—',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasData
                    ? (isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444))
                    : Colors.grey,
              ),
            ),
            if (hasData)
              _buildChangeChip(changePercent, isPositive),
          ],
        ),
      ],
    );
  }

  // 모의투자 배지
  Widget _buildMockTradingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: const Text(
        '모의투자',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  // Change Chip
  Widget _buildChangeChip(double changePercent, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF10b981).withOpacity(0.1)
            : const Color(0xFFef4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        CoinFormatters.formatPercent(changePercent),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
        ),
      ),
    );
  }
}
