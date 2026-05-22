// Wielolinijkowe stringi w `changes` są celowe (długie opisy łamane do 80
// znaków) — wyłączamy regułę adjacent strings.
// ignore_for_file: no_adjacent_strings_in_list

/// Lista zmian „Co nowego" — najnowszy wpis na górze.
///
/// Po KAŻDEJ aktualizacji dopisz nowy [ChangelogEntry] na początku listy
/// (zwykłym, nietechnicznym językiem — to czyta rodzina, nie programista).
/// `version` musi być unikalne dla każdego wpisu — na jego podstawie apka
/// pokazuje okienko „Co nowego" raz, po wejściu do nowej wersji.
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.changes,
  });

  /// Unikalny klucz wpisu (np. data). Zmiana = pokaż auto-okienko raz.
  final String version;
  final String date;
  final String title;
  final List<String> changes;
}

const List<ChangelogEntry> kChangelog = [
  ChangelogEntry(
    version: '2026-05-22',
    date: '22 maja 2026',
    title: 'Wygodniejszy głos, nowe wyglądy i podkategorie',
    changes: [
      'Dodawanie głosem jest prostsze: stukasz mikrofon (nie trzeba już '
          'trzymać), a w okienku masz instrukcję i przykłady komend.',
      'Nowe wyglądy: Kredka (komiksowy — czarne kontury i kropkowy raster), '
          'Plastelina i Aurora. Motywy różnią się teraz też kształtami '
          'przycisków i kart, nie tylko kolorem. Wybierzesz w Ustawieniach.',
      'Podkategorie: pod kategorią główną (np. „Transport") możesz mieć '
          'podkategorie (np. „Paliwo"). Na wykresie liczą się do głównej.',
      'Nowy ekran „Co nowego" — tutaj po każdej aktualizacji zobaczysz '
          'krótko, co się zmieniło.',
    ],
  ),
];

/// Klucz najnowszego wpisu — do porównania z zapamiętanym „ostatnio widziano".
String get currentChangelogVersion => kChangelog.first.version;
