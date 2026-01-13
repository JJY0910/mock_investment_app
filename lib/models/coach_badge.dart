/// 코치 배지 타입
enum CoachBadge {
  stopLossBuilder('StopLoss Builder', '손절 설정이 부족합니다'),
  overtradeBreaker('Overtrade Breaker', '과매매 경향이 있습니다'),
  entrySniper('Entry Sniper', '진입 타이밍이 우수합니다'),
  rrArchitect('RR Architect', 'RR 비율 관리가 우수합니다'),
  habitMaster('Habit Master', '거래 습관이 안정적입니다'),
  rookie('Rookie Trader', '거래를 시작하세요');
  
  final String displayName;
  final String description;
  
  const CoachBadge(this.displayName, this.description);
}
