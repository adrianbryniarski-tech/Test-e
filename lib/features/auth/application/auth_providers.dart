import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// Strumień zmian sesji Supabase.
///
/// Router subskrybuje to przez `refreshListenable` aby reagować na
/// signedIn / signedOut bez polling-u.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Bieżący użytkownik (null = wylogowany). Refresh po każdym
/// `onAuthStateChange`.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});
