import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/voice_input_service.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/voice_parser.dart';

/// Przycisk push-to-talk z Vosk.
///
/// Stany wizualne:
/// - unavailable → ikona mikrofonu wyszarzona + tooltip "Pobierz model"
/// - loading     → spinner
/// - ready       → ikona mikrofonu (trzymaj = nagrywanie)
/// - listening   → pulsująca czerwona ikona + opis "Mów..."
/// - processing  → spinner
///
/// Po rozpoznaniu wywoływany jest [onResult] z przefiltrowanym wynikiem.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    required this.categories,
    required this.onResult,
    super.key,
  });

  final List<Category> categories;
  final void Function(VoiceParseResult result) onResult;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _service = VoiceInputService.instance;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _service
      ..addListener(_rebuild)
      ..init();
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    _pulse.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_service.status != VoiceStatus.ready) return;
    await _service.startListening();
  }

  Future<void> _stopListening() async {
    if (_service.status != VoiceStatus.listening) return;
    final transcript = await _service.stopListening();
    if (transcript == null || transcript.isEmpty) return;
    final parser = VoiceParser(widget.categories);
    final result = parser.parse(transcript);
    widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = _service.status;

    if (status == VoiceStatus.unavailable) {
      // Klikalny skrót: model niegotowy → przejdź od razu do Ustawień,
      // gdzie można go pobrać.
      return IconButton.outlined(
        tooltip: 'Model głosu niegotowy — stuknij, aby pobrać w Ustawieniach',
        onPressed: () => context.push('/settings'),
        icon: const Icon(Icons.mic_off_outlined),
      );
    }

    if (status == VoiceStatus.loading || status == VoiceStatus.processing) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (status == VoiceStatus.listening) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapUp: (_) => _stopListening(),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    cs.error,
                    cs.errorContainer,
                    _pulse.value,
                  ),
                ),
                child: Icon(Icons.stop, color: cs.onError, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (_service.partialTranscript?.isNotEmpty ?? false)
                ? _service.partialTranscript!
                : 'Mów…',
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // ready
    return Tooltip(
      message: 'Trzymaj, żeby nagrać wydatek głosem',
      child: GestureDetector(
        onTapDown: (_) => _startListening(),
        onTapUp: (_) => _stopListening(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer,
          ),
          child: Icon(Icons.mic, color: cs.onPrimaryContainer),
        ),
      ),
    );
  }
}
