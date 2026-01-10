import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/price_provider.dart';

class CompactBalanceCard extends StatelessWidget {
  const CompactBalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceProvider>(
      builder: (context, priceProvider, _) {
        final totalAssets = priceProvider.totalAssets;
        final cash = priceProvider.cash;
        final estimatedValue = priceProvider.estimatedValue;
        final profitLoss = estimatedValue - (totalAssets - cash);
        final profitLossPercent =
            totalAssets > 0 ? (profitLoss / totalAssets) * 100 : 0.0;
        final isProfit = profitLoss >= 0;

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
                Text(
                  '내 자산',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),

                // Total Assets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 자산',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${totalAssets.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Cash
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '현금',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${cash.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Profit/Loss
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '평가손익',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isProfit
                            ? const Color(0xFF10b981)
                            : const Color(0xFFef4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Return %
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '수익률',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isProfit
                            ? const Color(0xFF10b981)
                            : const Color(0xFFef4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
