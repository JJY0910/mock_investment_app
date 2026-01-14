/// Platform-specific analytics helper
/// 
/// Uses conditional exports to provide different implementations:
/// - Web: Real gtag event sending via dart:js_interop
/// - Non-Web: No-op stub
export 'analytics_helper_stub.dart'
  if (dart.library.js_interop) 'analytics_helper_web.dart';
