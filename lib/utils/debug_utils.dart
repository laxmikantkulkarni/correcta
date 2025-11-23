// lib/utils/debug_utils.dart
import 'package:flutter/foundation.dart';

/// Throttles debug printing to avoid console spam
class DebugThrottler {
  static final Map<String, DateTime> _lastPrintTimes = {};
  static const Duration _throttleDuration = Duration(seconds: 2);

  /// Prints debug message only if enough time has passed since last print
  static void throttledPrint(String key, String message) {
    final now = DateTime.now();
    final lastPrint = _lastPrintTimes[key];

    if (lastPrint == null || now.difference(lastPrint) > _throttleDuration) {
      debugPrint(message);
      _lastPrintTimes[key] = now;
    }
  }

  /// Prints full debug info with throttling
  static void printDebugInfo(String key, Map<String, dynamic> data) {
    final now = DateTime.now();
    final lastPrint = _lastPrintTimes[key];

    if (lastPrint == null || now.difference(lastPrint) > _throttleDuration) {
      final buffer = StringBuffer();
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════');
      data.forEach((label, value) {
        buffer.writeln('$label: $value');
      });
      buffer.writeln('═══════════════════════════════════════');
      debugPrint(buffer.toString());
      _lastPrintTimes[key] = now;
    }
  }
}

// Usage Example:
// DebugThrottler.throttledPrint('camera', 'Image Size: 480x640');