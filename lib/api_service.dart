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

  /// Sends [message] to the configured OpenAI-compatible endpoint
  /// (this shape works for OpenRouter, Groq, and most self-hosted
  /// servers including a typical Colab + ngrok tunnel running an
  /// OpenAI-compatible server like text-generation-webui or vLLM).
  static Future<String> sendMessage(String message) async {
    final config = await loadConfig();
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
                  'content':
                      'You are Jarvis, a concise, helpful personal voice assistant. Keep answers short and spoken-friendly.'
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
      // OpenAI-compatible shape: choices[0].message.content
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
