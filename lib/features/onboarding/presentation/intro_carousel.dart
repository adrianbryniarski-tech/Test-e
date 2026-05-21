import 'package:flutter/material.dart';

/// Carousel powitalny pokazywany przy pierwszym uruchomieniu apki
/// (przed logowaniem). 4 strony wyjaśniające co apka robi i jak połączyć
/// się z partnerem. Po ostatniej stronie `onFinish` zamyka intro.
class IntroCarousel extends StatefulWidget {
  const IntroCarousel({required this.onFinish, super.key});

  final VoidCallback onFinish;

  @override
  State<IntroCarousel> createState() => _IntroCarouselState();
}

class _IntroCarouselState extends State<IntroCarousel> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _IntroPage(
      emoji: '🏠',
      title: 'Nasz budżet domowy',
      body: 'Wspólny budżet dla Was dwojga. Wszystkie wydatki i dochody '
          'w jednym miejscu, synchronizowane na żywo między telefonami.',
    ),
    _IntroPage(
      emoji: '🎤',
      title: 'Dodawaj szybko',
      body: 'Stuknij + żeby dodać wydatek lub dochód. Albo przytrzymaj '
          'mikrofon i powiedz: „50 złotych Biedronka wczoraj" — apka sama '
          'wypełni formularz. Działa offline, bez internetu.',
    ),
    _IntroPage(
      emoji: '🤝',
      title: 'Połączcie się',
      body: 'Jedna osoba tworzy gospodarstwo i dostaje kod (np. ABC-XYZ). '
          'Druga wpisuje ten kod przy rejestracji. Od teraz widzicie te '
          'same transakcje na obu telefonach.',
    ),
    _IntroPage(
      emoji: '📊',
      title: 'Pełna kontrola',
      body: 'Ustaw budżety miesięczne, oglądaj wykresy, dostosuj kategorie '
          'i motyw. Wszystko działa też bez zasięgu — sync gdy wróci '
          'internet.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinish,
                child: const Text('Pomiń'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            // Wskaźnik stron (kropki).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Zaczynamy!' : 'Dalej'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 96)),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
