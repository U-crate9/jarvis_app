import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// Handles local device commands that don't need the AI API at all —
/// opening apps, setting alarms. Matched by simple keyword rules before
/// falling back to the AI for anything else.
class DeviceController {
  // Common app package names. Add more here as needed.
  static const Map<String, String> _appPackages = {
    'youtube': 'com.google.android.youtube',
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'chrome': 'com.android.chrome',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'spotify': 'com.spotify.music',
    'camera': 'com.android.camera',
    'settings': 'com.android.settings',
  };

  /// Returns true if [command] was handled locally (no need to call the AI).
  static Future<bool> tryHandle(String command) async {
    final lower = command.toLowerCase();

    if (lower.contains('open ')) {
      for (final entry in _appPackages.entries) {
        if (lower.contains(entry.key)) {
          await _openApp(entry.value);
          return true;
        }
      }
    }

    if (lower.contains('set an alarm') ||
        lower.contains('set alarm') ||
        (lower.contains('alarm') && lower.contains('for'))) {
      final time = _extractTime(lower);
      if (time != null) {
        await _setAlarm(time.$1, time.$2);
        return true;
      }
    }

    return false;
  }

  static Future<void> _openApp(String packageName) async {
    final intent = AndroidIntent(
      action: 'action_main',
      package: packageName,
      componentName: null,
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
    } catch (_) {
      // App likely not installed — silently ignore, caller can fall back.
    }
  }

  static Future<void> _setAlarm(int hour, int minute) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    await intent.launch();
  }

  /// Very simple time extractor for phrases like "5 am", "5:30 pm", "17:00".
  static (int, int)? _extractTime(String text) {
    final match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(text);
    if (match == null) return null;
    int hour = int.tryParse(match.group(1) ?? '') ?? -1;
    int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final meridiem = match.group(3);
    if (hour < 0 || hour > 23) return null;
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return (hour, minute);
  }
}
