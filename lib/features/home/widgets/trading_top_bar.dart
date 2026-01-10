import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/theme_provider.dart';

class TradingTopBar extends StatefulWidget {
  final String selectedSymbol;
  final Function(String?) onSymbolChanged;

  const TradingTopBar({
    Key? key,
    required this.selectedSymbol,
    required this.onSymbolChanged,
  }) : super(key: key);

  @override
  State<TradingTopBar> createState() => _TradingTopBarState();
}

class _TradingTopBarState extends State<TradingTopBar> {
  String _selectedTimeframe = '1m';

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceProvider>(
      builder: (context, priceProvider, _) {
        final assetPrice = priceProvider.getPriceBySymbol(widget.selectedSymbol);
        final price = assetPrice?.price ?? 0.0;
        final changePercent = assetPrice?.changePercent ?? 0.0;
        final isPositive = changePercent >= 0;

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
                  ? _buildMobileLayout(price, changePercent, isPositive)
                  : _buildDesktopLayout(price, changePercent, isPositive),
            );
          },
        );
      },
    );
  }

  // Desktop/Tablet Layout (single row)
  Widget _buildDesktopLayout(double price, double changePercent, bool isPositive) {
    return Row(
      children: [
        // Symbol Dropdown
        _buildSymbolDropdown(18),
        const SizedBox(width: 24),

        // Current Price
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 16),

        // 24h Change
        _buildChangeChip(changePercent, isPositive),

        const Spacer(),

        // Timeframe Buttons (Desktop)
        Row(
          children: ['1m', '5m', '15m', '1h'].map((tf) {
            final isSelected = tf == _selectedTimeframe;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => setState(() => _selectedTimeframe = tf),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue[50] : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Theme Toggle Button
        const SizedBox(width: 8),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onPressed: () => themeProvider.toggle(),
              tooltip: themeProvider.isDark ? '라이트 모드' : '다크 모드',
            );
          },
        ),
      ],
    );
  }

  // Mobile Layout (2 rows)
  Widget _buildMobileLayout(double price, double changePercent, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Symbol + Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSymbolDropdown(16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Change + Timeframe Dropdown + Theme Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildChangeChip(changePercent, isPositive),
            const SizedBox(width: 12),
            _buildTimeframeDropdown(),
            const SizedBox(width: 8),
            // Theme Toggle Button (Mobile)
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    size: 20,
                  ),
                  onPressed: () => themeProvider.toggle(),
                  tooltip: themeProvider.isDark ? '라이트 모드' : '다크 모드',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // Symbol Dropdown Widget
  Widget _buildSymbolDropdown(double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: widget.selectedSymbol,
        underline: const SizedBox(),
        isDense: true,
        items: ['BTCUSDT', 'ETHUSDT', 'XRPUSDT']
            .map((symbol) => DropdownMenuItem(
                  value: symbol,
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ))
            .toList(),
        onChanged: widget.onSymbolChanged,
      ),
    );
  }

  // Change Chip Widget
  Widget _buildChangeChip(double changePercent, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF10b981).withOpacity(0.1)
            : const Color(0xFFef4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Timeframe Dropdown (Mobile)
  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeframe,
        underline: const SizedBox(),
        isDense: true,
        items: ['1m', '5m', '15m', '1h']
            .map((tf) => DropdownMenuItem(
                  value: tf,
                  child: Text(
                    tf,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimeframe = value);
          }
        },
      ),
    );
  }
}
