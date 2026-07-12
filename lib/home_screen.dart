import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'settings_screen.dart';
import 'device_controller.dart';
import 'background_service.dart';
import 'dockable_panel.dart';
import 'waveform_widget.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum JarvisState { starting, listeningForWake, listeningForCommand, thinking, speaking }

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

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final List<ChatEntry> _messages = [];
  final ScrollController _scrollController = ScrollController();

  JarvisState _state = JarvisState.starting;
  bool _speechAvailable = false;
  bool _commandCaptured = false;
  static const String _wakePhrase = 'hello jarvis';

  static const List<String> _thinkingFillers = [
    'Give me a sec, boss.',
    'One moment.',
    'On it.',
    'Let me check that.',
  ];

  @override
  void initState() {
    super.initState();
    _bootUp();
  }

  Future<void> _bootUp() async {
    await Permission.microphone.request();
    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (e) => debugPrint('Speech error: $e'),
    );

    await BackgroundService.requestPermissions();
    await BackgroundService.start();

    final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    if (_speechAvailable) {
      await _speakGreeting();
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
    if (status == 'done' || status == 'notListening') {
      if (_state == JarvisState.listeningForWake) {
        Future.delayed(const Duration(milliseconds: 400), _startWakeListening);
      } else if (_state == JarvisState.listeningForCommand && !_commandCaptured) {
        Future.delayed(const Duration(milliseconds: 400), _startWakeListening);
      }
    }
  }

  void _startWakeListening() {
    if (!_speechAvailable) return;
    setState(() => _state = JarvisState.listeningForWake);
    _speech.listen(
      onResult: _onWakeResult,
      listenFor: const Duration(seconds: 55),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _onWakeResult(dynamic result) async {
    final heard = result.recognizedWords.toString().toLowerCase();
    if (heard.contains(_wakePhrase)) {
      _speech.stop();
      await _showJarvisOverlay('Listening…', active: true);
      _startCommandListening();
    }
  }

  Future<void> _showJarvisOverlay(String text, {required bool active}) async {
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
      FlutterOverlayWindow.shareData({'text': text, 'active': active});
    } catch (_) {
      // Overlay permission may not be granted yet — safe to ignore,
      // the in-app UI still works normally.
    }
  }

  void _closeJarvisOverlay() {
    FlutterOverlayWindow.closeOverlay().catchError((_) {});
  }

  void _startCommandListening() {
    _commandCaptured = false;
    setState(() => _state = JarvisState.listeningForCommand);
    _speech.listen(
      onResult: _onCommandResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _onCommandResult(dynamic result) async {
    final command = result.recognizedWords.toString().trim();
    if (command.isEmpty) {
      _closeJarvisOverlay();
      _startWakeListening();
      return;
    }
    _commandCaptured = true;

    setState(() {
      _messages.add(ChatEntry(command, true));
      _state = JarvisState.thinking;
    });
    _scrollToBottom();
    await _showJarvisOverlay('You: $command\n\nThinking…', active: false);

    final handledLocally = await DeviceController.tryHandle(command);
    if (handledLocally) {
      await _speakAndShow('Done, boss.');
      await _showJarvisOverlay('Done, boss.', active: false);
      _scheduleOverlayClose();
      _startWakeListening();
      return;
    }

    final lower = command.toLowerCase();
    final isNewsQuery = lower.contains('news') || lower.contains('headline');

    final filler = (_thinkingFillers..shuffle()).first;
    await _tts.setSpeechRate(0.5);
    _tts.speak(filler);

    final reply = await ApiService.sendMessage(command, isNewsQuery: isNewsQuery);
    await _speakAndShow(reply);
    await _showJarvisOverlay(reply, active: false);
    _scheduleOverlayClose();
    _startWakeListening();
  }

  void _scheduleOverlayClose() {
    Future.delayed(const Duration(seconds: 6), _closeJarvisOverlay);
  }

  Future<void> _speakAndShow(String text) async {
    setState(() {
      _messages.add(ChatEntry(text, false));
      _state = JarvisState.speaking;
    });
    _scrollToBottom();
    await _tts.setSpeechRate(0.48);
    await _tts.speak(text);
  }

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
      case JarvisState.starting:
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
            ).then((_) => _bootUp()),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WaveformIndicator(active: active),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Text(
                    _statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          DockablePanel(
            title: 'TRANSCRIPT',
            initialCorner: PanelCorner.bottomLeft,
            accentColor: const Color(0xFF00E5FF),
            child: _buildTranscript(),
          ),
          DockablePanel(
            title: 'STATUS',
            initialCorner: PanelCorner.topRight,
            accentColor: const Color(0xFF3DDC84),
            child: _buildStatusPanelContent(),
          ),
          DockablePanel(
            title: 'NEWS',
            initialCorner: PanelCorner.bottomRight,
            accentColor: const Color(0xFFFFB800),
            child: _buildNewsPanelContent(),
          ),
          DockablePanel(
            title: 'QUICK ACTIONS',
            initialCorner: PanelCorner.topLeft,
            accentColor: const Color(0xFFB388FF),
            child: _buildQuickActionsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanelContent() {
    final rows = [
      ('System', _speechAvailable ? 'Online' : 'Offline', _speechAvailable),
      ('Mic', _state == JarvisState.listeningForCommand ? 'Active' : 'Standby',
          _state == JarvisState.listeningForCommand),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(r.$2,
                        style: TextStyle(
                          color: r.$3 ? const Color(0xFF00E5FF) : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNewsPanelContent() {
    final lastNews = _messages.lastWhere(
      (m) => !m.isUser,
      orElse: () => ChatEntry('Say "Hello Jarvis, what\'s the news?" to fetch a summary.', false),
    );
    return SingleChildScrollView(
      child: Text(
        lastNews.text,
        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
      ),
    );
  }

  Widget _buildQuickActionsContent() {
    final actions = [
      ('Open YouTube', 'open youtube'),
      ('Open WhatsApp', 'open whatsapp'),
      ('Alarm 6 AM', 'set an alarm for 6 am'),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: actions
          .map((a) => GestureDetector(
                onTap: () => DeviceController.tryHandle(a.$2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '› ${a.$1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTranscript() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Say "Hello Jarvis" to start.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: m.isUser ? const Color(0xFF00E5FF).withOpacity(0.15) : const Color(0xFF12161F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: m.isUser ? const Color(0xFF00E5FF).withOpacity(0.4) : Colors.white12,
              ),
            ),
            child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.25)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
