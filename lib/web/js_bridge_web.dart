// Web-specific implementation using dart:js_util
// This file is only compiled on web platforms
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

/// Call a JavaScript method on a target object
dynamic callMethod(dynamic target, String method, List<dynamic> args) {
  return js_util.callMethod(target, method, args);
}

/// Check if a JavaScript object has a property
bool hasProperty(dynamic target, String property) {
  return js_util.hasProperty(target, property);
}

/// Convert a Dart object to JavaScript
dynamic jsify(dynamic object) {
  return js_util.jsify(object);
}

/// Access to window object for web-specific operations
dynamic get window => html.window;
