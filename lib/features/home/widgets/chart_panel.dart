// Conditional export for web/non-web platforms
export 'chart_panel_stub.dart'
  if (dart.library.html) 'chart_panel_web.dart';
