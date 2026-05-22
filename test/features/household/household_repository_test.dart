import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/household/data/household_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mapowanie kodów błędów RPC `accept_invitation` na typed InvitationError —
// decyduje, jaki komunikat zobaczy osoba wpisująca kod zaproszenia.
void main() {
  const repo = HouseholdRepository();

  PostgrestException err(String? code) =>
      PostgrestException(message: 'raw', code: code);

  group('mapInvitationError', () {
    test('P0002 → notFound', () {
      expect(repo.mapInvitationError(err('P0002')), InvitationError.notFound);
    });

    test('P0003 → alreadyUsed', () {
      expect(
        repo.mapInvitationError(err('P0003')),
        InvitationError.alreadyUsed,
      );
    });

    test('P0004 → expired', () {
      expect(repo.mapInvitationError(err('P0004')), InvitationError.expired);
    });

    test('42501 → unauthenticated', () {
      expect(
        repo.mapInvitationError(err('42501')),
        InvitationError.unauthenticated,
      );
    });

    test('nieznany kod → unknown', () {
      expect(repo.mapInvitationError(err('zzz')), InvitationError.unknown);
      expect(repo.mapInvitationError(err(null)), InvitationError.unknown);
    });
  });

  test('InvitationException.toString zawiera nazwę błędu', () {
    expect(
      const InvitationException(InvitationError.expired).toString(),
      'InvitationException(expired)',
    );
  });
}
