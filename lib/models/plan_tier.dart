/// 구독 플랜 등급
enum PlanTier {
  free('Free', 0.0, 'Basic trading and scoring'),
  pro('Pro', 9.99, 'Full AI coaching and insights'),
  elite('Elite', 19.99, 'Premium features and priority support');
  
  final String displayName;
  final double monthlyPrice;
  final String description;
  
  const PlanTier(this.displayName, this.monthlyPrice, this.description);
  
  String get priceText => monthlyPrice == 0 ? 'Free' : '\$${monthlyPrice.toStringAsFixed(2)}/month';
}
