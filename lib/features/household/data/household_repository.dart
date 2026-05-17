import 'dart:math';

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
      throw InvitationException(_mapInvitationError(e));
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

  InvitationError _mapInvitationError(PostgrestException e) {
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
