// Multi-line stringi w listach `steps` są intencjonalne (długi tekst
// instrukcji łamany dla limitu 80 znaków) — wyłączamy regułę adjacent
// strings dla tego pliku.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:flutter/material.dart';

/// Statyczny ekran pomocy — instrukcje krok-po-kroku. Dostępny zawsze
/// z Ustawień. Cel: żeby właściciel apki nie musiał każdej nowej osobie
/// tłumaczyć "jak połączyć z partnerem" itd.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomoc')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: const [
          _HelpSection(
            emoji: '🤝',
            title: 'Jak połączyć się z partnerem/ką',
            steps: [
              'TY (pierwsza osoba): na ekranie startowym wybierz '
                  '„Stwórz nowe gospodarstwo", nadaj nazwę.',
              'Dostaniesz 6-znakowy kod (np. ABC-XYZ). Skopiuj go.',
              'Wyślij kod partnerowi (SMS, Telegram, cokolwiek).',
              'PARTNER: instaluje tę samą apkę, zakłada konto na swój '
                  'email + hasło.',
              'Na ekranie startowym wybiera „Mam kod zaproszenia", '
                  'wpisuje Twój kod → „Dołącz".',
              'Gotowe — od teraz widzicie te same transakcje na obu '
                  'telefonach, na żywo.',
            ],
          ),
          _HelpSection(
            emoji: '🔑',
            title: 'Gdzie znaleźć kod zaproszenia później',
            steps: [
              'Zakładka „Transakcje" (dolny pasek).',
              'Ikona 👤+ w prawym górnym rogu.',
              'Pokaże aktualny kod + przycisk „Kopiuj". Możesz też '
                  'wygenerować nowy.',
            ],
          ),
          _HelpSection(
            emoji: '➕',
            title: 'Jak dodać wydatek / dochód',
            steps: [
              'Stuknij duży przycisk + (prawy dolny róg).',
              'Wybierz Wydatek lub Dochód.',
              'Wpisz kwotę, wybierz kategorię, datę (domyślnie dziś).',
              'Opcjonalnie dodaj opis. Stuknij „Zapisz".',
            ],
          ),
          _HelpSection(
            emoji: '📊',
            title: 'Pulpit — co widać na głównym ekranie',
            steps: [
              'Pulpit to Wasz szybki podgląd pieniędzy w wybranym okresie.',
              'Na górze wybierasz okres (ten miesiąc, 3 miesiące, rok…) — '
                  'wszystkie wykresy dopasowują się do niego.',
              'Saldo = dochody minus wydatki. Kolor/strzałka pokazuje, czy '
                  'jest lepiej czy gorzej niż w poprzednim takim okresie.',
              'Kółko (wykres kołowy) pokazuje, na co idą pieniądze wg '
                  'kategorii. Wydatki podkategorii liczą się do kategorii '
                  'głównej.',
              'Słupki i linia pokazują wpływy/wydatki oraz jak rosło lub '
                  'malało saldo w czasie.',
            ],
          ),
          _HelpSection(
            emoji: '🎤',
            title: 'Jak dodać głosem',
            steps: [
              'Najpierw w Ustawieniach → „Sterowanie głosem" pobierz '
                  'model głosu (~50 MB) — jednorazowo, najlepiej przez Wi-Fi.',
              'Potem na ekranie dodawania transakcji stuknij ikonę '
                  'mikrofonu (prawy górny róg).',
              'Przytrzymaj i powiedz np. „pięćdziesiąt złotych Biedronka '
                  'wczoraj".',
              'Apka sama wypełni kwotę, kategorię i datę — sprawdź '
                  'i zapisz.',
            ],
          ),
          _HelpSection(
            emoji: '🏷️',
            title: 'Kategorie i podkategorie',
            steps: [
              'Zakładka „Kategorie" (dolny pasek) — osobno wydatki '
                  'i dochody.',
              'Ikona + u góry → nowa kategoria (nazwa, kolor, ikona, typ).',
              'Przy każdej kategorii głównej jest „+" — dodaje podkategorię '
                  '(np. pod „Transport" → „Paliwo", „Serwis").',
              'Podkategorię wybierzesz przy dodawaniu transakcji; na wykresie '
                  'jej wydatki liczą się do kategorii głównej.',
              'Własne: stuknij by edytować, przesuń w lewo by usunąć '
                  '(z przeniesieniem transakcji). Systemowe są zablokowane.',
            ],
          ),
          _HelpSection(
            emoji: '🗑️',
            title: 'Jak usunąć pomyłkę',
            steps: [
              'Na liście transakcji przesuń wpis palcem w lewo.',
              'Potwierdź w okienku „Usuń".',
            ],
          ),
          _HelpSection(
            emoji: '🎯',
            title: 'Jak ustawić budżet miesięczny',
            steps: [
              'Zakładka „Budżety" (dolny pasek).',
              'Ikona + → wybierz kategorię wydatków, wpisz kwotę.',
              'Pasek pokaże ile już wydaliście: zielony / żółty / '
                  'czerwony (przekroczone).',
            ],
          ),
          _HelpSection(
            emoji: '📈',
            title: 'Inwestycje (krypto, złoto, srebro)',
            steps: [
              'Zakładka „Inwestycje" (dolny pasek).',
              'Ikona + → wybierz krypto / złoto / srebro, podaj ilość, '
                  'datę i cenę zakupu.',
              'Cenę możesz wpisać w PLN, USD lub EUR — przeliczymy na PLN '
                  'po kursie NBP z dnia zakupu.',
              'Dokupienie tego samego aktywa scala się w jedną pozycję '
                  'ze średnią ceną zakupu.',
              'Wartość i zysk/strata liczą się po aktualnych kursach; '
                  'wykres pokazuje wartość portfela w czasie.',
            ],
          ),
          _HelpSection(
            emoji: '🎨',
            title: 'Jak zmienić wygląd i animacje',
            steps: [
              'Zakładka „Transakcje" → ⋮ (3 kropki) → „Ustawienia".',
              'Wybierz jeden z 11 motywów (m.in. Kredka, Plastelina, '
                  'Aurora) + tryb jasny/ciemny.',
              'Niżej — włącz/wyłącz pojedyncze animacje i dźwięki.',
            ],
          ),
          _HelpSection(
            emoji: '🔄',
            title: 'Coś się nie odświeża?',
            steps: [
              'Pociągnij listę palcem od góry w dół (pull-to-refresh).',
              'Albo stuknij ikonę 🔄 w pasku u góry.',
              'Dane synchronizują się automatycznie gdy jest internet.',
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.emoji,
    required this.title,
    required this.steps,
  });

  final String emoji;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
