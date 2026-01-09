// Stub implementation for non-web platforms
void clearOAuthQueryFromUrl() {
  // No-op on non-web platforms
  print('[Auth] clearOAuthQueryFromUrl (stub - no action on non-web)');
}

// Replace history state (no-op on non-web)
void replaceHistoryState(String url) {
  // No-op on non-web platforms
  print('[UrlHelper] replaceHistoryState (stub - no action on non-web)');
}

// Redirect to root (no-op on non-web)
void redirectToRoot() {
  // No-op on non-web platforms
  print('[UrlHelper] redirectToRoot (stub - no action on non-web)');
}
