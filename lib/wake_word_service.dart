import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WakeWordService {
  static const _accessKeyPref = 'picovoice_access_key';
  PorcupineManager? _manager;

  static Future<void> saveAccessKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKeyPref, key);
  }

  static Future<String> loadAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKeyPref) ?? '';
  }

  Future<String?> start({required Function() onWake}) async {
    final accessKey = await loadAccessKey();
    if (accessKey.isEmpty) {
      return 'No Picovoice Access Key set. Add it in Settings.';
    }
    try {
      _manager = await PorcupineManager.fromBuiltInKeywords(
        accessKey,
        [BuiltInKeyword.JARVIS],
        (keywordIndex) {
          if (keywordIndex == 0) onWake();
        },
        errorCallback: (error) {},
      );
      await _manager!.start();
      return null;
    } on PorcupineException catch (e) {
      return 'Wake word engine failed to start: ${e.message}';
    } catch (e) {
      return 'Wake word engine failed to start: $e';
    }
  }

  Future<void> pause() async {
    try {
      await _manager?.stop();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await _manager?.start();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _manager?.stop();
      await _manager?.delete();
    } catch (_) {}
    _manager = null;
  }
}
