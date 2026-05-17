import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/household/presentation/invitation_share_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('InvitationShareScreen', () {
    testWidgets('renderuje kod i przyciski Kopiuj / Udostępnij',
        (tester) async {
      await tester.pumpWidget(
        wrap(const InvitationShareScreen(code: 'ABC-XYZ')),
      );
      expect(find.text('ABC-XYZ'), findsOneWidget);
      expect(find.text('Gospodarstwo gotowe'), findsOneWidget);
      expect(find.text('Kopiuj'), findsOneWidget);
      expect(find.text('Udostępnij'), findsOneWidget);
      expect(find.text('Przejdź do budżetu'), findsOneWidget);
    });
  });
}
