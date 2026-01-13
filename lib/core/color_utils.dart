import 'dart:ui';

/// Color opacity compatibility utility
/// 
/// Replaces deprecated Color.withOpacity() with Color.withAlpha()
/// to avoid deprecated_member_use warnings in newer Flutter versions.
Color withOpacityCompat(Color c, double opacity) {
  return c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}
