# Nasz budżet domowy

Aplikacja mobilna do zarządzania budżetem domowym dla dwóch osób, z synchronizacją między telefonami, **wejściem głosowym po polsku działającym offline**, importem wyciągów bankowych i deduplikacją wpisów.

**Stack**: Flutter (Android) + Supabase (Postgres + Auth + Realtime + Storage) + Vosk (offline ASR).

**Filozofia**: bezkosztowa (0 zł/mc), tylko do własnego użytku, dystrybucja przez APK + sideload (bez Google Play).

## Funkcje (MVP — v1)

- Dwa konta + jedno wspólne gospodarstwo (zaproszenie kodem)
- Sync w czasie rzeczywistym między telefonami (Supabase Realtime, respektuje RLS)
- **Trzy ścieżki wprowadzania transakcji**:
  - ręczna (formularz z maską PLN)
  - **głosowa po polsku — offline** (Vosk, ~50 MB model na urządzeniu)
  - import wyciągów (CSV/XML w v2, PDF w v3)
- Twarda deduplikacja przez `UNIQUE(household_id, sha256(date || amount || normalized_description))`
- Offline-first: lokalna SQLite + kolejka write-behind, sync gdy online
- Dashboard bento (Material 3, low-stimulus paleta, dark mode) z **pickerem zakresu dat**
- Kategorie z pełnym CRUD-em + oznaczeniem kolorystycznym i ikoną

## Status

Faza implementacji: ticket 1/7 (scaffold + theme + env). Patrz: [plan implementacji](./docs/plan.md).

## Setup deweloperski

### Wymagane

- Flutter SDK ≥ 3.24
- Konto Supabase (free tier) — tworzy użytkownik, claude nie ma uprawnień

### Zmienne środowiskowe (przekazywane przez `--dart-define`)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

### Migracje DB

```bash
supabase link --project-ref <ref>
supabase db push
```

## Licencja

Prywatny projekt, brak licencji do redystrybucji.
