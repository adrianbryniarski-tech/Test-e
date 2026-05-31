import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:nasz_budzet_domowy/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Operacje na gospodarstwie i zaproszeniach.
///
/// Wszystkie write-y przechodzą przez RPC `security definer`
/// (`create_household_with_owner`, `accept_invitation`) — RLS na
/// `household_members` blokuje bezpośredni INSERT z klienta.
class HouseholdRepository {
  const HouseholdRepository();

  /// Zwraca `household_id` pierwszego gospodarstwa do którego należy
  /// bieżący user, lub `null` gdy nie należy do żadnego (= onboarding).
  ///
  /// W v1 user należy do jednego gospodarstwa. v4 doda switcher.
  Future<String?> currentHouseholdId() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final rows = await supabase
        .from('household_members')
        .select('household_id')
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['household_id'] as String;
  }

  /// Tworzy gospodarstwo (z bieżącym userem jako `owner`) + seed kategorii.
  ///
  /// Atomowe (RPC w jednej transakcji DB). Zwraca `household_id`.
  Future<String> createHousehold({required String name}) async {
    final result = await supabase.rpc<String>(
      'create_household_with_owner',
      params: {'p_name': name},
    );
    return result;
  }

  /// Bieżący user opuszcza wskazane gospodarstwo. Po tym
  /// `currentHouseholdId()` zwraca null → router redirects na onboarding
  /// → user może wpisać kod zaproszenia do innego.
  Future<void> leaveHousehold(String householdId) async {
    await supabase.rpc<void>(
      'leave_household',
      params: {'p_household_id': householdId},
    );
  }

  /// Przyjmuje zaproszenie po kodzie. Mapowanie błędów SQL →
  /// `InvitationException` z typed `InvitationError` żeby UI mógł
  /// pokazać przyjazny komunikat.
  Future<String> acceptInvitation(String code) async {
    try {
      final result = await supabase.rpc<String>(
        'accept_invitation',
        params: {'p_code': code.trim().toUpperCase()},
      );
      return result;
    } on PostgrestException catch (e) {
      throw InvitationException(mapInvitationError(e));
    }
  }

  /// Tworzy nowe zaproszenie do podanego gospodarstwa. RLS sprawdza
  /// że user jest członkiem (`is_household_member`).
  Future<Invitation> createInvitation(String householdId) async {
    final code = _generateCode();
    final row = await supabase
        .from('invitations')
        .insert({
          'household_id': householdId,
          'code': code,
        })
        .select()
        .single();
    return Invitation.fromJson(row);
  }

  /// Pobiera ostatnie zaproszenia (np. żeby pokazać "twój aktywny kod").
  Future<List<Invitation>> activeInvitations(String householdId) async {
    final rows = await supabase
        .from('invitations')
        .select()
        .eq('household_id', householdId)
        .isFilter('accepted_at', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at')
        .limit(5);
    return rows.map(Invitation.fromJson).toList();
  }

  /// Lista członków gospodarstwa — `user_id`, `role`, `joined_at`. RLS
  /// pozwala czytać `household_members` tylko członkom (przez
  /// `is_household_member`). Bez nazw / emaili (RLS na `auth.users`
  /// blokowałby join'a).
  Future<List<HouseholdMember>> members(String householdId) async {
    final rows = await supabase
        .from('household_members')
        .select('user_id, role, joined_at')
        .eq('household_id', householdId)
        .order('joined_at');
    return rows.map(HouseholdMember.fromJson).toList();
  }

  /// Stream członków — używać żeby auto-update przy dołączeniu nowego
  /// członka (Realtime przyniesie INSERT na `household_members`).
  /// Wymaga migracji 0005 (publication supabase_realtime + table).
  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return supabase
        .from('household_members')
        .stream(primaryKey: ['household_id', 'user_id'])
        .eq('household_id', householdId)
        .order('joined_at')
        .map((rows) => rows.map(HouseholdMember.fromJson).toList());
  }

  /// Członkowie gospodarstwa RAZEM z e-mailem. Czyta przez RPC
  /// `security definer` (migracja 0011), bo RLS na `auth.users` blokuje
  /// zwykłego join'a. RPC oddaje e-maile tylko gdy wołający jest członkiem
  /// tego gospodarstwa — brak wycieku obcych adresów.
  Future<List<HouseholdMember>> membersWithEmail(String householdId) async {
    final rows = await supabase.rpc<List<dynamic>>(
      'household_members_with_email',
      params: {'p_household_id': householdId},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(HouseholdMember.fromJson)
        .toList();
  }

  /// Zwraca metadata gospodarstwa (nazwa) bez całej listy członków.
  Future<HouseholdInfo?> info(String householdId) async {
    try {
      final row = await supabase
          .from('households')
          .select('id, name')
          .eq('id', householdId)
          .maybeSingle();
      if (row == null) return null;
      return HouseholdInfo.fromJson(row);
    } on Object {
      return null;
    }
  }

  /// Format kodu: `XXX-XXX` (6 znaków A-Z bez I/O/0/1 dla czytelności).
  static String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final chars = List.generate(
      6,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    );
    return '${chars.sublist(0, 3).join()}-${chars.sublist(3).join()}';
  }

  /// Mapuje kody błędów RPC `accept_invitation` na typed [InvitationError].
  /// Publiczne wyłącznie dla testów.
  @visibleForTesting
  InvitationError mapInvitationError(PostgrestException e) {
    // Kody błędów ustawiane w RPC `accept_invitation` (migracja 0001).
    return switch (e.code) {
      'P0002' => InvitationError.notFound,
      'P0003' => InvitationError.alreadyUsed,
      'P0004' => InvitationError.expired,
      '42501' => InvitationError.unauthenticated,
      _ => InvitationError.unknown,
    };
  }
}

enum InvitationError {
  notFound,
  alreadyUsed,
  expired,
  unauthenticated,
  unknown,
}

/// Wyjątek z typed `InvitationError`. Łapać w UI:
/// `on InvitationException catch (e) { /* e.error */ }`.
class InvitationException implements Exception {
  const InvitationException(this.error);

  final InvitationError error;

  @override
  String toString() => 'InvitationException(${error.name})';
}

class HouseholdInfo {
  const HouseholdInfo({required this.id, required this.name});

  factory HouseholdInfo.fromJson(Map<String, dynamic> json) {
    return HouseholdInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.email,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      // Tylko z RPC `household_members_with_email`; stream realtime
      // (`watchMembers`) e-maila nie zwraca → null.
      email: json['email'] as String?,
    );
  }

  final String userId;
  final String role;
  final DateTime joinedAt;

  /// E-mail członka — dostępny tylko gdy rekord pochodzi z
  /// `membersWithEmail` (RPC). W strumieniu realtime jest `null`.
  final String? email;

  bool get isOwner => role == 'owner';
}

class Invitation {
  const Invitation({
    required this.id,
    required this.householdId,
    required this.code,
    required this.expiresAt,
    this.acceptedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
    );
  }

  final String id;
  final String householdId;
  final String code;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
}
