// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// Web-specific implementation for URL cleanup
void clearOAuthQueryFromUrl() {
  final uri = Uri.base;
  if (uri.queryParameters.containsKey('code') || 
      uri.queryParameters.containsKey('error') ||
      uri.queryParameters.containsKey('state')) {
    
    // Remove query parameters from URL
    final newUrl = uri.origin + uri.path;
    print('[Auth] Clearing OAuth params. New URL: $newUrl');
    
    // Replace history without reload
    html.window.history.replaceState(null, '', newUrl);
  }
}

// Replace history state with new URL
void replaceHistoryState(String url) {
  html.window.history.replaceState(null, '', url);
}

// Redirect to root
void redirectToRoot() {
  html.window.location.href = '/';
}
