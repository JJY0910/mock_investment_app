/// Analytics helper stub for non-web platforms
/// 
/// This is a no-op implementation used on mobile and desktop platforms.
/// Actual logging is handled by debugPrint in AnalyticsService.
void sendGtagEvent(String eventName, Map<String, Object?> params) {
  // No-op on non-web platforms
  // debugPrint is already handled in AnalyticsService
}
