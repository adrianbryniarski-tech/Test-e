import 'package:audioplayers/audioplayers.dart';

/// Cienki wrapper nad audioplayers dla pojedynczych short-burst'ów.
/// Trzymamy 1 instance AudioPlayer per service — reuse + lower latency
/// niż tworzenie new instance per play.
class SoundService {
  SoundService() : _player = AudioPlayer() {
    // Tryb low-latency — krótkie sample, bez bufferowania.
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;

  /// Odpala cash-register "cha-ching" przy zapisie dochodu.
  /// Plik w assets/sounds/cha_ching.mp3 — rzeczywista próbka kasy
  /// z freesound.org (CC0 / public domain).
  Future<void> playChaChing() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/cha_ching.mp3'));
    } on Object {
      // Audio errors są niekrytyczne — nigdy nie powinniśmy crashnąć
      // apki bo dźwięk nie zagrał (np. brak headphone routing, no permission).
    }
  }

  void dispose() => _player.dispose();
}
