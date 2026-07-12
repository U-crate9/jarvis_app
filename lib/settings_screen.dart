import 'package:flutter/material.dart';
import 'api_service.dart';
import 'wake_word_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  final _newsUrlController = TextEditingController();
  final _newsKeyController = TextEditingController();
  final _newsModelController = TextEditingController();
  final _picovoiceController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ApiService.loadConfig();
    final newsConfig = await ApiService.loadNewsConfig();
    final picovoiceKey = await WakeWordService.loadAccessKey();
    _urlController.text = config['url'] ?? '';
    _keyController.text = config['key'] ?? '';
    _modelController.text = config['model'] ?? '';
    _newsUrlController.text = newsConfig['url'] ?? '';
    _newsKeyController.text = newsConfig['key'] ?? '';
    _newsModelController.text = newsConfig['model'] ?? '';
    _picovoiceController.text = picovoiceKey;
    setState(() {});
  }

  Future<void> _save() async {
    await ApiService.saveConfig(
      url: _urlController.text.trim(),
      key: _keyController.text.trim(),
      model: _modelController.text.trim(),
    );
    await ApiService.saveNewsConfig(
      url: _newsUrlController.text.trim(),
      key: _newsKeyController.text.trim(),
      model: _newsModelController.text.trim(),
    );
    await WakeWordService.saveAccessKey(_picovoiceController.text.trim());
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

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
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
            _sectionTitle(
              'Wake Word (Picovoice)',
              'Free Access Key from console.picovoice.ai — needed for silent, always-on "Hello Jarvis" detection.',
            ),
            TextField(
              controller: _picovoiceController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _decoration('Picovoice Access Key', 'paste your AccessKey here'),
            ),
            _sectionTitle(
              'Main AI (chat)',
              'Any OpenAI-compatible endpoint: OpenRouter, Groq, or your own server.',
            ),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('API URL', 'https://openrouter.ai/api/v1/chat/completions'),
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
              decoration: _decoration('Model name', 'e.g. meta-llama/llama-3.3-70b-instruct:free'),
            ),
            _sectionTitle(
              'News (optional)',
              'A separate endpoint used only when you ask about news. Leave blank to reuse the main AI above.',
            ),
            TextField(
              controller: _newsUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('News API URL', 'optional'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newsKeyController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _decoration('News API Key', 'optional'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newsModelController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('News Model name', 'optional'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _saved ? 'Saved ✓' : 'Save',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
