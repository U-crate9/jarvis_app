import 'package:flutter/material.dart';
import 'api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ApiService.loadConfig();
    _urlController.text = config['url'] ?? '';
    _keyController.text = config['key'] ?? '';
    _modelController.text = config['model'] ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    await ApiService.saveConfig(
      url: _urlController.text.trim(),
      key: _keyController.text.trim(),
      model: _modelController.text.trim(),
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white60),
      hintStyle: const TextStyle(color: Colors.white24),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'API Endpoint',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Point this at any OpenAI-compatible endpoint: OpenRouter, '
              'Groq, or your own server (e.g. a Colab + ngrok tunnel).',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'API URL',
                'https://openrouter.ai/api/v1/chat/completions',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _decoration('API Key', 'sk-or-...'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _modelController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Model name',
                'e.g. llama-3.3-70b-versatile',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _saved ? 'Saved ✓' : 'Save',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
