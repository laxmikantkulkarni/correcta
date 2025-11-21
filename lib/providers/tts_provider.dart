// lib/providers/tts_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsProvider extends ChangeNotifier {
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  String _lastSpokenFeedback = '';

  bool get isSpeaking => _isSpeaking;
  bool get isEnabled => _isEnabled;

  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    // Configure TTS settings
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(0.8);
    await _flutterTts!.setPitch(1.0);

    // Set up TTS completion handler
    _flutterTts!.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    // Set up TTS error handler
    _flutterTts!.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || _isSpeaking || text == _lastSpokenFeedback) return;

    _isSpeaking = true;
    _lastSpokenFeedback = text;
    notifyListeners();

    try {
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    notifyListeners();
    speak(_isEnabled ? 'Voice feedback enabled' : 'Voice feedback disabled');
  }

  void resetLastSpoken() {
    _lastSpokenFeedback = '';
  }

  Future<void> stop() async {
    await _flutterTts?.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }
}