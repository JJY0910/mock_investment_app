import 'package:flutter/material.dart';
import 'market_side_panel.dart';

/// 트랩클 거래소 메인 레이아웃 (반응형) - FIXED
class TradeLayout extends StatelessWidget {
  final String selectedSymbol;
  final Function(String) onCoinSelected;
  final Widget chartPanel;
  final Widget orderPanel;
  final Widget bottomTabs;

  const TradeLayout({
    Key? key,
    required this.selectedSymbol,
    required this.onCoinSelected,
    required this.chartPanel,
    required this.orderPanel,
    required this.bottomTabs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return _buildDesktopLayout();
    } else if (screenWidth >= 900) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // Desktop Layout (>=1200px) - FIXED: No Expanded inside
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측 메인 영역 (70%)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 차트 패널 (고정 높이)
                SizedBox(
                  height: 420,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: chartPanel,
                  ),
                ),
                // 주문 패널
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: orderPanel,
                ),
                const SizedBox(height: 16),
                // 하단 탭
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: bottomTabs,
                ),
              ],
            ),
          ),
        ),
        // 우측 사이드바 (30%)
        SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarketSidePanel(
              onCoinSelected: onCoinSelected,
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Layout (900~1199px)
  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측 영역 (60%)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 380,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: chartPanel,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: orderPanel,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: bottomTabs,
                ),
              ],
            ),
          ),
        ),
        // 우측 영역 (40%)
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarketSidePanel(
              onCoinSelected: onCoinSelected,
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Layout (<900px) - FIXED: SizedBox instead of Expanded for TabBarView
  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 차트 (고정 높이)
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: chartPanel,
            ),
          ),
          // 하단 탭 바
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: '주문'),
                Tab(text: '내역'),
                Tab(text: '마켓'),
              ],
            ),
          ),
          // 탭 내용 (고정 높이)
          SizedBox(
            height: 400, // FIXED: No Expanded, use fixed height
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: orderPanel,
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: bottomTabs,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarketSidePanel(
                    onCoinSelected: onCoinSelected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
