import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/voice_input_service.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/voice_parser.dart';
import 'package:nasz_budzet_domowy/shared/widgets/manga_icons.dart';

/// Ikona mikrofonu w AppBar. Po stuknięciu otwiera arkusz „Dodaj głosem"
/// (instrukcja + przykłady + przełącznik nagrywania). Stany:
/// - unavailable → mic_off, stuknięcie prowadzi do Ustawień (pobierz model)
/// - loading     → spinner (model się ładuje)
/// - inaczej     → mic, stuknięcie otwiera arkusz
class VoiceInputButton extends ConsumerStatefulWidget {
  const VoiceInputButton({
    required this.categories,
    required this.onResult,
    super.key,
  });

  final List<Category> categories;
  final void Function(VoiceParseResult result) onResult;

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton> {
  final _service = VoiceInputService.instance;

  @override
  void initState() {
    super.initState();
    _service
      ..addListener(_rebuild)
      ..init();
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openSheet() async {
    final transcript = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _VoiceSheet(),
    );
    if (!mounted || transcript == null || transcript.trim().isEmpty) return;
    final result = VoiceParser(widget.categories).parse(transcript);
    widget.onResult(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rozpoznano: „$transcript". Sprawdź i zapisz.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _service.status;

    if (status == VoiceStatus.unavailable) {
      return IconButton.outlined(
        tooltip: 'Model głosu niegotowy — stuknij, aby pobrać w Ustawieniach',
        onPressed: () => context.push('/settings'),
        icon: const AppIcon(Icons.mic_off_outlined),
      );
    }

    if (status == VoiceStatus.loading) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isManga = ref.watch(themeVariantProvider) == AppThemeVariant.manga;
    return IconButton(
      tooltip: 'Dodaj głosem',
      onPressed: _openSheet,
      icon: isManga
          ? const MangaIcon(MangaIconKind.mic)
          : const AppIcon(Icons.mic),
    );
  }
}

/// Arkusz nagrywania: instrukcja, przykłady komend i duży przycisk
/// stuknij-by-nagrać / stuknij-by-zakończyć. Po zakończeniu zwraca
/// transkrypt przez `Navigator.pop`.
class _VoiceSheet extends ConsumerStatefulWidget {
  const _VoiceSheet();

  @override
  ConsumerState<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends ConsumerState<_VoiceSheet> {
  final _service = VoiceInputService.instance;
  bool _closing = false;

  static const _examples = [
    '„50 zł Biedronka wczoraj"',
    '„120 złotych Orlen"',
    '„apteka 30 zł dzisiaj"',
    '„pensja 5000" (dochód)',
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_service.status == VoiceStatus.ready) {
      await _service.startListening();
    } else if (_service.status == VoiceStatus.listening) {
      _closing = true;
      final transcript = await _service.stopListening();
      if (!mounted) return;
      Navigator.of(context).pop(transcript);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = _service.status;
    final listening = status == VoiceStatus.listening;
    final processing = status == VoiceStatus.processing || _closing;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dodaj głosem', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            listening
                ? 'Słucham… mów teraz. Gdy skończysz — stuknij, żeby zakończyć.'
                : 'Stuknij mikrofon i powiedz np. „50 zł Biedronka wczoraj". '
                    'Stuknij ponownie, żeby zakończyć.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: processing ? null : _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening ? cs.error : cs.primaryContainer,
                ),
                child: processing
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (!listening &&
                            ref.watch(themeVariantProvider) ==
                                AppThemeVariant.manga)
                        ? MangaIcon(
                            MangaIconKind.mic,
                            size: 44,
                            color: cs.onPrimaryContainer,
                          )
                        : Icon(
                            listening ? Icons.stop : Icons.mic,
                            size: 44,
                            color:
                                listening ? cs.onError : cs.onPrimaryContainer,
                          ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              listening
                  ? (_service.partialTranscript?.isNotEmpty ?? false)
                      ? _service.partialTranscript!
                      : '…'
                  : processing
                      ? 'Przetwarzam…'
                      : 'Stuknij, żeby nagrać',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (_service.lastError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _service.lastError!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onErrorContainer),
              ),
            ),
            if (_service.micPermanentlyDenied) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _service.openSystemSettings,
                icon: const AppIcon(Icons.settings),
                label: const Text('Otwórz ustawienia'),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Text('Przykłady', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ex in _examples)
                Chip(
                  label: Text(ex),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rozumiem: kwotę, datę (dziś / wczoraj / „13 marca"), sklep lub '
            'nazwę kategorii, oraz dochód (np. „pensja", „wpłynęło").',
            style:
                theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
