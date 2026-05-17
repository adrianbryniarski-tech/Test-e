import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';

/// Status usługi rozpoznawania głosu.
enum VoiceStatus {
  /// Model nie pobrany lub brak uprawnień.
  unavailable,

  /// Model jest ładowany do pamięci.
  loading,

  /// Gotowy do nagrywania.
  ready,

  /// Trwa nagrywanie.
  listening,

  /// Przetwarzanie transkryptu.
  processing,
}

/// Wynik nagrania.
sealed class VoiceResult {}

class VoiceTranscript extends VoiceResult {
  VoiceTranscript(this.text);

  final String text;
}

class VoiceError extends VoiceResult {
  VoiceError(this.message);

  final String message;
}

/// Serwis Vosk (singleton, lazy init).
///
/// Lifecycle:
/// 1. `init()` — ładuje model z dysku (jeśli istnieje).
/// 2. `startListening()` / `stopListening()` — push-to-talk.
/// 3. `dispose()` — zwalnia zasoby.
///
/// Jeśli model nie istnieje, `status` = `unavailable`.
/// Model pobierany ręcznie przez usera przez `downloadModel()`.
class VoiceInputService extends ChangeNotifier {
  VoiceInputService._();

  static final VoiceInputService instance = VoiceInputService._();

  static const _modelDirName = 'vosk-model-small-pl-0.22';

  // Oficjalny URL małego polskiego modelu Vosk (~50 MB).
  static const modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip';

  VoiceStatus _status = VoiceStatus.unavailable;
  VoiceStatus get status => _status;

  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  String? _partialTranscript;
  String? get partialTranscript => _partialTranscript;

  Future<void> init() async {
    final dir = await _modelDir();
    if (!dir.existsSync()) {
      _status = VoiceStatus.unavailable;
      notifyListeners();
      return;
    }
    await _loadModel(dir.path);
  }

  Future<Directory> _modelDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$_modelDirName');
  }

  Future<void> _loadModel(String path) async {
    _status = VoiceStatus.loading;
    notifyListeners();
    try {
      _model = await VoskFlutterPlugin.instance().createModel(path);
      _recognizer = await VoskFlutterPlugin.instance()
          .createRecognizer(model: _model!, sampleRate: 16000);
      _status = VoiceStatus.ready;
    } on Exception catch (e) {
      debugPrint('Vosk load error: $e');
      _status = VoiceStatus.unavailable;
    }
    notifyListeners();
  }

  /// Rozpoczyna nagrywanie (push-to-talk).
  Future<void> startListening() async {
    if (_recognizer == null) return;
    _status = VoiceStatus.listening;
    _partialTranscript = null;
    notifyListeners();

    try {
      _speechService = await VoskFlutterPlugin.instance()
          .initSpeechService(_recognizer!);
      await _speechService!.start();
      _speechService!.onPartial().listen((partial) {
        _partialTranscript = partial;
        notifyListeners();
      });
    } on Exception catch (e) {
      debugPrint('Vosk listen error: $e');
      _status = VoiceStatus.ready;
      notifyListeners();
    }
  }

  /// Zatrzymuje nagrywanie i zwraca finalny transkrypt.
  Future<String?> stopListening() async {
    if (_speechService == null) return null;
    _status = VoiceStatus.processing;
    notifyListeners();

    try {
      await _speechService!.stop();
      // Czekamy chwilę na finalny wynik.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final result = await _recognizer!.getFinalResult();
      _speechService = null;
      _status = VoiceStatus.ready;
      notifyListeners();
      // Vosk zwraca JSON {"text": "..."}, wyciągamy pole text.
      return _extractText(result);
    } on Exception catch (e) {
      debugPrint('Vosk stop error: $e');
      _speechService = null;
      _status = VoiceStatus.ready;
      notifyListeners();
      return null;
    }
  }

  String? _extractText(String json) {
    // Prosta ekstrakcja pola "text" bez json.decode na krytycznej ścieżce.
    final start = json.indexOf('"text"');
    if (start == -1) return null;
    final colon = json.indexOf(':', start);
    if (colon == -1) return null;
    final q1 = json.indexOf('"', colon);
    if (q1 == -1) return null;
    final q2 = json.indexOf('"', q1 + 1);
    if (q2 == -1) return null;
    final text = json.substring(q1 + 1, q2).trim();
    return text.isEmpty ? null : text;
  }

  /// Oznacza model jako pobrany i ładuje go.
  Future<void> notifyModelDownloaded() async {
    final dir = await _modelDir();
    if (dir.existsSync()) {
      await _loadModel(dir.path);
    }
  }

  @override
  void dispose() {
    _speechService?.stop();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }
}
