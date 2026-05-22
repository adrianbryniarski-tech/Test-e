# Nasz budżet domowy — wskazówki dla Claude

## Zasady pracy

- **Pomoc w apce musi nadążać za funkcjami.** Przy dodawaniu nowej funkcji
  lub zmianie istniejącej zawsze sprawdź i zaktualizuj ekran Pomocy:
  `lib/features/onboarding/presentation/help_screen.dart`
  (sekcje `_HelpSection` z krokami). Jeśli funkcja zmienia sposób obsługi
  (np. „model głosu pobierasz w Ustawieniach"), popraw też odpowiednie
  kroki, nie tylko dodawaj nowe.

## Przed zakończeniem zadania

- `flutter analyze --no-pub` — czysto.
- `flutter test --no-pub` — zielone (znany flaky: `pending_ops_dao_test`
  `watchForHousehold` — przechodzi w izolacji).
- Zmiany schematu bazy → nowa migracja w `supabase/migrations/` z kolejnym
  numerem; nie edytuj już zaaplikowanych migracji.
- Po zmianie migracji / RLS / RPC uruchom testy bazy na prawdziwych
  migracjach: `bash supabase/test/run_db_tests.sh --local` (te same testy
  odpala CI w jobie „DB tests"). Asercje w `supabase/test/tests/*.sql`.
