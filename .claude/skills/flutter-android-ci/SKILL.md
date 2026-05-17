---
name: flutter-android-ci
description: Konfiguracja buildu Flutter Android w GitHub Actions dla projektu "Nasz budżet domowy". Używaj gdy modyfikujesz workflow .github/workflows/build-apk-*.yml, debugujesz padnięty build APK, dotykasz android/build.gradle.kts lub innych plików scaffoldingu Android, albo dodajesz natywne pluginy (vosk_flutter_2, sqflite, flutter_local_notifications).
---

# Flutter Android CI — lekcje z bólu

## TL;DR — najważniejsza zasada

**Commituj cały `android/` scaffolding do gita.** NIE polegaj na `flutter create` w CI do generowania `build.gradle.kts`, `MainActivity.kt`, styles, mipmap. To prowadzi do "działa lokalnie, pada w CI" — różne wersje Flutter stable generują różne pliki.

## Co commitować, co NIE

### W gicie (commit)
- `android/build.gradle.kts`
- `android/settings.gradle.kts`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/<org>/<project>/MainActivity.kt`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/drawable*/launch_background.xml`
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/xml/data_extraction_rules.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/.gitignore` (lokalny gitignore plików IDE / lokalnych)

### W .gitignore (NIE commit)
```gitignore
**/android/**/gradle-wrapper.jar    # binarka, regen przez flutter create
**/android/gradlew                  # shell wrapper, regen
**/android/gradlew.bat              # bat wrapper, regen
**/android/local.properties         # ścieżki lokalne do flutter SDK
**/android/**/GeneratedPluginRegistrant.java  # generowane przez Flutter
**/android/key.properties           # SEKRETY release signing
*.jks *.keystore                    # SEKRETY release keystore
```

## Pułapki z natywnymi pluginami

### vosk_flutter_2 (offline ASR)
- Wymaga `minSdkVersion >= 21` — Flutter `flutter.minSdkVersion` w 2026 jest 24+, OK.
- NDK: nie wymaga konkretnej wersji w `1.0.5`, ale jak będzie warning "NDK version mismatch", **dopisz ndkVersion explicite** do `android/app/build.gradle.kts`:
  ```kotlin
  android {
      ndkVersion = "27.0.12077973"  // lub jakąkolwiek wskazaną przez warning
  }
  ```
- Model NIE jest bundlowany — apka pobiera w runtime do `getApplicationSupportDirectory()`.

### sqflite + sqflite_common_ffi
- W produkcji używaj `sqflite` (zwykły).
- W testach `sqflite_common_ffi` z `sqfliteFfiInit()` + `inMemoryDatabasePath`.
- NIE używaj `sqflite_ffi` w runtime aplikacji — to crashuje na realnym Androidzie.

### Native libs conflict (`Multiple files were found in libxxx.so`)
Jeśli Vosk + jakiś inny natywny plugin powodują konflikty `.so`:
```kotlin
android {
    packagingOptions {
        pickFirst("lib/**/libc++_shared.so")
        pickFirst("lib/**/libvosk.so")
    }
}
```
Tylko jak realnie zajdzie potrzeba — proaktywnie nie dorzucaj.

## Workflow GitHub Actions — wzorzec

Plik `.github/workflows/build-apk-debug.yml`:

```yaml
name: Build debug APK
on: { workflow_dispatch: {} }

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }

      # Dogenerowuje TYLKO pliki gitignored (gradle-wrapper.jar, gradlew,
      # local.properties). Reszta scaffoldingu już w repo.
      - name: Bootstrap gradle wrapper
        run: |
          flutter create --platforms=android \
            --org=pl.naszbudzetdomowy \
            --project-name=nasz_budzet_domowy .

      - run: flutter pub get

      - name: Build debug APK
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
            echo "❌ Brak sekretów SUPABASE_URL / SUPABASE_ANON_KEY"
            exit 1
          fi
          flutter build apk --debug \
            --dart-define=SUPABASE_URL="$SUPABASE_URL" \
            --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
            --dart-define=APP_VERSION=debug-${{ github.sha }}

      - uses: actions/upload-artifact@v4
        with:
          name: nasz-budzet-domowy-debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
          if-no-files-found: error
          retention-days: 30
```

## Diagnostyka padniętego buildu

Jak workflow w GitHub Actions pada z `Process completed with exit code 1` i nie masz dostępu do logów przez MCP:

1. **Najpierw sprawdź sekrety.** Workflow ma explicit check — jak `SUPABASE_URL` brak, kończy się `exit 1` z czytelnym komunikatem.
2. **Sprawdź czy android/ scaffolding jest w gicie** (`git ls-files android/`). Jak jest tylko AndroidManifest.xml, problem prawie na pewno tu.
3. **Sprawdź pubspec.lock pod kątem nowych natywnych pluginów** które dodały się od ostatniego działającego buildu. Często wymagają nowego `ndkVersion` lub `compileSdkVersion`.
4. **Poproś użytkownika o screenshot Annotations**. Warning zaczynający się od "NDK" → version mismatch. Warning "manifest merger" → konflikt uprawnień lub atrybutów. Warning "duplicate class" → konflikt zależności.
5. **Jeśli wszystko inne fail-uje** — zaproponuj uruchomienie workflow z `ACTIONS_STEP_DEBUG=true` jako `repository_dispatch` secret (verbose logging).

## Lekcja meta

Kod który "działa lokalnie ale pada w CI" prawie zawsze ma jedno źródło: **różnica między tym co jest w repo a tym co generuje się w czasie buildu**. Im więcej scaffoldingu w gicie, tym mniej takich problemów. Trade-off: większe repo, więcej plików w PR review. Warto.
