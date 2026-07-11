import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'settings_screen.dart';
import 'device_controller.dart';
import 'background_service.dart';

enum JarvisState { idle, listeningForWake, listeningForCommand, thinking, speaking }

class ChatEntry {
  final String text;
  final bool isUser;
  ChatEntry(this.text, this.isUser);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final List<ChatEntry> _messages = [];
  final ScrollController _scrollController = ScrollController();

  JarvisState _state = JarvisState.idle;
  bool _speechAvailable = false;
  bool _commandCaptured = false;
  static const String _wakePhrase = 'hello jarvis';

  late AnimationController _pulseController;

  static const List<String> _thinkingFillers = [
    'Give me a sec, boss.',
    'One moment.',
    'On it.',
    'Let me check that.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initSpeech();
    _initBackgroundService();
  }

  Future<void> _initBackgroundService() async {
    await BackgroundService.requestPermissions();
    await BackgroundService.start();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (e) => debugPrint('Speech error: $e'),
    );
    if (_speechAvailable) {
      _speakGreeting();
      _startWakeListening();
    } else {
      setState(() {});
    }
  }

  Future<void> _speakGreeting() async {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 0 && hour < 5) {
      greeting = "Hello boss, you're up late tonight.";
    } else if (hour < 12) {
      greeting = 'Good morning, boss. Jarvis is online.';
    } else if (hour < 17) {
      greeting = 'Good afternoon, boss. Ready when you are.';
    } else {
      greeting = 'Good evening, boss. Jarvis is online.';
    }
    setState(() => _messages.add(ChatEntry(greeting, false)));
    await _tts.setSpeechRate(0.48);
    await _tts.speak(greeting);
  }

  void _onSpeechStatus(String status) {
    // If listening stops on its own (timeout), restart the wake-word loop.
    if (status == 'done' || status == 'notListening') {
      if (_state == JarvisState.listeningForWake) {
        Future.delayed(const Duration(milliseconds: 400), _startWakeListening);
      } else if (_state == JarvisState.listeningForCommand && !_commandCaptured) {
        // Timed out waiting for a command after the wake word — go back to
        // listening for the wake word instead of getting stuck.
        Future.delayed(const Duration(milliseconds: 400), _startWakeListening);
      }
    }
  }

  void _startWakeListening() {
    if (!_speechAvailable) return;
    setState(() => _state = JarvisState.listeningForWake);
    _speech.listen(
      onResult: _onWakeResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _onWakeResult(dynamic result) {
    final heard = result.recognizedWords.toString().toLowerCase();
    if (heard.contains(_wakePhrase)) {
      _speech.stop();
      _startCommandListening();
    }
  }

  void _startCommandListening() {
    _commandCaptured = false;
    setState(() => _state = JarvisState.listeningForCommand);
    _speech.listen(
      onResult: _onCommandResult,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _onCommandResult(dynamic result) async {
    final command = result.recognizedWords.toString().trim();
    if (command.isEmpty) {
      _startWakeListening();
      return;
    }
    _commandCaptured = true;

    setState(() {
      _messages.add(ChatEntry(command, true));
      _state = JarvisState.thinking;
    });
    _scrollToBottom();

    // Try local device actions first (open app, set alarm) — no API call needed.
    final handledLocally = await DeviceController.tryHandle(command);
    if (handledLocally) {
      const reply = 'Done, boss.';
      setState(() {
        _messages.add(ChatEntry(reply, false));
        _state = JarvisState.speaking;
      });
      _scrollToBottom();
      await _tts.setSpeechRate(0.48);
      await _tts.speak(reply);
      _tts.setCompletionHandler(() => _startWakeListening());
      return;
    }

    // Speak a quick filler while we wait on the API, for a snappier feel.
    final filler = (_thinkingFillers..shuffle()).first;
    await _tts.setSpeechRate(0.5);
    unawaited(_tts.speak(filler));

    final reply = await ApiService.sendMessage(command);

    setState(() {
      _messages.add(ChatEntry(reply, false));
      _state = JarvisState.speaking;
    });
    _scrollToBottom();

    await _tts.setSpeechRate(0.48);
    await _tts.speak(reply);
    _tts.setCompletionHandler(() {
      _startWakeListening();
    });
  }

  void unawaited(Future<void> future) {}

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _statusLabel {
    switch (_state) {
      case JarvisState.idle:
        return _speechAvailable ? 'Starting…' : 'Microphone unavailable';
      case JarvisState.listeningForWake:
        return 'Say "Hello Jarvis"';
      case JarvisState.listeningForCommand:
        return 'Listening…';
      case JarvisState.thinking:
        return 'Thinking…';
      case JarvisState.speaking:
        return 'Speaking…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _state == JarvisState.listeningForCommand ||
        _state == JarvisState.thinking ||
        _state == JarvisState.speaking;

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'JARVIS',
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildOrb(active),
          const SizedBox(height: 10),
          Text(
            _statusLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildStatusPanels(),
          const SizedBox(height: 12),
          Expanded(child: _buildTranscript()),
        ],
      ),
    );
  }

  Widget _buildStatusPanels() {
    final panels = [
      ('SYSTEM', _speechAvailable ? 'ONLINE' : 'OFFLINE', _speechAvailable),
      ('MODEL', 'CONNECTED', true),
      ('MIC', _state == JarvisState.listeningForCommand ? 'ACTIVE' : 'STANDBY',
          _state == JarvisState.listeningForCommand),
    ];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: panels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (label, value, isUp) = panels[i];
          return Container(
            width: 130,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUp ? const Color(0xFF00E5FF) : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrb(bool active) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = active
            ? 1.0 + (_pulseController.value * 0.15)
            : 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(active ? 0.9 : 0.4),
                  const Color(0xFF00E5FF).withOpacity(0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(active ? 0.5 : 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranscript() {
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Say "Hello Jarvis" to start. Your conversation will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: m.isUser
                  ? const Color(0xFF00E5FF).withOpacity(0.15)
                  : const Color(0xFF12161F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: m.isUser
                    ? const Color(0xFF00E5FF).withOpacity(0.4)
                    : Colors.white12,
              ),
            ),
            child: Text(
              m.text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
