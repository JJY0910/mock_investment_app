import 'package:flutter/material.dart';
import 'market_side_panel.dart';

/// 트랩클 거래소 메인 레이아웃 (반응형)
/// Breakpoint:
/// - Desktop (>=1200px): 3열 (차트 + 우측패널)
/// - Tablet (900~1199px): 2열
/// - Mobile (<900px): 1열 + 하단 탭
class TradeLayout extends StatelessWidget {
  final String selectedSymbol;
  final Function(String) onCoinSelected; // 콜백 추가
  final Widget chartPanel;
  final Widget orderPanel;
  final Widget bottomTabs;

  const TradeLayout({
    Key? key,
    required this.selectedSymbol,
    required this.onCoinSelected,
    required this.chartPanel,
    required this.orderPanel,
    // balanceCard 제거
    required this.bottomTabs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: Use MediaQuery instead of LayoutBuilder to avoid unbounded constraints
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Breakpoint 기준
    // Desktop: >= 1200px (3열 레이아웃)
    // Tablet: 900~1199px (2열 레이아웃)
    // Mobile: < 900px (1열 + 하단 탭)
    
    if (screenWidth >= 1200) {
      return _buildDesktopLayout();
    } else if (screenWidth >= 900) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // Desktop Layout (>=1200px): [좌측: 차트+주문+탭] | [우측: 마켓패널]
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측 메인 영역 (70%)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // 1. 차트 패널 (높이 고정 또는 Flex)
              SizedBox(
                height: 420,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: chartPanel,
                ),
              ),

              // 2. 주문 패널 (차트 바로 아래)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: orderPanel,
              ),
              const SizedBox(height: 16),

              // 3. 하단 탭 (체결내역/보유자산 등)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: bottomTabs,
              ),
            ],
          ),
        ),

        // 우측 사이드바 (30%): 마켓 리스트 전용
        SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MarketSidePanel(
                  onCoinSelected: onCoinSelected,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Layout (900~1199px): [차트+주문] | [마켓]
  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측 영역 (60%)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 차트 (높이 고정)
                SizedBox(
                  height: 380,
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

        // 우측 영역 (40%): 마켓 패널
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

  // Mobile Layout (<900px): 탭으로 구분
  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // 상단: 차트 (고정 높이)
          SizedBox(
            height: 350,
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
                Tab(text: '주문'), // 주문을 첫 번째로
                Tab(text: '내역'),
                Tab(text: '마켓'),
              ],
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              children: [
                // 탭 1: 주문
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: orderPanel,
                ),

                // 탭 2: 내역 (BottomTabs)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: bottomTabs,
                ),

                // 탭 3: 마켓
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
