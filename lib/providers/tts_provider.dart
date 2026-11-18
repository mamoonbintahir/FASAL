import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fasal_core/models.dart';

import '../services/tts_service.dart';
import 'settings_provider.dart';

enum TtsStatus { idle, playing, paused }

enum TtsNotice { none, urduMissing, unavailable }

@immutable
class TtsState {
  const TtsState({this.status = TtsStatus.idle, this.activeId, this.notice = TtsNotice.none, this.noticeSeq = 0});

  final TtsStatus status;

  /// Which Listen button is currently speaking (so only it shows controls).
  final String? activeId;
  final TtsNotice notice;

  /// Increments on each notice so the UI can show the same notice again.
  final int noticeSeq;

  bool isActive(String id) => activeId == id && status != TtsStatus.idle;
}

final ttsEngineProvider = Provider<TtsEngine>((ref) => FlutterTtsEngine());

/// Voice guidance controller: listen / pause / resume / stop.
/// Reads exactly the text shown in the UI, in the app language.
class TtsController extends Notifier<TtsState> {
  LocalizedText? _text;
  String? _locale;

  TtsEngine get _engine => ref.read(ttsEngineProvider);

  @override
  TtsState build() {
    final engine = ref.read(ttsEngineProvider);
    engine.onDone = () {
      if (state.status == TtsStatus.playing) state = TtsState(noticeSeq: state.noticeSeq);
    };
    engine.onError = (_) => state = TtsState(noticeSeq: state.noticeSeq);
    ref.onDispose(() => engine.stop());
    return const TtsState();
  }

  Future<void> speak(String id, LocalizedText text) async {
    final settings = ref.read(settingsProvider);
    await _engine.stop();
    var lang = settings.isUrdu ? 'ur' : 'en';
    var notice = TtsNotice.none;
    if (lang == 'ur' && !await _engine.isLanguageAvailable('ur-PK')) {
      lang = 'en';
      notice = TtsNotice.urduMissing;
    }
    _locale = lang == 'ur' ? 'ur-PK' : 'en-US';
    _text = text;
    try {
      await _engine.configure(locale: _locale!, rate: settings.speechRate);
      state = TtsState(
        status: TtsStatus.playing,
        activeId: id,
        notice: notice,
        noticeSeq: notice == TtsNotice.none ? state.noticeSeq : state.noticeSeq + 1,
      );
      await _engine.speak(cleanForSpeech(text.of(lang)));
    } catch (_) {
      state = TtsState(notice: TtsNotice.unavailable, noticeSeq: state.noticeSeq + 1);
    }
  }

  Future<void> pause() async {
    if (state.status != TtsStatus.playing) return;
    await _engine.pause();
    state = TtsState(status: TtsStatus.paused, activeId: state.activeId, noticeSeq: state.noticeSeq);
  }

  /// Resumes by speaking again (Android resumes from the paused position on
  /// API 26+, older engines restart the text).
  Future<void> resume() async {
    final text = _text;
    if (state.status != TtsStatus.paused || text == null) return;
    state = TtsState(status: TtsStatus.playing, activeId: state.activeId, noticeSeq: state.noticeSeq);
    await _engine.speak(cleanForSpeech(text.of(_locale == 'ur-PK' ? 'ur' : 'en')));
  }

  Future<void> stop() async {
    await _engine.stop();
    state = TtsState(noticeSeq: state.noticeSeq);
  }
}

final ttsProvider = NotifierProvider<TtsController, TtsState>(TtsController.new);
