import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Abstraction over the device text-to-speech engine (fakeable in tests).
abstract interface class TtsEngine {
  Future<bool> isLanguageAvailable(String locale);
  Future<void> configure({required String locale, required double rate});
  Future<void> speak(String text);
  Future<void> pause();
  Future<void> stop();
  set onDone(VoidCallback? cb);
  set onError(ValueChanged<String>? cb);
}

/// Real engine using `flutter_tts`.
/// Urdu needs a TTS voice installed on the phone (Google TTS → Urdu).
class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine() {
    _tts.setCompletionHandler(() => _onDone?.call());
    _tts.setCancelHandler(() => _onDone?.call());
    _tts.setErrorHandler((dynamic msg) => _onError?.call(msg.toString()));
  }

  final FlutterTts _tts = FlutterTts();
  VoidCallback? _onDone;
  ValueChanged<String>? _onError;

  @override
  set onDone(VoidCallback? cb) => _onDone = cb;

  @override
  set onError(ValueChanged<String>? cb) => _onError = cb;

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    try {
      final dynamic r = await _tts.isLanguageAvailable(locale);
      return r == true || r == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> configure({required String locale, required double rate}) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

/// Removes emoji / symbols so the voice doesn't read them aloud.
String cleanForSpeech(String text) => text
    .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]', unicode: true), '')
    .replaceAll(' · ', ', ')
    .replaceAll('·', ',')
    .replaceAll('→', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
