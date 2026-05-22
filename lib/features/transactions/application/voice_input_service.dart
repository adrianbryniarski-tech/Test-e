import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
/// Jeśli model nie istnieje, `status` = `unavailable`. User pobiera go
/// w Ustawieniach → „Sterowanie głosem" przez [downloadModel].
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
  StreamSubscription<String>? _partialSub;

  /// Czy użytkownik trwale odmówił zgody na mikrofon (wtedy trzeba go wysłać
  /// do ustawień systemowych — `request()` już nic nie pokaże).
  bool _micPermanentlyDenied = false;
  bool get micPermanentlyDenied => _micPermanentlyDenied;

  /// Otwiera ekran ustawień aplikacji (gdy zgoda trwale odmówiona).
  Future<void> openSystemSettings() => openAppSettings();

  String? _partialTranscript;
  String? get partialTranscript => _partialTranscript;

  /// Komunikat ostatniego błędu nagrywania (np. mikrofon zajęty / brak
  /// zgody). Pokazywany w UI, żeby „nie działa" nigdy nie było ciszą.
  String? _lastError;
  String? get lastError => _lastError;

  // Stan pobierania modelu (do UI w Ustawieniach).
  bool _downloading = false;
  bool get isDownloading => _downloading;

  /// Postęp pobierania 0..1 (faza ściągania pliku). null = nieznany rozmiar.
  double? _downloadProgress;
  double? get downloadProgress => _downloadProgress;

  String? _downloadError;
  String? get downloadError => _downloadError;

  /// Czy model jest już na dysku (gotowy lub do załadowania).
  Future<bool> isModelDownloaded() async => (await _modelDir()).existsSync();

  Future<void> init() async {
    // Model ładujemy TYLKO raz. Wcześniej `init()` (wołany z initState przy
    // każdym otwarciu ekranu „Nowa transakcja") tworzył model od nowa —
    // ~50 MB za każdym razem, bez zwalniania starego = wyciek pamięci i
    // narastające zacięcia. Gdy już gotowy/ładuje się — nic nie robimy.
    if (_status != VoiceStatus.unavailable) return;
    final dir = await _modelDir();
    if (!dir.existsSync()) {
      _status = VoiceStatus.unavailable;
      notifyListeners();
      return;
    }
    await _loadModel(dir.path);
  }

  /// Pobiera i rozpakowuje model Vosk (~50 MB), a następnie ładuje go.
  /// Postęp i błędy są wystawiane przez gettery + [notifyListeners].
  Future<void> downloadModel() async {
    if (_downloading) return;
    _downloading = true;
    _downloadProgress = null;
    _downloadError = null;
    notifyListeners();

    http.Client? client;
    try {
      final support = await getApplicationSupportDirectory();
      support.createSync(recursive: true);
      final targetDir = await _modelDir();
      // Sprzątamy ewentualny niedokończony pobór.
      if (targetDir.existsSync()) targetDir.deleteSync(recursive: true);
      final zipPath = '${support.path}/$_modelDirName.zip';
      final zipFile = File(zipPath);
      if (zipFile.existsSync()) zipFile.deleteSync();

      // Strumieniujemy do pliku, żeby nie trzymać 50 MB w pamięci.
      client = http.Client();
      final resp = await client.send(http.Request('GET', Uri.parse(modelUrl)));
      if (resp.statusCode != 200) {
        throw HttpException('Serwer zwrócił HTTP ${resp.statusCode}');
      }
      final total = resp.contentLength ?? 0;
      var received = 0;
      final sink = zipFile.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        _downloadProgress = total > 0 ? received / total : null;
        notifyListeners();
      }
      await sink.close();
      client.close();
      client = null;

      // Rozpakowanie ZIP-a (zawiera folder vosk-model-small-pl-0.22/…)
      // bezpośrednio do katalogu support.
      _downloadProgress = 1;
      notifyListeners();
      await extractFileToDisk(zipPath, support.path);
      zipFile.deleteSync();

      if (!targetDir.existsSync()) {
        throw const FileSystemException('Rozpakowany model nie istnieje');
      }
      _downloading = false;
      _downloadProgress = null;
      notifyListeners();
      await _loadModel(targetDir.path);
    } on Object catch (e) {
      debugPrint('Vosk download error: $e');
      client?.close();
      _downloading = false;
      _downloadProgress = null;
      _downloadError = e is HttpException
          ? e.message
          : 'Nie udało się pobrać modelu. Sprawdź internet i spróbuj ponownie.';
      _status = VoiceStatus.unavailable;
      notifyListeners();
    }
  }

  Future<Directory> _modelDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$_modelDirName');
  }

  Future<void> _loadModel(String path) async {
    _status = VoiceStatus.loading;
    notifyListeners();
    try {
      // Zwolnij ewentualny poprzedni model (np. po ponownym pobraniu),
      // żeby nie trzymać dwóch w pamięci.
      await _recognizer?.dispose();
      _model?.dispose();
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

  /// Prosi o zgodę na mikrofon (Android wymaga runtime request — sama
  /// deklaracja w manifeście nie wystarcza). Zwraca true gdy przyznana.
  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    _micPermanentlyDenied = status.isPermanentlyDenied;
    return status.isGranted;
  }

  /// Rozpoczyna nagrywanie (push-to-talk).
  Future<void> startListening() async {
    if (_recognizer == null) return;
    _partialTranscript = null;
    _lastError = null;

    // 1. Zgoda na mikrofon — bez niej `start()` rzuca wyjątkiem.
    if (!await _ensureMicPermission()) {
      _lastError = _micPermanentlyDenied
          ? 'Brak zgody na mikrofon. Włącz ją w ustawieniach telefonu '
              '(stuknij „Otwórz ustawienia" poniżej) i spróbuj ponownie.'
          : 'Aby dyktować, pozwól aplikacji używać mikrofonu.';
      _status = VoiceStatus.ready;
      notifyListeners();
      return;
    }

    // 2. Uruchamiamy mikrofon. Status „processing" (spinner) — UI NIE pokazuje
    //    jeszcze „Słucham…", żeby user nie zaczął mówić przed startem mikrofonu
    //    (inaczej początek zdania ginie).
    _status = VoiceStatus.processing;
    notifyListeners();
    try {
      _speechService =
          await VoskFlutterPlugin.instance().initSpeechService(_recognizer!);
      await _partialSub?.cancel();
      _partialSub = _speechService!.onPartial().listen((partial) {
        _partialTranscript = partial;
        notifyListeners();
      });
      await _speechService!.start();
      // Dopiero teraz mikrofon faktycznie nagrywa.
      _status = VoiceStatus.listening;
      notifyListeners();
    } on Exception catch (e) {
      debugPrint('Vosk listen error: $e');
      _lastError = 'Nie udało się włączyć mikrofonu. Zamknij inne aplikacje '
          'używające mikrofonu i spróbuj ponownie.';
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
      await _partialSub?.cancel();
      _partialSub = null;
      // Czekamy na flush ostatnich słów (za krótko = ucinało końcówkę).
      await Future<void>.delayed(const Duration(milliseconds: 400));
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

  @override
  void dispose() {
    _partialSub?.cancel();
    _speechService?.stop();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }
}
