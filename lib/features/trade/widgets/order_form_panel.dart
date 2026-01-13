import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/coin_info.dart';
import '../../../providers/selected_coin_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/exchange_rate_provider.dart';
import '../../../providers/price_provider.dart';
import '../../../utils/formatters.dart';

/// 주문 폼 패널 - 매수/매도 주문 입력
class OrderFormPanel extends StatefulWidget {
  const OrderFormPanel({Key? key}) : super(key: key);

  @override
  State<OrderFormPanel> createState() => _OrderFormPanelState();
}

class _OrderFormPanelState extends State<OrderFormPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _orderType = '지정가'; // 지정가, 시장가, 예약-지정가
  bool _isBuy = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    if (_tabController.index == 0) {
      setState(() => _isBuy = true);
    } else if (_tabController.index == 1) {
      setState(() => _isBuy = false);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<SelectedCoinProvider, PortfolioProvider, ExchangeRateProvider, PriceProvider>(
      builder: (context, selectedCoinProvider, portfolioProvider, exchangeRateProvider, priceProvider, child) {
        final coin = selectedCoinProvider.selectedCoin;
        final cashKrw = portfolioProvider.cashKrw;
        final currentPriceUsdt = coin != null ? priceProvider.getPrice('${coin.base}USDT') : 0.0;
        final currentPriceKrw = exchangeRateProvider.usdtToKrw(currentPriceUsdt ?? 0.0);
        
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
                  labelColor: _isBuy ? const Color(0xFFD24F45) : const Color(0xFF1261C4),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: _isBuy ? const Color(0xFFD24F45) : const Color(0xFF1261C4),
                  indicatorWeight: 2,
                  tabs: const [
                    Tab(text: '매수'),
                    Tab(text: '매도'),
                    Tab(text: '간편주문'),
                    Tab(text: '거래내역'),
                  ],
                ),
              ),
              
              // 주문 폼 영역 (고정 높이 + 내부 스크롤)
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildOrderForm(coin, cashKrw, currentPriceKrw, isBuy: true),
                    _buildOrderForm(coin, cashKrw, currentPriceKrw, isBuy: false),
                    const Center(child: Text('간편주문 (준비 중)', style: TextStyle(color: Colors.grey))),
                    const Center(child: Text('거래내역 (준비 중)', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 주문 폼
  Widget _buildOrderForm(CoinInfo? coin, double cashKrw, double currentPriceKrw, {required bool isBuy}) {
    if (coin == null) {
      return Center(
        child: Text(
          '코인을 선택하세요',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final activeColor = isBuy ? const Color(0xFF10b981) : const Color(0xFFef4444);
    final price = _priceController.text.isEmpty ? 0.0 : double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
    final amount = _amountController.text.isEmpty ? 0.0 : double.tryParse(_amountController.text) ?? 0.0;
    final totalKrw = price * amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 주문 유형
          Row(
            children: [
              Text(
                '주문유형',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.help_outline, size: 14, color: Colors.grey[500]),
              const Spacer(),
              _buildTypeButton('지정가'),
              const SizedBox(width: 8),
              _buildTypeButton('시장가'),
              const SizedBox(width: 8),
              _buildTypeButton('예약-지정가'),
            ],
          ),
          const SizedBox(height: 16),

          // 사용가능 현금
          Text(
            '주문가능',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '${CoinFormatters.formatKrw(cashKrw)} KRW',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 매수가격
          Text(
            '매수가격 (KRW)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: currentPriceKrw.toStringAsFixed(0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final current = double.tryParse(_priceController.text.replaceAll(',', '')) ?? currentPriceKrw;
                  _priceController.text = (current - 1000).toStringAsFixed(0);
                },
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              IconButton(
                onPressed: () {
                  final current = double.tryParse(_priceController.text.replaceAll(',', '')) ?? currentPriceKrw;
                  _priceController.text = (current + 1000).toStringAsFixed(0);
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주문수량
          Text(
            '주문수량 (${coin.base})',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // 퍼센트 버튼
          Row(
            children: [
              _buildPercentButton('10%', 0.1, cashKrw, currentPriceKrw),
              const SizedBox(width: 8),
              _buildPercentButton('25%', 0.25, cashKrw, currentPriceKrw),
              const SizedBox(width: 8),
              _buildPercentButton('50%', 0.5, cashKrw, currentPriceKrw),
              const SizedBox(width: 8),
              _buildPercentButton('100%', 1.0, cashKrw, currentPriceKrw),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Text('직접입력', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주문총액
          Text(
            '주문총액 (KRW)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              totalKrw.toStringAsFixed(0),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),

          // 주문 버튼
          ElevatedButton(
            onPressed: () {
              // TODO: 주문 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${isBuy ? "매수" : "매도"} 주문 (준비 중)')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              isBuy ? '매수' : '매도',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    final isActive = _orderType == type;
    return OutlinedButton(
      onPressed: () => setState(() => _orderType = type),
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue[50] : Colors.white,
        side: BorderSide(color: isActive ? Colors.blue : Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.blue : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildPercentButton(String label, double percent, double cashKrw, double currentPriceKrw) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          final availableAmount = cashKrw * percent;
          if (currentPriceKrw > 0) {
            final amount = availableAmount / currentPriceKrw;
            _amountController.text = amount.toStringAsFixed(6);
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ),
    );
  }
}
