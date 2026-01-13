import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trader_score_provider.dart';
import '../providers/subscription_provider.dart'; // PHASE 3
import '../models/coach_badge.dart';

/// AI 코치 카드 (TradeScreen 하단) - 3블록 버전
class AICoachCard extends StatelessWidget {
  const AICoachCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<TraderScoreProvider, SubscriptionProvider>(
      builder: (context, scoreProvider, subscriptionProvider, child) {
        final feedback = scoreProvider.lastFeedback;
        final hasPremium = subscriptionProvider.hasPremium;
        
        if (feedback == null) {
          return Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.psychology, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    '거래를 시작하면 AI 코치가 피드백을 제공합니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: AI 코치 + 배지
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 24, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'AI 코치',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(scoreProvider.currentBadge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => _showProInfo(context),
                      tooltip: 'Pro 기능 안내',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  feedback.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Bullets (근거) - Free 플랜 차등화
                if (hasPremium) ...[
                  if (feedback.bullets.isNotEmpty) ...[
                    ...feedback.bullets.map((bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  // Free 플랜: 잠금 UI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock, size: 32, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'Pro 플랜으로 업그레이드하여\n상세 근거와 액션 가이드를 확인하세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/pricing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pro 플랜 보기'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                const Divider(),
                const SizedBox(height: 12),
                
                // NextAction (강조) - Free 플랜 차등화
                if (hasPremium) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feedback.nextAction,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // 업데이트 시간
                const SizedBox(height: 12),
                Text(
                  _formatTime(feedback.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBadge(CoachBadge badge) {
    final badgeColor = _getBadgeColor(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        badge.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
  
  Color _getBadgeColor(CoachBadge badge) {
    switch (badge) {
      case CoachBadge.stopLossBuilder:
        return Colors.orange;
      case CoachBadge.overtradeBreaker:
        return Colors.red;
      case CoachBadge.entrySniper:
        return Colors.green;
      case CoachBadge.rrArchitect:
        return Colors.purple;
      case CoachBadge.habitMaster:
        return Colors.blue;
      case CoachBadge.rookie:
        return Colors.grey;
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
  
  void _showProInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 기능'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Pro 구독 시 제공되는 기능:'),
            SizedBox(height: 12),
            Text('• TradeScore 상세 항목 설명'),
            Text('• HabitScore 원인 분석'),
            Text('• 최근 7일 패턴 요약'),
            Text('• 실수 반복 패턴 탐지'),
            Text('•  Daily/Weekly 리포트'),
            SizedBox(height: 12),
            Text(
              '현재 Free 플랜: 기본 코칭만 제공',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
