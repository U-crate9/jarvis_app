import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const String _wakePhrase = 'hello jarvis';

class JarvisTaskHandler extends TaskHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _speechReady = await _speech.initialize(
      onStatus: _onStatus,
      onError: (e) => print('Jarvis bg speech error: $e'),
    );
    if (_speechReady) {
      _listenForWake();
    }
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && !_busy) {
      Future.delayed(const Duration(milliseconds: 400), _listenForWake);
    }
  }

  void _listenForWake() {
    if (!_speechReady || _busy) return;
    _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 55),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _onResult(dynamic result) async {
    final heard = result.recognizedWords.toString().toLowerCase();
    if (heard.contains(_wakePhrase) && !_busy) {
      _busy = true;
      _speech.stop();
      await _triggerOverlay();
      _busy = false;
      _listenForWake();
    }
  }

  Future<void> _triggerOverlay() async {
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (!granted) return;
      final running = await FlutterOverlayWindow.isActive();
      if (!running) {
        await FlutterOverlayWindow.showOverlay(
          height: 220,
          width: 300,
          alignment: OverlayAlignment.center,
          enableDrag: true,
          overlayTitle: 'Jarvis',
        );
        await Future.delayed(const Duration(milliseconds: 200));
      }
      FlutterOverlayWindow.shareData({'text': 'Listening…', 'active': true});
    } catch (e) {
      print('Jarvis bg overlay error: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _speech.stop();
  }
}

class BackgroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'jarvis_service',
        channelName: 'Jarvis is running',
        channelDescription: 'Jarvis is listening for "Hello Jarvis" in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> requestPermissions() async {
    final notifPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Jarvis',
      notificationText: 'Listening for "Hello Jarvis"…',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(JarvisTaskHandler());
}
