import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/plan_tier.dart';
import '../services/analytics_service.dart'; // GA4

/// Pricing 페이지
class PricingScreen extends StatelessWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('요금제 선택'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '나에게 맞는 플랜을 선택하세요',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI 코치와 함께 트레이딩 실력을 향상시키세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // 플랜 카드들
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPlanCard(context, PlanTier.free)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPlanCard(context, PlanTier.pro, featured: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPlanCard(context, PlanTier.elite)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildPlanCard(context, PlanTier.free),
                            const SizedBox(height: 16),
                            _buildPlanCard(context, PlanTier.pro, featured: true),
                            const SizedBox(height: 16),
                            _buildPlanCard(context, PlanTier.elite),
                          ],
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 기능 비교 테이블
                  _buildFeatureComparison(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlanCard(BuildContext context, PlanTier tier, {bool featured = false}) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final isCurrentPlan = subscriptionProvider.currentTier == tier;
    
    return Card(
      elevation: featured ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: featured 
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (featured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '인기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (featured) const SizedBox(height: 12),
            
            Text(
              tier.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tier.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tier.monthlyPrice == 0 ? '무료' : '\$${tier.monthlyPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (tier.monthlyPrice > 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '/월',
                      style:TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 기능 목록
            ..._getPlanFeatures(tier).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    feature.included ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: feature.included ? Colors.green : Colors.grey[300],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: feature.included ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan 
                    ? null
                    : () => _handleUpgrade(context, tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: featured ? Colors.blue : Colors.grey[300],
                  foregroundColor: featured ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCurrentPlan ? '현재 플랜' : '선택하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기능 비교',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildComparisonRow('기본 거래', true, true, true),
            _buildComparisonRow('점수 시스템', true, true, true),
            _buildComparisonRow('배지', true, true, true),
            _buildComparisonRow('AI 코치 (요약)', true, true, true),
            _buildComparisonRow('AI 코치 (상세)', false, true, true),
            _buildComparisonRow('Daily 메시지', false, true, true),
            _buildComparisonRow('Weekly 리포트', false, false, true),
            _buildComparisonRow('패턴 탐지', false, false, true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonRow(String feature, bool free, bool pro, bool elite) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(child: _buildCheckIcon(free)),
          Expanded(child: _buildCheckIcon(pro)),
          Expanded(child: _buildCheckIcon(elite)),
        ],
      ),
    );
  }
  
  Widget _buildCheckIcon(bool included) {
    return Icon(
      included ? Icons.check_circle : Icons.cancel,
      size: 20,
      color: included ? Colors.green : Colors.grey[300],
    );
  }
  
  List<_PlanFeature> _getPlanFeatures(PlanTier tier) {
    switch (tier) {
      case PlanTier.free:
        return [
          _PlanFeature('기본 거래', true),
          _PlanFeature('점수 시스템', true),
          _PlanFeature('배지 표시', true),
          _PlanFeature('AI 코치 요약', true),
          _PlanFeature('상세 코칭', false),
          _PlanFeature('Daily 메시지', false),
        ];
      case PlanTier.pro:
        return [
          _PlanFeature('Free 전체 기능', true),
          _PlanFeature('AI 코치 3블록', true),
          _PlanFeature('배지 상세 설명', true),
          _PlanFeature('Daily 메시지', true),
          _PlanFeature('Weekly 리포트', false),
        ];
      case PlanTier.elite:
        return [
          _PlanFeature('Pro 전체 기능', true),
          _PlanFeature('Weekly 리포트', true),
          _PlanFeature('패턴 탐지', true),
          _PlanFeature('랭킹 강조', true),
          _PlanFeature('우선 지원', true),
        ];
    }
  }
  
  void _handleUpgrade(BuildContext context, PlanTier tier) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // GA4: begin_checkout event
    AnalyticsService.logBeginCheckout(
      itemName: '${tier.displayName} Plan',
      value: tier.monthlyPrice,
    );
    
    // Mock 업그레이드
    await subscriptionProvider.upgradeTo(tier);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('업그레이드 완료!'),
          content: Text('${tier.displayName} 플랜으로 업그레이드되었습니다.\n30일 체험이 시작됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}

class _PlanFeature {
  final String name;
  final bool included;
  
  _PlanFeature(this.name, this.included);
}
