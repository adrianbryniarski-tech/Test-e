import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Czy user widział intro-carousel. Pokazujemy je RAZ, przy pierwszym
/// uruchomieniu apki (przed pierwszym logowaniem). Persistowane w
/// `shared_preferences` per urządzenie.
final introSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('intro_seen') ?? false;
});

/// Oznacza intro jako obejrzane + invaliduje provider (UI przełączy się
/// na formularz logowania). Przyjmuje `WidgetRef` bo wołane z widgetu.
Future<void> markIntroSeen(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('intro_seen', true);
  ref.invalidate(introSeenProvider);
}
