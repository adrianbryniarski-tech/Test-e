# "Nasz budżet domowy" — plan implementacji

## Kontekst

Repo `Test-e` jest praktycznie puste (sam README). Budujemy od zera **aplikację "Nasz budżet domowy"** — do zarządzania budżetem domowym dla dwóch osób (użytkownik + żona).

- **Nazwa wyświetlana** (UI, splash screen, `AndroidManifest.xml` `android:label`, Google Play): **Nasz budżet domowy**.
- **Package id** na Androidzie: `pl.naszbudzetdomowy.app` (do potwierdzenia przy konfiguracji Google Play; nie da się zmienić po publikacji).
- **Zmiana nazwy repo GitHub** z `adrianbryniarski-tech/test-e` → `adrianbryniarski-tech/nasz-budzet-domowy` (slug ASCII, GitHub nie akceptuje polskich znaków ani spacji w nazwach repo).
  - **Wykonanie**: GitHub → repo → Settings → General → Repository name → wpisać `nasz-budzet-domowy` → Rename. GitHub automatycznie ustawia HTTP redirects ze starych URLi.
  - **Lokalnie po rename**: `git remote set-url origin git@github.com:adrianbryniarski-tech/nasz-budzet-domowy.git` (lub `https://...`).
  - **Lokalny katalog** `/home/user/Test-e` może zostać (kosmetyka) lub przemianować na `nasz-budzet-domowy` — bez wpływu na funkcjonalność.
  - **Ostrzeżenie o tej sesji**: GitHub MCP tej sesji jest zrestryktowany do `adrianbryniarski-tech/test-e`. Po zmianie nazwy na GitHubie MCP w tej sesji prawdopodobnie przestanie działać (whitelist nazw). **Rekomendacja: zrobić rename po skończeniu prac w tej sesji** (po zacommitowaniu i pushnięciu wszystkich zmian), albo na początku kolejnej sesji.
  - **README** zaktualizować na "Nasz budżet domowy" jako tytuł + krótki opis.

### Wymagania potwierdzone przez użytkownika

- **Dwa telefony z Androidem**, jedno wspólne gospodarstwo budżetowe, sync w czasie rzeczywistym między urządzeniami.
- **Trzy ścieżki wprowadzania danych**: ręczna, **głosowa po polsku** ("150 złotych zakupy w Biedronce wczoraj"), import wyciągów bankowych (PKO BP, ING, Santander, Millennium, Pekao; CSV/XML preferowane, PDF wymagany w drugiej kolejności).
- **Deduplikacja** — żadnych dubli, gdy ta sama transakcja trafi z wpisu ręcznego i z importu wyciągu.
- **Dashboard z wykresami**, nowoczesny niskobodźcowy design 2026 (bento grid, Material 3, dark mode, duża typografia).
- **Podsumowanie za dowolny wskazany okres** — picker zakresu dat na górze dashboardu z presetami (bieżący miesiąc, poprzedni miesiąc, ostatnie 3M / 6M / 12M, bieżący rok / YTD, poprzedni rok, wszystko) **oraz własnym zakresem od-do**. Wszystkie KPI, wykresy i lista transakcji filtrowane po wybranym okresie. Wybór persistowany per użytkownik (lokalnie w `shared_preferences`).
- **Zarządzanie kategoriami** — pełny CRUD (dodawanie, edycja, usuwanie własnych), z polityką "co z transakcjami w usuniętej kategorii" (musisz wybrać kategorię docelową przed usunięciem). Kategorie systemowe (seed PL) — chronione przed usunięciem, ale dopuszczalne ukrycie z UI.
- **Wizualne oznaczenie kategorii** — każda kategoria ma **kolor** (z palety 12 niskobodźcowych odcieni) i **ikonę** (z `Material Symbols`, picker w UI), używane spójnie w liście transakcji (kółko z ikoną + akcent koloru), na wykresie pie (segmenty), na chipach filtrów, w wynikach voice.
- Konta: każdy małżonek ma swoje logowanie, łączą się w jedno "gospodarstwo" przez zaproszenie.

Cel: dostarczyć MVP (v1), który będzie używalny od pierwszego tygodnia, i mieć jasną roadmapę do v4 bez przebudowy fundamentów.

### Ograniczenia twarde (potwierdzone)

- **Apka bezkosztowa** — wszystkie usługi w darmowych planach, **0 zł / miesiąc** w stanie ustalonym.
- **Tylko własny użytek** (dla 2 osób), **bez publikacji w Google Play** — dystrybucja przez APK + sideload (Settings → Apps → Install unknown apps → włącz dla menedżera plików / przeglądarki).

### Wpływ na decyzje (co wycinamy / zostawiamy)

| Decyzja | Z powodu |
|---|---|
| **Brak iOS** | Apple Developer Program = $99/rok. Zostajemy przy Androidzie. |
| **Brak Google Play** | Brak konta deweloperskiego ($25 jednorazowo, ale i tak skip — niepotrzebne dla 2 osób). Build `flutter build apk --release`, podpis własnym keystore'em, transfer przez Telegram/USB. |
| **Brak FCM push** | FCM jest free, ale wymaga Firebase project — dorzuca komplikację i drugi backend. Zamiast tego **`flutter_local_notifications`** — alerty triggerowane lokalnie przez polling Realtime (i tak słuchamy). |
| **Kontomatik OUT** całkowicie | Enterprise pricing, niedostępne dla apki domowej. Własne parsery CSV/PDF na zawsze. |
| **LLM voice fallback** (Claude Haiku w v4) — przeniesione do "do rozważenia", nie planowane | Anthropic API kosztuje (~$0.25/M input tokens). Przy 100 wydatkach/mc i ~50 tokenów na transkrypt to <$0.01/mc, ale "0 zł" = 0 zł. Regex-only wystarczy. |
| **Supabase Free Tier** | Realne limity 2026: 500 MB DB / 1 GB Storage / 50k MAU / 200 concurrent realtime connections / 2M realtime msgs/mc / 500k Edge Function invocations/mc / 5 GB egress (DB) + 5 GB cached + 5 GB storage egress / **2 active projects**. Dla 2 osób z OGROMNYM zapasem (100 transakcji/mc × ~1 KB ≈ 1.2 MB/rok). **⚠️ Brak automatycznych backupów na free tier** — robimy własne (sekcja Observability). **⚠️ Projekt pauzuje się po 7 dniach bez API requests** — keep-alive przez GitHub Actions cron. |
| **Sentry Free** (5k errors/mc) | Wystarczy dla apki dla 2 osób. Alternatywnie: tylko Supabase Logs (też free). |
| **Email sender** = wbudowany Supabase Auth (30 maili/h limit) | Magic linki + invite, wystarczy bezkosztowo. Brak Resend / SendGrid. |
| **Brak custom domeny** | Magic link idzie z `*.supabase.co` — bezpłatnie, w pełni funkcjonalne. |
| **Backupy** | Supabase free daily backupy + dodatkowo **user-initiated JSON export** zapisywany na telefon (nasza implementacja, 0 zł). Bez S3 / R2. |

---

## Podział pracy: co robię ja (Claude), a co Ty musisz zrobić sam

**Krótko**: cały kod, migracje, testy, commity, push, PR, CI/CD — **TY nie dotykasz**. Ja to robię z czatu, Ty tylko zatwierdzasz polecenia w UI Claude Code. ALE **kilku rzeczy fizycznie nie mogę zrobić** — wymagają Twoich kliknięć w cudzych UI (Supabase, GitHub Settings, telefon Androidem), bo nie mam tam konta na siebie.

### Co robię ja sam (zero Twoich kliknięć)

| Zadanie | Jak |
|---|---|
| Cały kod Flutter, migracje SQL, Edge Functions Deno | Edit/Write na plikach repo |
| Strukturyzacja projektu, theme, pakiety | Bash + Edit |
| Commit, push do branchu, draft PR | Bash (git) + GitHub MCP |
| Workflow GitHub Actions (`ci.yml`, `build-apk.yml`, `keepalive.yml`, `backup.yml`) | Edit yaml + commit |
| Testy unit / widget / integration | Edit + lokalny `flutter test` w kontenerze |
| Pisanie / modyfikacja README | Edit |
| Dodawanie nowych funkcji wg Twoich poleceń z czatu | jw. |
| Fixy CI po failach | Reading workflow logs (GitHub MCP) + Edit |

### Co musisz zrobić Ty (jednorazowo, ~15 min łącznie)

| Zadanie | Czas | Jak / dlaczego |
|---|---|---|
| **1. Założyć konto Supabase** | 2 min | https://supabase.com → Sign up (email + GitHub OAuth). Nie mam jak — wymaga akceptacji ToS przez osobę fizyczną. |
| **2. Stworzyć projekt Supabase** | 2 min (+5 min provisioning w tle) | W panelu Supabase: New Project → wybierz region (Frankfurt EU najbliżej), wpisz silne DB password (zapisz w password managerze), wybierz Free tier. |
| **3. Skopiować 3 sekrety Supabase** | 1 min | Project Settings → API → kopia: `Project URL`, `anon public key`. Project Settings → Database → kopia: `Connection string` (URI). Wklej do mnie na czat. |
| **4. Wkleić sekrety do GitHub Secrets** | 2 min | Repo → Settings → Secrets and variables → Actions → New repository secret. Dodać: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_DB_URL`, `SUPABASE_SERVICE_ROLE_KEY`. GitHub MCP **nie ma** uprawnień write na secrets — Ty musisz wkleić. |
| **5. Zainstalować Supabase CLI lokalnie** (opcjonalne, dla debugowania) | 2 min | `brew install supabase/tap/supabase` (Mac) lub `scoop install supabase` (Windows). Bez tego dasz radę — CI robi `supabase db push`. |
| **6. Wygenerować keystore Android** | 2 min | `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` — zapamiętaj hasła. Zachowaj keystore w bezpiecznym miejscu (password manager, nie repo!). Wklej Base64 keystore + hasła do GitHub Secrets jako `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`. |
| **7. Zmienić nazwę repo GitHub** | 30 s | https://github.com/adrianbryniarski-tech/test-e/settings → Repository name → `nasz-budzet-domowy` → Rename. GitHub MCP nie ma operacji `rename_repository`. |
| **8. Pobrać APK i zainstalować na swoim telefonie** | 5 min (pierwszy raz) | Po pierwszym buildzie CI: Actions → run → artefakt `app-arm64-v8a-release.apk` → download → otwórz na telefonie → Install (musisz włączyć "Install unknown apps" dla menedżera plików/przeglądarki, jednorazowo). |
| **9. Wysłać APK żonie + jej zaproszenie** | 2 min | Po stworzeniu gospodarstwa apka pokaże kod zaproszenia (np. `ABC-XYZ`). Wyślij żonie APK przez Telegram/Signal + kod, ona zainstaluje i wpisze. |

### Czego nie zrobimy w ogóle

| Nie | Powód |
|---|---|
| Konto Google Play / publikacja | $25 jednorazowo + apka tylko dla 2 osób → niepotrzebne. Sideload APK. |
| Konto Apple Developer / iOS | $99/rok + nikt nie ma iPhone'a. |
| Konto Firebase (FCM) | Drugi backend, niepotrzebny — `flutter_local_notifications` wystarczy. |
| Konto Sentry | Opcjonalne — Supabase Logs wystarczą. Włączymy gdy będzie potrzebne. |
| Konto na zewnętrznych aggregatorach (Kontomatik) | Enterprise pricing. |

### Tryb pracy na czacie

Po jednorazowym setup (kroki 1-7 powyżej) cała dalsza praca to **"Adrian: zrób X" → Claude robi X → commit + push + PR → Adrian zatwierdza w czacie**. Włącznie z:
- nowe funkcje ("dodaj eksport do Excela")
- bugfixy ("ta kategoria nie zapisuje się")
- redesign ("zmień paletę na bardziej kontrastową")
- migracje DB ("dodaj pole 'merchant' do transakcji")
- nowy parser banku ("dodaj support dla Aliora")

Jedyne kolejne Twoje fizyczne akcje po setupie:
- Pobierz APK z CI i zainstaluj/zaktualizuj na telefonach (przy ważniejszych releasach).
- Zaakceptuj nowe sekrety / migracje DB jeśli będą breaking.

---

## Filozofia projektowania (Agentic Engineering, zgodnie z Karpathy)

Apka trzyma **pieniądze i dane finansowe rodziny** — pracujemy w trybie **Agentic Engineering**, nie Vibe Coding. Konkretnie:

1. **Spec to nowy kod**. Ten plan + acceptance criteria per ticket + snapshot/integration testy są kontraktem. Agent (Claude) wykonuje je krok po kroku, człowiek waliduje na gateach. Detale typu składnia konkretnej funkcji Supabase/Flutter są oddane "praktykantowi" — plan ma być wykonywalny.
2. **"You can outsource your thinking, but not your understanding"**. Człowiek musi rozumieć: schemat DB, polityki RLS, strategię deduplikacji, model uprawnień. Te 4 rzeczy weryfikujemy ręcznie testami, nie ślepo akceptujemy.
3. **Małe, zweryfikowane iteracje**. Każdy ticket kończy się działającym, używalnym stanem. Nie commitujemy "WIP, wraca jutro". 5 ticketów = 5 PR-ów.
4. **Discipline + security first**. Dane finansowe = RLS na każdej tabeli, testy RLS w CI, Sentry bez treści transakcji, MFA opcjonalne.
5. **Gates of human review** (rzeczy które człowiek musi ręcznie zatwierdzić, nie agent):
   - Migracje SQL przed `db push` (Claude proponuje, człowiek czyta).
   - Polityki RLS przed włączeniem (testy `supabase/tests/` zielone + ręczny przegląd).
   - Pierwsza wersja parsera per bank (na realnych plikach, niedostarczanych do repo).
   - Jakakolwiek zmiana w `accept_invitation` / RPC z `security definer`.

---

## Build vs buy — sanity check (heurystyka MenuGen)

Zanim zbudujemy 100% custom, zadajemy 3 pytania (z odpowiedziami dla naszego case):

| Pytanie | Odpowiedź | Decyzja |
|---|---|---|
| Czy gotowa apka (Spendee/Money Lover/YNAB/Revolut Vaults) tego nie robi? | Tak, ale: brak PL voice input do dodawania transakcji + brak importu PL wyciągów + brak naszej polityki deduplikacji + większość freemium z limitami i obcą jurysdykcją danych. | Build własne. |
| Czy gotowy aggregator open-banking (Kontomatik, Tink, TrueLayer, Yapily, Salt Edge) zwolni nas z parsowania CSV/PDF? | **Kontomatik** ma PSD2 + PDF parsing dla 100+ banków w PL/EU. ALE: pricing "skontaktuj sprzedaż" (enterprise), wymaga podpisanego kontraktu, koszty per-wywołanie. Sprzeczne z "0 zł". | Build własne parsery. Kontomatik OUT na zawsze (przy obecnym profilu kosztowym). |
| Czy nowy model LLM zrobi to natywnie bez własnej apki? | Nie — sync między urządzeniami, RLS, dedup, push-to-talk to obowiązkowe natywne integracje. LLM byłby tylko komponentem do parsowania voice/PDF. | Build apkę, **bez** LLM-komponentu (regex-only — koszty Anthropic API sprzeczne z "0 zł"). Re-rozważyć dopiero gdy regex okaże się za słaby. |

---

## Stack technologiczny (decyzje)

| Warstwa | Wybór | Uzasadnienie (1 zdanie) |
|---|---|---|
| Frontend | **Flutter (Android target)** | Decyzja użytkownika; jeden kod źródłowy, łatwe rozszerzenie na iOS w v4. |
| Backend | **Supabase (Postgres + Auth + Realtime + Storage + Edge Functions)** | Postgres niezbędny do raportów (SUM po kategoriach, miesiącach), `UNIQUE` constraint do twardej deduplikacji, Realtime respektuje RLS, Edge Functions (Deno) do parsowania PDF, opcja self-hostingu (Docker) gdy prywatność stanie się problemem. Firebase odpada przez słabe agregacje i brak natywnych unique constraints. |
| Stan w Flutter | `flutter_riverpod` **3.0** + `riverpod_generator` + `riverpod_sqflite` (offline cache) | Wersja 3.0 ma compile-time safety, wbudowaną **offline persistence** (kluczowe dla apki używanej w sklepie bez zasięgu) i flagę `AsyncValue.isFromCache` — UI pokazuje "tryb offline / oczekuje sync" gdy dane z cache. Async providers mapują się 1:1 na `supabase.stream()`. |
| Sieć / online status | `connectivity_plus` + custom `OnlineStatusProvider` | Decyduje kiedy próbować sync, kiedy zostawić w lokalnej kolejce. |
| Routing | `go_router` | Typowane trasy + redirecty zależne od stanu auth. |
| Wykresy | `fl_chart` | Free, wystarczy na pie/bar/line; Syncfusion = licencja. |
| Voice | **`vosk_flutter`** (offline, pl model ~50 MB) | **KRYTYCZNE**: `speech_to_text` wymagałby internetu (Google Speech Services) — sprzeczne z "offline-first" (żona w Biedronce bez wifi nie zaloguje wydatku). Vosk to open-source on-device ASR z polskim modelem; działa offline, zero latency, głos NIGDY nie opuszcza telefonu (bonus prywatności), 0 zł. Limit: model w APK lub jednorazowy download przy onboardingu. |
| Modele | `freezed` + `json_serializable` | Immutable, typesafe. |
| Formularze | `reactive_forms` | Maskowanie kwoty, walidacje. |
| Daty/i18n | `intl` z `pl_PL`, `timeago` | "wczoraj/dziś" po polsku, `showDateRangePicker` zlokalizowany. |
| Persist preferencji | `shared_preferences` | Zakres dat dashboardu per użytkownik (lokalnie). |
| CSV | `csv` + `charset_converter` | PKO/Pekao eksportują Windows-1250. |
| PDF | **server-side**, Edge Function (Deno) + `unpdf` lub `pdfjs-dist` | Dart-owe parsowanie PDF jest słabe; PDF leci do prywatnego bucketu, function zwraca `StagedTransaction[]` do potwierdzenia. |
| Krypto (dedup hash) | `crypto` | SHA-256 po stronie klienta. |

---

## Schemat bazy (Supabase migracja `supabase/migrations/0001_init.sql`)

```sql
-- Gospodarstwa i członkowie
create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

create table household_members (
  household_id uuid references households(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text check (role in ('owner','member')) default 'member',
  joined_at timestamptz default now(),
  primary key (household_id, user_id)
);

create table invitations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,
  code text unique not null,                -- 6-znakowy kod
  invited_email text,
  expires_at timestamptz not null,
  accepted_by uuid references auth.users(id),
  accepted_at timestamptz
);

-- Kategorie (z seedem polskich domyślnych + custom per gospodarstwo)
create table categories (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,
  parent_id uuid references categories(id),
  name text not null,
  icon text, color text,
  is_system boolean default false
);

-- Transakcje
create type tx_source as enum ('manual','voice','csv_import','pdf_import');
create type tx_type   as enum ('income','expense');

create table statement_imports (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,
  bank text not null,
  file_path text not null,                  -- prywatny Storage bucket
  imported_by uuid references auth.users(id),
  imported_at timestamptz default now(),
  row_count int,
  status text
);

create table transactions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,
  created_by uuid references auth.users(id),
  occurred_at date not null,
  amount_cents bigint not null,             -- zawsze dodatnia, znak w `type`
  type tx_type not null,
  category_id uuid references categories(id),
  description text,
  note text,
  source tx_source not null,
  import_id uuid references statement_imports(id),
  dedup_hash text not null,
  created_at timestamptz default now(),
  unique (household_id, dedup_hash)         -- twarda deduplikacja
);
create index on transactions (household_id, occurred_at desc);

create table budgets (                       -- v4
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,
  category_id uuid references categories(id),
  period text check (period in ('monthly')) default 'monthly',
  amount_cents bigint not null,
  starts_on date not null
);
```

**RLS na każdej tabeli** (wzorzec):
```sql
alter table transactions enable row level security;
create policy "household members can read"
  on transactions for select
  using (household_id in (
    select household_id from household_members where user_id = auth.uid()
  ));
create policy "household members can write"
  on transactions for insert with check (
    household_id in (select household_id from household_members where user_id = auth.uid())
  );
-- analogicznie update/delete + analogicznie dla pozostałych tabel
```

Zaproszenia: funkcja `accept_invitation(code text)` jako `security definer` RPC — wstawia rekord do `household_members` po walidacji kodu (omija RLS w kontrolowany sposób).

---

## Deduplikacja — dwa poziomy

**Twarda** (constraint w DB):
```
dedup_hash = sha256( occurred_at_iso || amount_cents || normalize(description) )
normalize = lower + strip diacritics + collapse whitespace + remove punctuation
```
`UNIQUE(household_id, dedup_hash)` → próba wstawienia duplikatu zwraca błąd 23505 → klient pokazuje "to już jest w bazie".

**Miękka** (przy imporcie wyciągu):
- Dla każdej nowej transakcji z importu szukamy istniejących z tą samą `amount_cents` w oknie `occurred_at ± 2 dni` i podobnym opisem (Levenshtein lub trigram).
- Pokazujemy ekran "Potencjalne duplikaty" — użytkownik zaznacza które pominąć, reszta leci do commitu.

---

## Offline-first, idempotency, sync

Apka MUSI działać w sklepie bez zasięgu — w połowie przypadków transakcję dodajemy w Biedronce, gdzie wifi jest słabe.

- **Lokalny cache** przez Riverpod 3.0 offline persistence (`persist()` na Notifierach transakcji + `riverpod_sqflite` jako backend). Klient zawsze najpierw zapisuje do lokalnej SQLite, dopiero potem syncuje z Supabase.
- **Kolejka write-behind**: każda mutacja (insert/update/delete transakcji) idzie do tabeli `pending_ops` w lokalnym SQLite z `client_op_id uuid` (idempotency key). `OnlineStatusProvider` triggeruje workera który przepycha kolejkę gdy jest połączenie.
- **Idempotency w Supabase**: insert do `transactions` ma `client_op_id uuid unique not null` w schemacie. Retry tego samego op-a → 23505 → klient kasuje z kolejki bez błędu (zamiast tworzyć duplikat).
- **Konflikt sync** (przypadek krawędziowy: oboje dodali ten sam wydatek offline): `dedup_hash` UNIQUE constraint zadziała przy pushu drugiego klienta → ten zobaczy "ten wydatek już dodała żona" i propozycję usunięcia lokalnej kopii. Wygrywa first-write-wins na poziomie DB; UX wyjaśnia oba zapisy.
- **UI wskaźnik**: w nagłówku ikona ☁️ (synced) / ⏳ (czeka na sync, X operacji w kolejce) / ⚠️ (błąd sync, tap → szczegóły). `AsyncValue.isFromCache` rozróżnia źródło danych.

Schemat dorzucony do migracji:
```sql
alter table transactions add column client_op_id uuid;
create unique index on transactions (household_id, client_op_id) where client_op_id is not null;
```

---

## Voice (push-to-talk) — strategia parsowania

**Wybór ASR: `vosk_flutter` (offline, na urządzeniu).** Powód: apka jest offline-first, a Google Speech Services (na którym opiera się `speech_to_text`) wymaga internetu. W sklepie bez wifi voice musi działać. Vosk dla polskiego ma model small ~50 MB.

**Setup modelu**: w pierwszym uruchomieniu apka pyta "Pobrać model rozpoznawania głosu (50 MB, działa offline)?" → download z oficjalnego CDN Alphacephei do `getApplicationSupportDirectory()` → checksum SHA-256 weryfikacja. Bez modelu: voice FAB pokazuje "Wymagany model — pobierz w Ustawieniach". Nie bundlujemy w APK żeby nie nadmuchać do 70 MB.

**Flow**:
1. **Mikrofon FAB** na ekranie "Dodaj wydatek". Trzymaj → mówisz po polsku → puszczasz → Vosk zwraca transkrypt → parser wypełnia formularz.
2. **Parser: regex + heurystyki w Dart** (zamknięta gramatyka):
   - kwota: `\d+([.,]\d{1,2})?\s*(zł|złotych|pln)`
   - data: lookup `{wczoraj, dziś, przedwczoraj, poniedziałek, ..., niedziela}` → konkretna data
   - kategoria: fuzzy match po nazwach kategorii + aliasy ("Biedronka/Lidl/Żabka → Spożywcze", "Orlen/BP/Shell → Paliwo", "Apteka/Doz → Zdrowie")
3. **Brak LLM fallback** (skreślony — koszty Anthropic API sprzeczne z "0 zł", plus naruszałby offline-first). Jeśli regex nie wyłapie, formularz pokazuje to co rozpoznał + puste pola dla reszty — użytkownik dopisuje ręcznie. Jeśli statystyki pokażą >20% niedoparsowanych głosów, **wtedy** rozważymy lepszy parser (np. lokalny mały NER w `onnxruntime`), nadal offline.
4. Użytkownik **zawsze widzi wypełniony formularz przed zapisem** — głos nie wysyła w ciemno.
5. **Telemetria lokalna**: liczymy `voice_total`, `voice_parsed_ok`, `voice_partial`, `voice_failed` w lokalnej SQLite. W Ustawieniach: "Skuteczność voice: 87% (43/50 ostatnich)". Bez wysyłki do serwera.

---

## Kategorie — CRUD, polityka usuwania, oznaczenia wizualne

### Model danych

Tabela `categories` (już w schemacie) — dodatkowe ograniczenia w migracji 0001:

```sql
-- Kolor jako hex (#RRGGBB), ikona jako nazwa Material Symbol (string).
alter table categories
  add constraint color_format check (color ~ '^#[0-9A-Fa-f]{6}$'),
  add constraint icon_required check (icon is not null and length(icon) > 0);

-- Transakcje: usunięcie kategorii NIE jest dozwolone póki ma transakcje.
-- Zamiast ON DELETE SET NULL (gubi info), wymuszamy reasignment z UI.
alter table transactions
  alter column category_id set not null;

-- Indeks dla szybkiego sprawdzenia "ile transakcji ma kategoria X"
create index on transactions (category_id);
```

### Seed (12 kategorii systemowych, `is_system = true`)

Każda z ikoną Material Symbol + kolorem z palety low-stimulus (12 odcieni — green, lime, amber, orange, red, pink, purple, indigo, blue, teal, brown, slate):

| Kategoria | Ikona Material | Kolor |
|---|---|---|
| Spożywcze | `shopping_cart` | `#7AB87A` (zielony) |
| Rachunki | `receipt_long` | `#5B8FB9` (niebieski) |
| Transport | `directions_car` | `#E8A24A` (pomarańczowy) |
| Rozrywka | `theaters` | `#B97AB8` (fiołkowy) |
| Zdrowie | `local_pharmacy` | `#E07A7A` (czerwony) |
| Dzieci | `child_care` | `#E8C24A` (żółty) |
| Mieszkanie | `home_work` | `#8B7355` (brązowy) |
| Ubrania | `checkroom` | `#B95B8F` (różowy) |
| Pensja | `payments` | `#4AE89E` (jasnozielony, INCOME) |
| Inne dochody | `savings` | `#7AE0D5` (turkus, INCOME) |
| Oszczędności | `account_balance` | `#5B7AB9` (granatowy) |
| Inne | `more_horiz` | `#94A3B8` (slate) |

Seed wstawiany przez RPC `seed_categories_for_household(household_id)` wywoływane przy tworzeniu gospodarstwa (czyli przy `accept_invitation` lub `create_household`).

### UI zarządzania kategoriami

Ekran `/settings/categories`:

- **Lista** — sortowanie: systemowe na górze (oznaczone ikoną kłódki), własne niżej. Każdy rząd: kółko z ikoną + kolorem (40 px), nazwa, licznik transakcji ("23 transakcje"), akcje (edit, delete jeśli własna).
- **+ Dodaj kategorię** (FAB) → bottom sheet:
  - Pole "Nazwa" (required, unique per household, max 30 znaków).
  - Typ (Wydatek / Dochód) — wpływa na to gdzie się pokazuje w pickerach.
  - **Picker ikony** — grid 8×N ikon Material Symbols (~80 starannie dobranych, nie wszystkie 3000), search po nazwie.
  - **Picker koloru** — paleta 12 odcieni z palety low-stimulus (te same co seed), jeden tap = wybór.
  - Podgląd "tak będzie wyglądać": kółko + nazwa + przykładowa transakcja.
- **Edycja** kategorii systemowej — TYLKO ikona/kolor (nazwa zablokowana). Edycja własnej — wszystko.
- **Usunięcie** kategorii:
  - Jeśli 0 transakcji → confirm dialog "Usunąć '<nazwa>'?" → DELETE.
  - Jeśli N>0 transakcji → dialog **"Kategoria '<nazwa>' ma N transakcji. Wybierz kategorię docelową dla istniejących wpisów:"** + dropdown z innymi kategoriami (tego samego typu income/expense) → przed DELETE robimy UPDATE transactions SET category_id = $target WHERE category_id = $old, atomowo w transakcji DB (RPC `delete_category_with_reassign(old_id, target_id)` jako `security definer`, walidacja że obie kategorie są w tym samym gospodarstwie).
  - Systemowe kategorie — ukrywalne, nie usuwalne (przycisk "Ukryj" zamiast "Usuń"; tabela `category_visibility(household_id, category_id, hidden bool)` lub flaga w pamięci na froncie).

### Spójne użycie oznaczeń w UI

- Lista transakcji: kółko 32 px (ikona + kolor) po lewej, kwota po prawej, kolor akcentu zgodny z kategorią.
- Pie chart na dashboardzie: segmenty w kolorach kategorii, legenda z ikoną + nazwą.
- Chipy filtrów: tło w kolorze kategorii z 12% opacity, ikona + nazwa.
- Voice — gdy parser wyciągnął kategorię ("Biedronka → Spożywcze"), wynik widoczny w formularzu z tym samym oznaczeniem.

---

## Import wyciągów — strategia per-bank

- Interfejs `BankStatementParser` + wykrywanie banku po sygnaturze nagłówka pliku.
- **CSV/XML parsujemy na urządzeniu** (offline-capable, tanio, brak round-tripu).
- **PDF parsujemy w Edge Function asynchronicznie** (cold start Deno 200-400 ms, soft limit 2 s — blokujący call z apki to anty-pattern):
  1. Klient uploaduje plik → Supabase Storage `statements/{household_id}/{import_id}.pdf`.
  2. Klient robi INSERT do `statement_imports` ze statusem `pending` (nie wywołuje Function bezpośrednio).
  3. DB webhook / `pg_net` trigger na INSERT wywołuje Edge Function `parse-statement` w tle.
  4. Function pobiera plik (signed URL), `unpdf` ekstraktuje tekst, regex per bank → wstawia `StagedTransaction[]` do tabeli `staged_transactions` (z FK do `statement_imports`) + UPDATE statusu na `parsed` lub `error` (z komunikatem).
  5. Klient subskrybuje Realtime na zmianę statusu `statement_imports`, pokazuje toast "Wyciąg gotowy do potwierdzenia" → otwiera ekran z miękkim dedup → user commituje wybrane transakcje.
- Banki: zaczynamy od **ING (najczystszy CSV)** w v2. Kolejne dodajemy iteracyjnie — każdy bank = osobny moduł parsera w `parsers/`, testy snapshotowe na anonimizowanych próbkach plików (nie commitować realnych wyciągów do repo).
- **Kontomatik / Tink / TrueLayer**: OUT — sprzeczne z "0 zł" (enterprise pricing). Własne parsery na zawsze (przy obecnym profilu kosztowym).

Dorzucone tabele do migracji (osobna w v2 `0002_imports.sql`, nie w v1):
```sql
create table staged_transactions (
  id uuid primary key default gen_random_uuid(),
  import_id uuid references statement_imports(id) on delete cascade,
  occurred_at date not null,
  amount_cents bigint not null,
  type tx_type not null,
  description text,
  raw_payload jsonb,            -- całość linii źródłowej dla debugu
  is_likely_duplicate boolean default false,
  duplicate_of uuid references transactions(id),
  decision text check (decision in ('pending','skip','commit')) default 'pending'
);
```

---

## Bezpieczeństwo (dane finansowe)

- RLS włączone na każdej tabeli, bez wyjątków. Testy RLS w `supabase/tests/`.
- Auth: email + magic link (`signInWithOtp`) jako domyślne, opcjonalnie email/hasło. **TOTP MFA** włączane w ustawieniach.
- Storage bucket `statements`: prywatny, polityka RLS lustruje członkostwo w gospodarstwie, dostęp tylko przez krótkie signed URLs.
- `pg_cron` purge plików `statements/*` starszych niż 90 dni (rozparsowane transakcje zostają).
- Brak logowania `description` transakcji do Sentry/konsoli.
- Klucze Supabase wstrzykiwane przez `--dart-define` (nie commitowane).
- Android release: `android:allowBackup="false"`, R8/proguard, kluczowe stringi przez `--dart-define`.

---

## Observability, backups, disaster recovery (wszystko free)

- **Logi**: domyślnie tylko **Supabase Logs** (Postgres + Edge Functions + Auth — free). Wystarczy do diagnozowania błędów dla 2 osób. Sentry **opcjonalnie** — free tier 5k errors/mc; włączamy gdy regex/sync zacznie sprawiać problemy. Ze scrubberem `beforeSend` który usuwa `description`, `note`, `amount_cents`, `email` (dane finansowe nie idą do zewnętrznego logger-a).

### Backupy (free tier NIE MA automatycznych — robimy własne)

Supabase free tier **nie udostępnia automatycznych backupów** (są dopiero od Pro $25/mc). Strategia bezkosztowa:

1. **In-app "Pobierz moje dane"** w Ustawieniach — JSON dump wszystkich transakcji + kategorii + zaproszeń tego gospodarstwa, zapisywany jako plik na telefon. Działa offline (z lokalnej SQLite), niezależny od Supabase. UI ma cotygodniowy przypominajka "Ostatni backup: 9 dni temu — zrób export".
2. **GitHub Actions weekly DB dump** (`.github/workflows/backup.yml`, cron `0 3 * * 0`):
   - Job na free runnerze (~5 min, w budżecie 2000 min/mc).
   - Używa `supabase db dump --db-url $SUPABASE_DB_URL` (service role w sekretach GH).
   - Commituje SQL dump do **prywatnego repo** `nasz-budzet-domowy-backups` (GitHub free dla prywatnych repo bez limitu rozmiaru rozsądnego).
   - Retencja: ostatnie 12 dumpów (rotacja przez actions).
   - Trigger także manualny (`workflow_dispatch`) — gdy chcemy backup before-change.
3. **Storage backupy** (`statements/` bucket, v3+): w tym samym workflow `gsutil`-iem albo Supabase CLI pull plików > tar.gz > push do backupów. Pliki PDF mają TTL 90 dni i tak.

### Keep-alive (przeciw auto-pauzie po 7 dniach)

Supabase pauzuje projekt po 7 dniach bez API requestów. Drugi GitHub Actions workflow `.github/workflows/keepalive.yml`, cron codziennie (`0 6 * * *`):

```yaml
name: Supabase keep-alive
on: { schedule: [{ cron: '0 6 * * *' }] }
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - run: |
          curl -sf -X GET "$SUPABASE_URL/rest/v1/categories?select=id&limit=1" \
            -H "apikey: $SUPABASE_ANON_KEY" \
            -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
            || exit 1
```

Koszt: ~10 s/dzień × 30 = 5 min/mc na koncie GitHub Actions (z 2000 min limitu).

### Disaster recovery

Jeśli Supabase pad / projekt skasowany:
1. Stwórz nowy projekt Supabase (free, drugi slot z 2 active projects).
2. Apply migracje 0001+ (`supabase db push` z lokalnego repo).
3. Restore z najnowszego dumpa GitHub Actions (`psql $NEW_DB < dumps/latest.sql`).
4. Każdy user logs in ponownie (sesje stracone — fresh sign-in z magic linkiem).
5. Lokalne dane na telefonach (Riverpod offline cache + pending_ops) PRZEŻYJĄ awarię — sync push gdy nowy backend gotowy.

RTO ~30 min, RPO ≤ 7 dni (tygodniowy dump) lub mniej jeśli user zrobił niedawno in-app export.

### User-initiated wipe

"Usuń moje konto" w Ustawieniach kasuje członkostwo + transakcje + pliki Storage tego usera. Gospodarstwo zostaje jeśli ma innych członków.

## Dystrybucja APK (zamiast Google Play)

- **Build**: `flutter build apk --release --split-per-abi --dart-define=...` → 3 APK (arm64, armv7, x86_64). Dla nowoczesnych telefonów wystarczy `app-arm64-v8a-release.apk`.
- **Podpis**: własny keystore (`keytool -genkey ...`), trzymany lokalnie + w password managerze użytkownika (NIE w repo). `key.properties` w `android/` jest w `.gitignore`. Bez signing'u nie da się aktualizować apki na telefonie (każda zmiana podpisu = "package conflict").
- **Transfer**: APK wysyłamy do żony przez Telegram / Signal / Drive / USB. Przed instalacją: Settings → Apps → menedżer plików → "Install unknown apps" → ON (jednorazowo dla danej apki źródłowej).
- **Aktualizacje**: ręcznie. Nowy build → ten sam keystore → APK nadpisuje stare zachowując dane. Można rozważyć w v4: in-app updater (apka sprawdza endpoint `releases.json` w prywatnym Supabase Storage i pokazuje "Nowa wersja: zainstaluj") — wciąż 0 zł.
- **CI build APK**: GitHub Actions na free runnerze, artefakt do download (2000 min/mc free) — wystarczy z zapasem.

---

## Struktura projektu (feature-first)

```
Test-e/
  README.md
  pubspec.yaml
  analysis_options.yaml
  android/
  lib/
    main.dart
    app/                  # router, theme (M3 dark/light), bootstrap
    core/                 # supabase client, env, errors, Result<T,E>
    shared/               # widgety: BentoTile, AmountText, CategoryChip, formatters
    features/
      auth/               { data, application, presentation }
      household/          # tworzenie, zaproszenia (accept_invitation RPC)
      transactions/       # lista, manual entry, voice entry, dedup
      categories/         # CRUD + seed
      dashboard/          # bento grid + 3 wykresy
      imports/            # v2: csv, v3: pdf
      budgets/            # v4
    l10n/                 # arb: pl, en
  supabase/
    migrations/0001_init.sql
    functions/
      parse-statement/    # Deno + unpdf, PDF parsing (v3+)
    tests/                # RLS tests
  test/                   # unit + widget tests
  .github/
    workflows/
      ci.yml              # flutter analyze + test, na PR
      build-apk.yml       # release APK build na tag, artefakt do download
      keepalive.yml       # daily cron, ping Supabase (anti auto-pause)
      backup.yml          # weekly cron, supabase db dump → prywatne repo backupów
```

Każda feature: `data/` (repository, DTOs), `application/` (Riverpod providers, use cases), `presentation/` (screens, widgets).

---

## Roadmapa MVP → v4

### v1 (MVP — pierwszy używalny build)
- Project scaffold (Flutter + Riverpod + go_router + theme M3 dark/light + `--dart-define`).
- Supabase: migracja 0001, RLS, seed polskich kategorii, RPC `accept_invitation`.
- Auth: signup/login (email + magic link), redirect logic.
- Onboarding: stwórz gospodarstwo LUB wpisz kod zaproszenia; ekran zaproszenia partnera.
- Manual entry (form, reactive_forms, walidacje, dedup_hash po stronie klienta).
- Voice entry (push-to-talk, regex/heurystyki PL, formularz pre-filled).
- Lista transakcji + filtrowanie po dacie/kategorii, realtime `.stream()`.
- Dashboard bento z **pickerem zakresu dat** (presety + własny od-do, persist lokalny): saldo wybranego okresu + delta vs poprzedni równy okres, pie kategorii w okresie, bar po miesiącach w okresie (lub po tygodniach gdy zakres ≤ 31 dni), line saldo narastająco w okresie. Lista transakcji filtrowana tym samym zakresem.
- Twarda deduplikacja (unique constraint).

### v2
- Import CSV/XML — zaczynamy od **ING (najczystszy CSV)**, dalej PKO BP, Santander, Millennium, Pekao.
- `charset_converter` dla Windows-1250 (PKO/Pekao).
- Tabela `staged_transactions` (osobna migracja `0002_imports.sql`), ekran "Potencjalne duplikaty" (miękki dedup).
- Snapshot testy parserów na anonimizowanych próbkach (nie commitować prawdziwych wyciągów).

### v3
- PDF import (Edge Function `parse-statement`, `unpdf`, regex per bank, jeden bank na iterację).

### v4
- Budżety per kategoria + alerty (**`flutter_local_notifications`** — lokalne, bez FCM/Firebase, bez kosztu).
- Raporty miesięczne/roczne (eksport PDF na telefon przez `printing` package).
- "Pobierz moje dane" — JSON dump wszystkich transakcji do pliku na telefonie.

### Wycięte z planu (sprzeczne z "0 zł" / "tylko własny użytek")
- ~~iOS build~~ — Apple Developer Program $99/rok.
- ~~Google Play~~ — niepotrzebne dla 2 osób, dystrybucja przez APK + sideload.
- ~~FCM push notifications~~ — drugi backend (Firebase), niepotrzebny, lokalne notifications wystarczą.
- ~~Kontomatik / Tink / TrueLayer~~ — enterprise pricing.
- ~~Claude Haiku LLM voice fallback~~ — koszty Anthropic API; rozważyć dopiero przy >20% błędów regex.
- ~~Custom email sender (Resend/SendGrid)~~ — Supabase Auth Email wystarczy.
- ~~Custom domena~~ — niepotrzebna dla 2 osób.

---

## Pierwsze 5 ticketów (kolejność wykonania)

Każdy ticket ma **definicję pracy**, **acceptance criteria** (jak agent / człowiek wie że gotowe) i **gate** (co człowiek osobiście waliduje przed mergem).

---

### Ticket 1 — Scaffold + theme + env

**Praca**: `flutter create` (org `pl.naszbudzetdomowy`), `pubspec.yaml` z pakietami z listy stacku, theme M3 (dark+light, low-stimulus paleta), font Inter (lub Manrope), wiring `--dart-define` dla `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `APP_VERSION` / `SENTRY_DSN`, lint `very_good_analysis`, GitHub Action `flutter analyze && flutter test`.

**Acceptance**:
- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` startuje na emulatorze.
- Theme toggle dark/light działa, snapshot test obu wariantów przechodzi.
- `flutter analyze` zero warningów.
- CI zielony na PR.

**Human gate**: przegląd `pubspec.yaml` (czy nie wciągnęły się niechciane zależności).

---

### Ticket 2 — Migracja Supabase + RLS + seed + RPC

**Praca**: `supabase/migrations/0001_init.sql` zawiera cały schemat z sekcji "Schemat bazy" + tabele `pending_ops` (lokalna SQLite, nie tutaj). `staged_transactions` przychodzi z migracją `0002_imports.sql` w v2 (nie w MVP). Polityki RLS na wszystkich tabelach (read + insert + update + delete wzorzec z `household_members`). Seed 12 polskich kategorii systemowych z `household_id = null` i `is_system = true` (lub seed per gospodarstwo przy onboardingu — wybrać). RPC `accept_invitation(code text)` jako `security definer`. Testy RLS w `supabase/tests/rls.test.sql` (próba SELECT spoza gospodarstwa = 0 wierszy, próba INSERT do cudzego = 42501).

**Acceptance**:
- `supabase db reset` lokalnie idzie czysto.
- `supabase test db` zielony.
- Ręczna próba (z `psql` jako anon): brak dostępu do `transactions` bez auth.

**Human gate**: czytanie RLS policy linia-po-linii. To jest single point of failure dla bezpieczeństwa danych.

---

### Ticket 3 — Auth + bootstrap gospodarstwa

**Praca**: ekrany sign-up/sign-in (magic link przez `signInWithOtp` — bez hasła w v1), po pierwszym logowaniu screen "Stwórz gospodarstwo" lub "Wpisz kod zaproszenia"; po stworzeniu — ekran "Twój kod zaproszenia: XXXX-XX (kopiuj, wyślij żonie)". Redirecty w `go_router` (`/onboarding` jeśli brak `current_household_id`, `/home` jeśli jest). State `currentHouseholdProvider` (Riverpod 3.0).

**Acceptance**:
- Na emulatorze A: rejestracja → magic link w mailbox → klik → onboarding → stwórz gospodarstwo → ekran z kodem.
- Na emulatorze B: rejestracja → onboarding → wpisz kod → ekran home, `current_household_id` ten sam co u A.
- Próba wpisania złego kodu → komunikat "Kod nieprawidłowy lub wygasł".
- Refresh apki utrzymuje sesję.

**Human gate**: ręczne przejście pełnego flowu na dwóch emulatorach.

---

### Ticket 4 — Manual transactions + lista + realtime + offline kolejka

**Praca**: form `reactive_forms` (kwota z maską PLN, typ income/expense, kategoria z dropdown, data z `showDatePicker pl_PL`, opcjonalny opis). Repository `TransactionRepository`: insert z `dedup_hash` i `client_op_id` liczonymi po stronie klienta, łapanie 23505 → "to już jest w bazie / już zsynchronizowane". Lista przez `supabase.from('transactions').stream(...)` → Riverpod async provider z `persist()` dla offline. Lokalna kolejka `pending_ops` w SQLite (`sqflite`) — wstawiamy zawsze najpierw lokalnie, worker syncuje gdy online (`connectivity_plus`). Ikona statusu sync w nagłówku (☁️ / ⏳N / ⚠️).

**Acceptance**:
- Dodanie wydatku w trybie offline → widoczny w liście od razu (z indykatorem ⏳).
- Po włączeniu sieci → ikona zmienia się na ☁️ w <3 s, rekord w Supabase.
- Podwójne dodanie tej samej transakcji → drugi błąd "to już jest".
- Realtime: na emulatorze A insert → emulator B widzi w liście <1 s.
- Test integracyjny: airplane mode → 3 inserty → online → wszystkie 3 w Supabase z poprawnymi `client_op_id`.

**Human gate**: test scenariusza konfliktu (oboje offline dodają ten sam wydatek → włączają sieć).

---

### Ticket 5 — Bento dashboard v1 + picker zakresu dat

**Praca**: **Pasek zakresu dat** na górze — chip-y z presetami (Bieżący miesiąc / Poprzedni miesiąc / 3M / 6M / 12M / YTD / Poprzedni rok / Wszystko / **Własny…**). "Własny…" otwiera `showDateRangePicker` Material 3 z lokalizacją `pl_PL`. Wybór trzymany w `dateRangeProvider` (Riverpod 3.0), persistowany w `shared_preferences` per użytkownik, default = bieżący miesiąc.

4 kafelki bento sterowane zakresem:
- (a) saldo okresu + delta vs poprzedni równy okres,
- (b) pie wydatków po kategoriach,
- (c) bar income vs expense — grupowanie auto: dziennie ≤14 dni, tygodniowo ≤90 dni, miesięcznie wyżej,
- (d) line saldo narastająco.

Repozytorium ma jedną metodę `summary(range)` → query do Postgresa lub Postgres view `transactions_summary` z `WHERE occurred_at BETWEEN $1 AND $2`. Material 3, paleta low-stimulus (off-white tło, zielony/czerwony akcent, neutralne szare), big typography (Display Large dla salda).

**Acceptance**:
- 5-10 testowych transakcji rozłożonych na 3 miesiące → przełączanie presetów spójnie zmienia wszystkie 4 kafelki.
- "Własny…" z zakresem od 1.04 do 15.04 → wykresy i lista pokazują tylko ten przedział.
- Reload apki utrzymuje ostatnio wybrany zakres.
- Snapshot widget tests dla light + dark + 3 zakresów (miesiąc, 3M, YTD).

**Human gate**: ocena estetyczna (zgodność z low-stimulus, brak wizualnego szumu).

---

---

### Ticket 6 — Voice push-to-talk (Vosk offline) + regex parser PL

**Praca**: integracja `vosk_flutter`, ekran "Pobierz model rozpoznawania mowy (50 MB)" w pierwszym uruchomieniu, download + SHA-256 check, zapis do `getApplicationSupportDirectory()/vosk-model-small-pl/`. Mikrofon FAB na ekranie "Dodaj wydatek": hold → recording → stop → transkrypt → `VoiceParser` w Dart (kwota regex + data lookup + kategoria fuzzy match) → prefill formularza z Ticket 4. Lokalne liczniki skuteczności w SQLite.

**Acceptance**:
- Pierwsze uruchomienie pokazuje ekran download modelu; po success: stan "Voice gotowy".
- Airplane mode + powiedz "150 złotych Biedronka wczoraj" → formularz: kwota=150 PLN, kategoria=Spożywcze, data=wczoraj, opis="Biedronka". Voice działa BEZ internetu.
- Wadliwy input ("yyy eee no jakieś tam zakupy") → formularz częściowo wypełniony (puste kwota), input możliwy ręcznie.
- Test: 20 nagranych próbek (różni mówcy/akcenty) → ≥80% prawidłowo zidentyfikowanych kwot.

**Human gate**: rzeczywiste przejście 10 wpisów głosowych — ocena czy UX nie jest frustrujący.

---

---

### Ticket 7 — Kategorie CRUD + oznaczenia wizualne + reasignment przy delete

**Praca**: ekran `/settings/categories`, `CategoryRepository` (insert/update/soft-hide/delete), RPC `delete_category_with_reassign(old_id, target_id)` jako `security definer` z walidacją że obie należą do tego samego gospodarstwa i są tego samego typu. Picker ikony Material Symbols (curated ~80 ikon, search). Picker koloru (paleta 12 odcieni). Wymuszenie dialog'u reasignment gdy delete z N>0 transakcji. Spójne oznaczenia w liście transakcji, pie chart, chipach (`CategoryBadge` widget).

**Acceptance**:
- Dodanie własnej kategorii "Hobby" z ikoną `palette` i kolorem fiołkowym → widoczne w pickerze formularza wydatku natychmiast (realtime sync).
- Edycja koloru kategorii systemowej "Spożywcze" → zmiana propaguje się na liście transakcji, pie chart i chipach.
- Usunięcie kategorii z 5 transakcjami → dialog "wybierz docelową" → po wyborze "Inne" → transakcje mają nowy category_id, kategoria zniknęła.
- Próba usunięcia kategorii systemowej → przycisk "Usuń" niewidoczny, tylko "Ukryj z listy".
- Próba dodania kategorii o nazwie już istniejącej → walidacja "Ta nazwa jest już zajęta".

**Human gate**: ocena spójności wizualnej oznaczeń w 3 miejscach (lista, dashboard, voice result).

---

Po Tickecie 5 mamy **używalny MVP** (manual + dashboard + offline + sync). Po Tickecie 6 — pełen offline voice flow. Po Tickecie 7 — pełne zarządzanie kategoriami.

---

## Pliki krytyczne do utworzenia/zmiany

- `/home/user/Test-e/pubspec.yaml` — pakiety
- `/home/user/Test-e/lib/main.dart` — bootstrap
- `/home/user/Test-e/lib/app/router.dart` — `go_router` + redirecty auth/onboarding
- `/home/user/Test-e/lib/app/theme.dart` — Material 3, low-stimulus paleta, dark/light
- `/home/user/Test-e/lib/core/supabase/supabase_client.dart` — singleton + `--dart-define` env
- `/home/user/Test-e/supabase/migrations/0001_init.sql` — schemat + RLS + seed + RPC
- `/home/user/Test-e/lib/features/auth/` — sign-in/up + magic link
- `/home/user/Test-e/lib/features/household/` — create/invite/accept
- `/home/user/Test-e/lib/features/transactions/data/transaction_repository.dart` — insert + stream + dedup_hash
- `/home/user/Test-e/lib/features/transactions/application/voice_parser.dart` — regex/heurystyki PL (ticket 6)
- `/home/user/Test-e/lib/features/dashboard/` — bento grid + 4 wykresy + `DateRangeBar` + `dateRangeProvider` (Riverpod, persist w `shared_preferences`)
- `/home/user/Test-e/lib/shared/widgets/bento_tile.dart` — wspólny kafelek

---

## Weryfikacja (jak sprawdzić end-to-end)

1. **DB**: `supabase db reset` lokalnie → migracja idzie czysto → testy RLS w `supabase/tests/` przechodzą (próba SELECT spoza gospodarstwa zwraca 0 rzędów).
2. **Auth + invite**: na emulatorze A stwórz gospodarstwo, wyślij kod, na emulatorze B wpisz kod → oba telefony widzą to samo gospodarstwo.
3. **Dedup hard**: ręcznie wpisz tę samą transakcję dwa razy → drugi insert zwraca błąd, UI pokazuje "to już jest".
4. **Realtime**: na emulatorze A dodaj wydatek → emulator B widzi go w liście w <1s bez odświeżania.
5. **Voice**: trzymaj FAB, powiedz "150 złotych Biedronka wczoraj" → formularz wypełnia się: kwota 150 PLN, kategoria Spożywcze, data wczoraj.
6. **Wykresy + zakres dat**: 5-10 testowych transakcji rozłożonych na 3 miesiące → przełączanie presetów (bieżący miesiąc / 3M / YTD) zmienia wszystkie kafelki spójnie; wybór "Własny…" → np. od 1.04 do 15.04 → pie/bar/line/lista pokazują tylko ten zakres; reload aplikacji → ostatnio wybrany zakres jest zapamiętany.
7. **Snapshot dashboard** w testach widgetowych (Material 3, dark mode włączony domyślnie).

---

## Decyzje (już domknięte)

- **Hosting**: Supabase.com free tier. Migracja na self-hosted Docker tylko gdy free tier się skończy (lata zapasu dla 2 osób).
- **Voice**: regex-only, bez LLM. Re-rozważyć dopiero przy >20% niedoparsowanych głosów.
- **Bank imports**: nie w v1 (MVP). W v2 własne parsery CSV/XML (zaczynamy od ING), w v3 PDF przez Edge Function. Bez Kontomatika.
- **Dystrybucja**: APK + sideload, bez Google Play, bez iOS.
- **Notyfikacje**: lokalne (flutter_local_notifications), bez FCM/Firebase.
- **Observability**: Supabase Logs domyślnie; Sentry free dorzucamy gdy zacznie być potrzebne.

## Otwarte decyzje — brak

Wszystkie kluczowe decyzje są zamknięte. Plan jest gotowy do zatwierdzenia.
