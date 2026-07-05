import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListening = false;

  final StreamController<String> _onResultController = StreamController<String>.broadcast();
  final StreamController<bool> _onListeningChangedController = StreamController<bool>.broadcast();
  final StreamController<String> _onErrorController = StreamController<String>.broadcast();
  final StreamController<String> _onStatusController = StreamController<String>.broadcast();

  Stream<String> get onResult => _onResultController.stream;
  Stream<bool> get onListeningChanged => _onListeningChangedController.stream;
  Stream<String> get onError => _onErrorController.stream;
  Stream<String> get onStatus => _onStatusController.stream;
  bool get isListening => _isListening;
  bool get isAvailable => _initialized && _speech.isAvailable;

  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize(
      onError: (e) => _onErrorController.add(e.errorMsg),
      onStatus: (status) {
        _onStatusController.add(status);
        if (status == 'notListening' || status == 'done') {
          _isListening = false;
          _onListeningChangedController.add(false);
        }
      },
      debugLogging: false,
    );
    return _initialized;
  }

  Future<bool> hasPermission() async => await _speech.hasPermission;

  /// Return list of available locales on the device. Use this to choose a matching locale id like 'ar_SA' or 'ar-SA'.
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    try {
      final locales = await _speech.locales();
      return locales;
    } catch (_) {
      return <stt.LocaleName>[];
    }
  }

  /// Choose the first available locale from [preferred] or null if none found.
  Future<String?> pickLocale(List<String> preferred) async {
    final locales = await getAvailableLocales();
    final ids = locales.map((l) => l.localeId).toList();
    for (final p in preferred) {
      if (ids.contains(p)) return p;
    }
    return ids.isNotEmpty ? ids.first : null;
  }

  Future<void> startListening({
    String localeId = 'en_US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        _onErrorController.add('Speech recognition not available');
        return;
      }
    }
    if (_isListening) await stopListening();

    _isListening = true;
    _onListeningChangedController.add(true);

    _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty) {
          _onResultController.add(r.recognizedWords);
        }
        if (r.finalResult) {
          _isListening = false;
          _onListeningChangedController.add(false);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _onListeningChangedController.add(false);
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _onListeningChangedController.add(false);
    }
  }

  void dispose() {
    _onResultController.close();
    _onListeningChangedController.close();
    _onErrorController.close();
    _onStatusController.close();
  }
}
