import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/client.dart' as app_client;
import 'package:string_theory_flutter/main.dart';
import 'package:string_theory_flutter/screens/settings_screen.dart';
import 'package:string_theory_flutter/screens/sign_in_screen.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/services/auth_service.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

import 'helpers/fake_auth.dart';
import 'helpers/fake_health_sync_service.dart';

void main() {
  late FakeHealthSyncService fakeHealth;
  late FakeEndpointAnonymousIdp anonymousIdp;
  late InMemorySessionQueueStorage queueStorage;

  /// Installs the app globals with [stored] as the persisted session and
  /// [accountEmail] as the server's answer to the account email lookup.
  Future<void> setUpAuth({AuthSuccess? stored, String? accountEmail}) async {
    final client = buildOfflineTestClient(InMemoryAuthSuccessStorage(stored));
    queueStorage = InMemorySessionQueueStorage();
    app_client.client = client;
    app_client.offlineSessionQueue = OfflineSessionQueue(storage: queueStorage);
    app_client.authService = AuthService(
      client: client,
      anonymousEndpoint: anonymousIdp,
      fetchAccountEmail: () async => accountEmail,
      offlineQueue: app_client.offlineSessionQueue,
    );
    await app_client.authService.initialize();
  }

  Future<void> tapContinueAsGuest(WidgetTester tester) async {
    final button = find.byKey(SignInScreen.keyContinueAsGuestButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  setUp(() {
    fakeHealth = FakeHealthSyncService();
    addTearDown(fakeHealth.dispose);
    anonymousIdp = FakeEndpointAnonymousIdp();
  });

  group('auth gate', () {
    testWidgets('no stored session shows the sign-in screen, no guest', (
      tester,
    ) async {
      await setUpAuth();

      await tester.pumpWidget(MyApp(healthSyncService: fakeHealth));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(VirtualBagScreen), findsNothing);
      expect(anonymousIdp.loginCalls, 0);
    });

    testWidgets('a stored guest session opens the bag with a GUEST badge', (
      tester,
    ) async {
      await setUpAuth(stored: testAuthSuccess(guestUserId));

      await tester.pumpWidget(MyApp(healthSyncService: fakeHealth));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('STRING THEORY'), findsOneWidget);
      expect(find.byType(VirtualBagScreen), findsOneWidget);
      expect(find.byKey(MyHomePage.keyGuestBadge), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ACCOUNT & SYNC'), findsOneWidget);
    });

    testWidgets('a stored email session opens the bag without a GUEST badge', (
      tester,
    ) async {
      await setUpAuth(
        stored: testAuthSuccess(emailUserId),
        accountEmail: 'judge@example.com',
      );

      await tester.pumpWidget(MyApp(healthSyncService: fakeHealth));
      await tester.pumpAndSettle();

      expect(find.byType(VirtualBagScreen), findsOneWidget);
      expect(find.byKey(MyHomePage.keyGuestBadge), findsNothing);
    });

    testWidgets('Continue as guest opens the bag', (tester) async {
      await setUpAuth();

      await tester.pumpWidget(MyApp(healthSyncService: fakeHealth));
      await tester.pumpAndSettle();
      await tapContinueAsGuest(tester);
      await tester.pumpAndSettle();

      expect(anonymousIdp.loginCalls, 1);
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(VirtualBagScreen), findsOneWidget);
      expect(find.byKey(MyHomePage.keyGuestBadge), findsOneWidget);
    });

    testWidgets(
      'signing out closes the bag, drops pushed routes and the queue, and the '
      'next sign-in gets a fresh bag',
      (tester) async {
        await setUpAuth(stored: testAuthSuccess(guestUserId));
        final blocs = <BagBloc>[];
        BagBloc createBloc() {
          final bloc = BagBloc(
            client: app_client.client,
            offlineQueue: app_client.offlineSessionQueue,
          );
          blocs.add(bloc);
          return bloc;
        }

        await tester.pumpWidget(
          MyApp(healthSyncService: fakeHealth, bagBlocFactory: createBloc),
        );
        await tester.pumpAndSettle();
        await queueStorage.write(['{"queued": true}']);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(SettingsScreen.keySignOutButton));
        await tester.tap(find.byKey(SettingsScreen.keySignOutButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(SettingsScreen.keyConfirmSignOutButton));
        await tester.pumpAndSettle();

        expect(find.byType(SignInScreen), findsOneWidget);
        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(VirtualBagScreen), findsNothing);
        expect(app_client.authService.isAuthenticated, isFalse);
        expect(blocs, hasLength(1));
        expect(blocs.single.isClosed, isTrue);
        expect(await queueStorage.read(), isEmpty);

        anonymousIdp.authSuccess = testAuthSuccess(
          UuidValue.fromString('12345678-1234-1234-1234-123456789012'),
        );
        await tapContinueAsGuest(tester);
        await tester.pumpAndSettle();

        expect(find.byType(VirtualBagScreen), findsOneWidget);
        expect(blocs, hasLength(2));
        expect(blocs.last.isClosed, isFalse);
        expect(blocs.last.state, isNot(isA<BagInitial>()));
      },
    );

    testWidgets(
      'MyApp binds the platform HealthSyncService by default (desktop shows '
      'the simulate badge)',
      (tester) async {
        await setUpAuth(stored: testAuthSuccess(guestUserId));

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        expect(
          find.byKey(VirtualBagScreen.keySimulateWorkoutBadge),
          findsOneWidget,
        );

        await tester.tap(find.byKey(VirtualBagScreen.keySimulateWorkoutBadge));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        expect(find.text('1h 30m Tennis Match Detected'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  });
}
