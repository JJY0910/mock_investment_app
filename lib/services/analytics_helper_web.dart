import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// Analytics helper for web platform
/// 
/// Uses dart:js_interop to call global gtag function.
/// Avoids dart:js and package:web to prevent build conflicts.

bool _debugModeInitialized = false;

/// Send GA4 event via gtag
void sendGtagEvent(String eventName, Map<String, Object?> params) {
  // Lazy initialize debug mode (only once in debug mode)
  if (kDebugMode && !_debugModeInitialized) {
    _initDebugMode();
    _debugModeInitialized = true;
  }
  
  // Get global gtag function
  final gtag = _getGtagFunction();
  if (gtag == null) {
    if (kDebugMode) {
      print('[Analytics] gtag function not found, skipping event: $eventName');
    }
    return;
  }
  
  // Convert params to JSObject
  final jsParams = _jsify(params);
  
  // Call gtag('event', eventName, params)
  try {
    gtag.callMethod('apply'.toJS, null, [
      'event'.toJS,
      eventName.toJS,
      jsParams,
    ].toJS);
  } catch (e) {
    if (kDebugMode) {
      print('[Analytics] Error calling gtag: $e');
    }
  }
}

/// Initialize debug mode for GA4 DebugView
void _initDebugMode() {
  final gtag = _getGtagFunction();
  if (gtag == null) return;
  
  try {
    gtag.callMethod('apply'.toJS, null, [
      'set'.toJS,
      'debug_mode'.toJS,
      true.toJS,
    ].toJS);
    print('[Analytics] Debug mode enabled for GA4 DebugView');
  } catch (e) {
    print('[Analytics] Error setting debug mode: $e');
  }
}

/// Get global gtag function safely
JSObject? _getGtagFunction() {
  try {
    final globalThis = globalContext;
    if (globalThis.has('gtag')) {
      return globalThis['gtag'] as JSObject?;
    }
  } catch (e) {
    if (kDebugMode) {
      print('[Analytics] Error accessing gtag: $e');
    }
  }
  return null;
}

/// Convert Dart Map/List to JSObject/JSArray
/// 
/// Supports:
/// - String, num, bool, null -> direct conversion
/// - Map -> JSObject (recursive)
/// - List -> JSArray (recursive)
JSAny? _jsify(Object? value) {
  if (value == null) {
    return null;
  } else if (value is String) {
    return value.toJS;
  } else if (value is num) {
    return value.toJS;
  } else if (value is bool) {
    return value.toJS;
  } else if (value is Map) {
    final jsObject = JSObject();
    value.forEach((key, val) {
      final jsKey = key.toString();
      final jsVal = _jsify(val);
      if (jsVal != null) {
        jsObject.setProperty(jsKey.toJS, jsVal);
      }
    });
    return jsObject;
  } else if (value is List) {
    final jsArray = <JSAny?>[];
    for (final item in value) {
      jsArray.add(_jsify(item));
    }
    return jsArray.toJS;
  } else {
    // Fallback: convert to string
    return value.toString().toJS;
  }
}
