import 'package:flutter/material.dart';
import 'orderbook_panel.dart';
import 'order_form_panel.dart';

/// 호가 + 주문 통합 섹션 (2열 레이아웃)
class TradeBottomSection extends StatelessWidget {
  const TradeBottomSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 모바일 (900px 이하): 탭 전환
        if (constraints.maxWidth < 900) {
          return _buildMobileLayout();
        }
        
        // 데스크탑: 2열 레이아웃
        return _buildDesktopLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: 호가 패널
          Expanded(
            flex: 1,
            child: const OrderbookPanel(),
          ),
          const SizedBox(width: 16),
          // 우측: 주문 패널
          Expanded(
            flex: 1,
            child: const OrderFormPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: '호가'),
              Tab(text: '주문'),
            ],
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                const OrderbookPanel(),
                const OrderFormPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
