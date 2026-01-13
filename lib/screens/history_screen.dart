// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trade_history_provider.dart';
import '../models/trade_fill.dart';
import '../utils/formatters.dart';

/// 체결 내역 화면
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // 'all', 'buy', 'sell'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투자 내역'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '내역 전체 삭제',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 모의투자 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey.withOpacity(0.1),
            child: const Text(
              '※ 모의투자 기록입니다',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 필터
          _buildFilterBar(),
          
          // 리스트
          Expanded(
            child: Consumer<TradeHistoryProvider>(
              builder: (context, provider, child) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final fils = provider.fills.where((f) {
                  if (_filter == 'all') return true;
                  return f.side == _filter;
                }).toList();

                if (fils.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '체결 내역이 없습니다',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: fils.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final fill = fils[index];
                    return _buildHistoryItem(fill);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          _buildFilterChip('전체', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('매수', 'buy'),
          const SizedBox(width: 8),
          _buildFilterChip('매도', 'sell'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildHistoryItem(TradeFill fill) {
    final isBuy = fill.side == 'buy';
    final color = isBuy ? AppColors.up : AppColors.down;
    final dateStr = DateFormat('MM/dd HH:mm:ss').format(fill.time);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isBuy ? Icons.add : Icons.remove,
          color: color,
          size: 20,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fill.base,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            dateStr,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isBuy ? "매수" : "매도"} ${CoinFormatters.formatKrw(fill.priceKrw)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
              Text(
                CoinFormatters.formatKrw(fill.amountKrw),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '수량: ${CoinFormatters.formatQuantity(fill.quantity)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Row(
                children: [
                  if (fill.feeKrw > 0)
                    Text(
                      '수수료: ${CoinFormatters.formatKrw(fill.feeKrw)} ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  Text(
                    fill.source == 'market' ? '시장가' : '지정가',
                    style: TextStyle(
                      fontSize: 11,
                      color: fill.source == 'market' ? Colors.blue : Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내역 삭제'),
        content: const Text('모든 체결 내역을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      await Provider.of<TradeHistoryProvider>(context, listen: false).clearHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체결 내역이 삭제되었습니다')),
      );
    }
  }
}

class AppColors {
  static const up = Color(0xFF10b981);
  static const down = Color(0xFFef4444);
}
