/// 구독 플랜 등급
enum PlanTier {
  free('Free', 0, 'Basic trading and scoring'),
  pro('Pro', 4990, 'Full AI coaching and insights'),
  max('Max', 13900, 'Premium features and priority support');
  
  final String displayName;
  final int monthlyPriceKrw;
  final String description;
  
  const PlanTier(this.displayName, this.monthlyPriceKrw, this.description);
  
  String get priceText => monthlyPriceKrw == 0 ? 'Free' : '₩${monthlyPriceKrw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  
  // === 랭킹 접근 권한 ===
  
  /// Top 10 총자산 랭킹 조회 가능 여부
  bool get canViewTop10TotalAssets => this != PlanTier.free;
  
  /// 수익률 탭 접근 가능 여부
  bool get canViewProfitTabs => this != PlanTier.free;
  
  /// Free 플랜이 볼 수 있는 랭킹 범위 (11~50위)
  static const int freeRankStart = 11;
  static const int freeRankEnd = 50;
  
  // === AI 코치 사용 제한 ===
  
  /// 일일 AI 코치 사용 횟수
  int get maxAICoachDaily {
    switch (this) {
      case PlanTier.free:
        return 3;
      case PlanTier.pro:
        return 10;
      case PlanTier.max:
        return 999; // 무제한
    }
  }
  
  // === 충전 제한 ===
  
  /// 일일 500만원 충전 횟수
  int get maxDailyRecharges {
    switch (this) {
      case PlanTier.free:
        return 3;
      case PlanTier.pro:
      case PlanTier.max:
        return 999; // 무제한
    }
  }
}
