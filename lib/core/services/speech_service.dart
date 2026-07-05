import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListening = false;
  final StreamController<String> _onResultController = StreamController<String>.broadcast();
  final StreamController<bool> _onListeningChangedController = StreamController<bool>.broadcast();
  final StreamController<String> _onErrorController = StreamController<String>.broadcast();

  Stream<String> get onResult => _onResultController.stream;
  Stream<bool> get onListeningChanged => _onListeningChangedController.stream;
  Stream<String> get onError => _onErrorController.stream;
  bool get isListening => _isListening;
  bool get isAvailable => _initialized && _speech.isAvailable;

  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize(
      onError: (e) => _onErrorController.add(e.errorMsg),
      onStatus: (s) {
        if (s == 'notListening' || s == 'done') {
          _isListening = false;
          _onListeningChangedController.add(false);
        }
      },
      debugLogging: false,
    );
    return _initialized;
  }

  Future<bool> hasPermission() async => await _speech.hasPermission;

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
    // Emit interim results immediately so UI can show live text
    if (r.recognizedWords.isNotEmpty) {
      _onResultController.add(r.recognizedWords);
    }
    // When the result is final, update listening state
    if (r.finalResult) {
      _isListening = false;
      _onListeningChangedController.add(false);
    }
  },
  onStatus: (status) {
    // status examples: 'listening', 'notListening', 'done'
    if (status == 'listening') {
      _isListening = true;
      _onListeningChangedController.add(true);
    } else if (status == 'notListening' || status == 'done') {
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
  }
}
