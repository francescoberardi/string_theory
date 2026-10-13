import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_flutter/screens/sign_in_screen.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';

import '../helpers/fake_auth.dart';

void main() {
  Future<void> pumpSignIn(
    WidgetTester tester, {
    required Future<bool> Function() onContinueAsGuest,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final client = buildOfflineTestClient(InMemoryAuthSuccessStorage());
    await tester.pumpWidget(
      MaterialApp(
        theme: CourtMidnightTheme.themeData,
        home: SignInScreen(
          client: client,
          onContinueAsGuest: onContinueAsGuest,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SignInScreen', () {
    testWidgets('shows the email sign-in form and Continue as guest', (
      tester,
    ) async {
      await pumpSignIn(tester, onContinueAsGuest: () async => true);

      expect(find.text('STRING THEORY'), findsOneWidget);
      expect(find.byType(EmailSignInWidget), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(
        find.byKey(SignInScreen.keyContinueAsGuestButton),
        findsOneWidget,
      );
      expect(find.text('Continue as guest'), findsOneWidget);
      expect(find.byKey(SignInScreen.keyGuestError), findsNothing);
    });

    testWidgets('Sign up opens the email registration step', (tester) async {
      await pumpSignIn(tester, onContinueAsGuest: () async => true);

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Up with email'), findsOneWidget);
    });

    testWidgets('Continue as guest starts a guest session once per tap', (
      tester,
    ) async {
      var calls = 0;
      final pending = Completer<bool>();
      await pumpSignIn(
        tester,
        onContinueAsGuest: () {
          calls++;
          return pending.future;
        },
      );

      await tester.tap(find.byKey(SignInScreen.keyContinueAsGuestButton));
      await tester.pump();
      // The button is disabled while the guest session is being created.
      await tester.tap(
        find.byKey(SignInScreen.keyContinueAsGuestButton),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(calls, 1);
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.byKey(SignInScreen.keyGuestError), findsNothing);
    });

    testWidgets('a failed guest sign-in shows an inline error with Retry', (
      tester,
    ) async {
      var calls = 0;
      await pumpSignIn(
        tester,
        onContinueAsGuest: () async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return true;
        },
      );

      await tester.tap(find.byKey(SignInScreen.keyContinueAsGuestButton));
      await tester.pumpAndSettle();

      expect(find.byKey(SignInScreen.keyGuestError), findsOneWidget);
      expect(find.text(SignInScreen.guestErrorMessage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.byKey(SignInScreen.keyGuestRetryButton));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.byKey(SignInScreen.keyGuestError), findsNothing);
    });
  });
}
