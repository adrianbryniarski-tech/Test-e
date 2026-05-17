import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Globalny router z redirectami zależnymi od stanu auth.
///
/// Logika redirectów:
/// - Brak sesji → `/sign-in`
/// - Jest sesja, brak gospodarstwa → `/onboarding`
/// - Jest sesja, jest gospodarstwo → `/home`
///
/// `currentHouseholdId` jest źródłem prawdy o krok 2 (sprawdzane przez
/// `householdNotifierProvider`, dodawany w ticketach 3 i 4).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final isSignIn = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';

      if (!loggedIn && !isSignIn) return '/sign-in';
      if (loggedIn && isSignIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Zaloguj się',
          message: 'Ekran logowania — Ticket 3.',
        ),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Załóż konto',
          message: 'Ekran rejestracji — Ticket 3.',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Onboarding',
          message: 'Stwórz gospodarstwo lub wpisz kod — Ticket 3.',
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Nasz budżet domowy',
          message: 'Dashboard — Ticket 5.',
        ),
      ),
      GoRoute(
        path: '/settings/categories',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Kategorie',
          message: 'CRUD kategorii — Ticket 7.',
        ),
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
