import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/household/data/household_repository.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return const HouseholdRepository();
});

/// `null` data = brak gospodarstwa (user właśnie się zarejestrował i jest
/// na onboardingu). Provider auto-invaliduje się przy zmianach sesji
/// — login/logout natychmiast aktualizuje state routera.
final currentHouseholdIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(householdRepositoryProvider).currentHouseholdId();
});

/// Aktywne (nieprzyjęte, niewygasłe) zaproszenia dla gospodarstwa.
final activeInvitationsProvider =
    FutureProvider.family<List<Invitation>, String>((ref, householdId) async {
  return ref.watch(householdRepositoryProvider).activeInvitations(householdId);
});

/// Metadata gospodarstwa (id, name) — pobierane raz.
final householdInfoProvider =
    FutureProvider.family<HouseholdInfo?, String>((ref, householdId) async {
  return ref.watch(householdRepositoryProvider).info(householdId);
});

/// Lista członków gospodarstwa (user_id, role, joined_at) — STREAM.
/// Realtime INSERT przy dołączeniu nowego członka (migracja 0005 dodała
/// `household_members` do publication `supabase_realtime`).
final householdMembersProvider =
    StreamProvider.family<List<HouseholdMember>, String>((ref, householdId) {
  return ref.watch(householdRepositoryProvider).watchMembers(householdId);
});

/// Mapa `user_id → email` członków gospodarstwa (przez RPC z migracji 0011).
/// Wzbogaca listę członków o czytelne adresy — strumień realtime e-maila
/// nie zwraca. Jednorazowy fetch; gdy się nie powiedzie, UI pokazuje UUID.
final householdMemberEmailsProvider =
    FutureProvider.family<Map<String, String>, String>(
        (ref, householdId) async {
  final members = await ref
      .watch(householdRepositoryProvider)
      .membersWithEmail(householdId);
  return {
    for (final m in members)
      if (m.email != null) m.userId: m.email!,
  };
});
