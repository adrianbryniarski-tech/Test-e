plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "pl.naszbudzetdomowy.nasz_budzet_domowy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Wymagane przez flutter_local_notifications ≥18.x (używa java.time)
        // — backportuje API Java 8+ na starsze poziomy Androida.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Stały debug keystore commitowany do repo (`android/app/debug.keystore`,
    // hasła: `android` / `android` — to publiczne defaulty Android SDK).
    // Bez tego każdy CI build używałby świeżo wygenerowanego keystore z
    // ~/.android/debug.keystore na runnerze → każdy APK miał inną sygnaturę
    // → Android odmawia update'u istniejącej apki ("package conflict").
    //
    // Commitowanie debug keystore jest BEZPIECZNE — to nie są sekrety,
    // hasła to publiczny default. Release keystore (jeśli kiedyś dorobimy)
    // ZOSTAJE w .gitignore + GitHub Secrets.
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    defaultConfig {
        applicationId = "pl.naszbudzetdomowy.nasz_budzet_domowy"
        // vosk_flutter_2 wymaga minSdk 30 (Android 11+). Dla apki na 2
        // telefony to OK — oba mają Android ≥11. NIE używamy
        // flutter.minSdkVersion (które jest niższe).
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
