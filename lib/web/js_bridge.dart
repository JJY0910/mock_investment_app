// Conditional export for JavaScript interop
// Exports stub on non-web platforms, web implementation on web platforms
export 'js_bridge_stub.dart'
  if (dart.library.html) 'js_bridge_web.dart';
