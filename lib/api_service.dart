import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all outbound calls to whichever AI backend the user configures
/// (OpenRouter, Groq, a self-hosted Colab tunnel, or anything else that
/// speaks a simple "send text, get text back" JSON API).
class ApiService {
  static const _urlKey = 'api_url';
  static const _keyKey = 'api_key';
  static const _modelKey = 'api_model';
  static const _newsUrlKey = 'news_api_url';
  static const _newsKeyKey = 'news_api_key';
  static const _newsModelKey = 'news_api_model';

  static Future<void> saveConfig({
    required String url,
    required String key,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
    await prefs.setString(_keyKey, key);
    await prefs.setString(_modelKey, model);
  }

  static Future<Map<String, String>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString(_urlKey) ?? '',
      'key': prefs.getString(_keyKey) ?? '',
      'model': prefs.getString(_modelKey) ?? '',
    };
  }

  static Future<void> saveNewsConfig({
    required String url,
    required String key,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_newsUrlKey, url);
    await prefs.setString(_newsKeyKey, key);
    await prefs.setString(_newsModelKey, model);
  }

  static Future<Map<String, String>> loadNewsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString(_newsUrlKey) ?? '',
      'key': prefs.getString(_newsKeyKey) ?? '',
      'model': prefs.getString(_newsModelKey) ?? '',
    };
  }

  /// Sends [message] to the main configured endpoint. If [isNewsQuery] is
  /// true and a separate News endpoint is configured, that one is used
  /// instead — otherwise it falls back to the main endpoint.
  static Future<String> sendMessage(String message, {bool isNewsQuery = false}) async {
    var config = await loadConfig();
    if (isNewsQuery) {
      final newsConfig = await loadNewsConfig();
      if ((newsConfig['url'] ?? '').isNotEmpty) {
        config = newsConfig;
      }
    }

    final url = config['url'] ?? '';
    final key = config['key'] ?? '';
    final model = config['model'] ?? '';

    if (url.isEmpty) {
      return "No API endpoint is set yet. Open Settings and add your API URL, key, and model name first.";
    }

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (key.isNotEmpty) 'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': isNewsQuery
                      ? 'You are Jarvis, a personal voice assistant. Summarize the latest relevant news concisely in 2-4 spoken-friendly sentences.'
                      : 'You are Jarvis, a concise, helpful personal voice assistant. Keep answers short and spoken-friendly.'
                },
                {'role': 'user', 'content': message},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return "Request failed (HTTP ${response.statusCode}). Check your API key, URL, and rate limits in Settings.";
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      if (content == null) {
        return "Got a response I couldn't parse. Check that your endpoint returns an OpenAI-style JSON body.";
      }
      return content.toString().trim();
    } catch (e) {
      return "Couldn't reach the API endpoint. Check your internet connection and the URL in Settings.\n\nDetails: $e";
    }
  }
}
