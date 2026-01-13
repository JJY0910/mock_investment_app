// Stub implementation for non-web platforms
// This file is used when dart.library.html is not available

dynamic callMethod(dynamic target, String method, List<dynamic> args) {
  throw UnsupportedError('JS interop is only available on web platforms');
}

bool hasProperty(dynamic target, String property) {
  throw UnsupportedError('JS interop is only available on web platforms');
}

dynamic jsify(dynamic object) {
  throw UnsupportedError('JS interop is only available on web platforms');
}

/// Window object (not available on non-web platforms)
dynamic get window {
  throw UnsupportedError('Window object is only available on web platforms');
}
