import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/verify_otp_screen.dart';
import '../features/household/application/household_providers.dart';
import '../features/household/presentation/create_household_screen.dart';
import '../features/household/presentation/invitation_share_screen.dart';
import '../features/household/presentation/join_household_screen.dart';
import '../features/household/presentation/onboarding_choice_screen.dart';

/// Globalny router z redirectami zależnymi od stanu auth i gospodarstwa.
///
/// Logika redirectów (sprawdzana na każdej nawigacji + przy refresh):
/// - Brak sesji → `/sign-in` (chyba że już jesteśmy na ekranach auth).
/// - Sesja jest, brak gospodarstwa → `/onboarding`.
/// - Sesja + gospodarstwo → `/home`.
///
/// `refreshListenable` słucha **dwóch** strumieni:
/// 1. `supabase.auth.onAuthStateChange` — login/logout.
/// 2. Riverpod `currentHouseholdIdProvider` — gdy user dołączy/stworzy
///    gospodarstwo, router automatycznie wypchnie go z onboardingu.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthHouseholdRefresh(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/sign-in',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final location = state.matchedLocation;

      final isOnAuth = location == '/sign-in' ||
          location.startsWith('/sign-in/');
      final isLoading = location == '/loading';

      if (!loggedIn) {
        if (isOnAuth) return null;
        return '/sign-in';
      }

      // Zalogowany — sprawdzamy gospodarstwo. Pierwsze odczytanie
      // triggeruje async build; pokazujemy `/loading` zamiast skakać
      // przez onboarding na home.
      final householdAsync = ref.read(currentHouseholdIdProvider);
      final onOnboarding = location.startsWith('/onboarding');

      if (householdAsync.isLoading) {
        return isLoading ? null : '/loading';
      }

      final household = householdAsync.valueOrNull;
      if (isLoading || isOnAuth) {
        return household == null ? '/onboarding' : '/home';
      }
      if (household == null && !onOnboarding) return '/onboarding';
      if (household != null && onOnboarding) {
        // Wyjątek: ekran "share invite code" jest podstroną onboardingu,
        // ale user już ma gospodarstwo — niech go obejrzy do końca.
        if (location.startsWith('/onboarding/invite/')) return null;
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _BootLoadingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            builder: (context, state) {
              final email = state.extra as String? ?? '';
              return VerifyOtpScreen(email: email);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingChoiceScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateHouseholdScreen(),
          ),
          GoRoute(
            path: 'join',
            builder: (context, state) => const JoinHouseholdScreen(),
          ),
          GoRoute(
            path: 'invite/:code',
            builder: (context, state) {
              final code = state.pathParameters['code'] ?? '';
              return InvitationShareScreen(code: code);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomePlaceholder(),
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

/// Notifier reagujący na zmiany sesji ORAZ household provider.
class _AuthHouseholdRefresh extends ChangeNotifier {
  _AuthHouseholdRefresh(this._ref) {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      // Sesja się zmieniła — wyczyść cache household i odśwież router.
      _ref.invalidate(currentHouseholdIdProvider);
      notifyListeners();
    });
    _householdSub = _ref.listen<AsyncValue<String?>>(
      currentHouseholdIdProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final StreamSubscription<AuthState> _authSub;
  late final ProviderSubscription<AsyncValue<String?>> _householdSub;

  @override
  void dispose() {
    _authSub.cancel();
    _householdSub.close();
    super.dispose();
  }
}

class _BootLoadingScreen extends StatelessWidget {
  const _BootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final household = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nasz budżet domowy'),
        actions: [
          IconButton(
            tooltip: 'Wyloguj',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zalogowany: ${user?.email ?? "(nieznany)"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Gospodarstwo: ${household.valueOrNull ?? "(brak)"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Dashboard — Ticket 5.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

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
