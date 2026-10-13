import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/settings_screen.dart';
import 'package:string_theory_flutter/services/auth_service.dart';

import 'helpers/fake_auth.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  group('SettingsScreen', () {
    final testUserId = UuidValue.fromString(
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    );
    final sampleAuthSuccess = AuthSuccess(
      authStrategy: 'session',
      token: 'jwt-token',
      authUserId: testUserId,
      scopeNames: {},
    );

    /// A signed-in [AuthService]: an email user with [accountEmail], a guest
    /// without one, or an unknown account when the lookup [fails].
    Future<AuthService> signedIn({
      String? accountEmail,
      bool fails = false,
    }) async {
      final client = buildOfflineTestClient(
        InMemoryAuthSuccessStorage(sampleAuthSuccess),
      );
      final auth = AuthService(
        client: client,
        fetchAccountEmail: () async {
          if (fails) throw Exception('offline');
          return accountEmail;
        },
      );
      await auth.initialize();
      return auth;
    }

    Future<void> pumpSettings(WidgetTester tester, AuthService auth) async {
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(authService: auth)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openSignOutDialog(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(SettingsScreen.keySignOutButton));
      await tester.tap(find.byKey(SettingsScreen.keySignOutButton));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'given a guest, shows the guest banner and no link or Google option',
      (tester) async {
        final auth = await signedIn();
        await pumpSettings(tester, auth);

        expect(find.text('Settings'), findsOneWidget);
        expect(find.byKey(SettingsScreen.keyGuestBanner), findsOneWidget);
        expect(
          find.textContaining('lives on this guest identity only'),
          findsOneWidget,
        );
        expect(
          find.textContaining('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
          findsOneWidget,
        );
        expect(find.byKey(SettingsScreen.keyAccountEmail), findsNothing);
        expect(find.textContaining('Link'), findsNothing);
        expect(find.textContaining('Google'), findsNothing);
        expect(find.textContaining('Re-authenticate'), findsNothing);
      },
    );

    testWidgets(
      'given an email user, shows the account email instead of the guest banner',
      (tester) async {
        final auth = await signedIn(accountEmail: 'judge@example.com');
        await pumpSettings(tester, auth);

        expect(find.byKey(SettingsScreen.keyAccountEmail), findsOneWidget);
        expect(find.text('judge@example.com'), findsOneWidget);
        expect(find.byKey(SettingsScreen.keyGuestBanner), findsNothing);
        expect(find.textContaining('Google'), findsNothing);
      },
    );

    testWidgets(
      'given the account lookup fails, shows generic account text and no guest banner',
      (tester) async {
        final auth = await signedIn(fails: true);
        await pumpSettings(tester, auth);

        expect(find.byKey(SettingsScreen.keyGuestBanner), findsNothing);
        expect(find.byKey(SettingsScreen.keyAccountEmail), findsNothing);
        expect(find.text('Signed in'), findsOneWidget);
      },
    );

    testWidgets(
      'given a guest, the sign-out dialog warns the bag becomes unreachable',
      (tester) async {
        final auth = await signedIn();
        await pumpSettings(tester, auth);

        await openSignOutDialog(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('unreachable'), findsOneWidget);
        expect(find.textContaining("can't be recovered"), findsOneWidget);
      },
    );

    testWidgets(
      'given an email user, the sign-out dialog has no guest warning',
      (tester) async {
        final auth = await signedIn(accountEmail: 'judge@example.com');
        await pumpSettings(tester, auth);

        await openSignOutDialog(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('unreachable'), findsNothing);
      },
    );

    testWidgets('cancelling the sign-out dialog keeps the user signed in', (
      tester,
    ) async {
      final auth = await signedIn();
      await pumpSettings(tester, auth);

      await openSignOutDialog(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
    });

    testWidgets('confirming sign-out signs the device out', (tester) async {
      final auth = await signedIn(accountEmail: 'judge@example.com');
      await pumpSettings(tester, auth);

      await openSignOutDialog(tester);
      await tester.tap(find.byKey(SettingsScreen.keyConfirmSignOutButton));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets(
      'Story 2.3: given settings screen, should render DEVELOPER & JUDGE CONTROLS and Trigger FutureCall Decay button',
      (tester) async {
        final authService = await signedIn();

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(authService: authService)),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevTriggerDecayButton),
        );
        expect(find.text('DEVELOPER & JUDGE CONTROLS'), findsOneWidget);
        expect(
          find.byKey(SettingsScreen.keyDevTriggerDecayButton),
          findsOneWidget,
        );
        expect(find.text('⚡ Trigger FutureCall Decay'), findsOneWidget);
      },
    );

    testWidgets(
      'Story 2.3: given settings screen, when [⚡ Trigger FutureCall Decay] is tapped, executes worker via RPC and reloads bag',
      (tester) async {
        final authService = await signedIn();

        final mockClient = MockClient();
        final mockEndpointBag = MockEndpointBag();
        final mockBagBloc = MockBagBloc();

        when(() => mockClient.bag).thenReturn(mockEndpointBag);
        when(
          () => mockEndpointBag.triggerDailyDecayNow(),
        ).thenAnswer((_) async => 4);

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              authService: authService,
              client: mockClient,
              bagBloc: mockBagBloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevTriggerDecayButton),
        );
        await tester.tap(find.byKey(SettingsScreen.keyDevTriggerDecayButton));
        await tester.pumpAndSettle();

        verify(() => mockEndpointBag.triggerDailyDecayNow()).called(1);
        verify(() => mockBagBloc.add(const LoadBag())).called(1);
        expect(
          find.text('Decay executed: 4 string jobs updated'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Story 2.3: given settings screen, when [⚡ Trigger FutureCall Decay] fails via RPC, shows error feedback snackbar',
      (tester) async {
        final authService = await signedIn();

        final mockClient = MockClient();
        final mockEndpointBag = MockEndpointBag();

        when(() => mockClient.bag).thenReturn(mockEndpointBag);
        when(
          () => mockEndpointBag.triggerDailyDecayNow(),
        ).thenThrow(Exception('RPC timeout'));

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              authService: authService,
              client: mockClient,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevTriggerDecayButton),
        );
        await tester.tap(find.byKey(SettingsScreen.keyDevTriggerDecayButton));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Error triggering decay: Exception: RPC timeout'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Story 2.4: given settings screen, renders [⏩ Fast-Forward 30 Days] button under DEVELOPER & JUDGE CONTROLS',
      (tester) async {
        final authService = await signedIn();

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(authService: authService),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevFastForwardButton),
        );
        expect(
          find.byKey(SettingsScreen.keyDevFastForwardButton),
          findsOneWidget,
        );
        expect(find.text('Fast-Forward 30 Days'), findsOneWidget);
        expect(find.text('Time-Warp Aging Simulator'), findsOneWidget);
      },
    );

    testWidgets(
      'Story 2.4: given settings screen with primary racquet in bag, when [⏩ Fast-Forward 30 Days] tapped, calls fastForwardRacquetAge and reloads bag',
      (tester) async {
        final authService = await signedIn();

        final mockClient = MockClient();
        final mockEndpointBag = MockEndpointBag();
        final mockBagBloc = MockBagBloc();

        final targetJob = StringJob(
          id: 1,
          userId: Namespace.nil.uuidValue,
          racquetId: 1,
          materialCategory: StringMaterialCategory.coPoly,
          stringingDate: DateTime.utc(2026, 9, 20),
          currentHealthScore: 76,
          createdAt: DateTime.utc(2026, 9, 20),
        );
        final targetRacquet = Racquet(
          id: 1,
          userId: Namespace.nil.uuidValue,
          name: 'Wilson Blade 98',
          isPrimary: true,
          activeStringJob: targetJob,
          createdAt: DateTime.utc(2026, 9, 20),
          updatedAt: DateTime.utc(2026, 9, 20),
        );

        final agedJob = targetJob.copyWith(currentHealthScore: 64);
        final agedRacquet = targetRacquet.copyWith(activeStringJob: agedJob);

        when(() => mockClient.bag).thenReturn(mockEndpointBag);
        when(() => mockBagBloc.state).thenReturn(BagLoaded([targetRacquet]));
        when(
          () => mockEndpointBag.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).thenAnswer((_) async => agedRacquet);

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              authService: authService,
              client: mockClient,
              bagBloc: mockBagBloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevFastForwardButton),
        );
        await tester.tap(find.byKey(SettingsScreen.keyDevFastForwardButton));
        await tester.pumpAndSettle();

        verify(
          () => mockEndpointBag.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).called(1);
        verify(
          () => mockBagBloc.add(const FastForwardRacquetAge(1, days: 30)),
        ).called(1);
        expect(
          find.text('Aged "Wilson Blade 98" by 30 days (Health: 64%)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Story 2.4: given settings screen without racquets, when [Fast-Forward 30 Days] tapped, shows error feedback snackbar',
      (tester) async {
        final authService = await signedIn();

        final mockClient = MockClient();
        final mockEndpointBag = MockEndpointBag();
        final mockBagBloc = MockBagBloc();

        when(() => mockClient.bag).thenReturn(mockEndpointBag);
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              authService: authService,
              client: mockClient,
              bagBloc: mockBagBloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevFastForwardButton),
        );
        await tester.tap(find.byKey(SettingsScreen.keyDevFastForwardButton));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No racquet with an active string job found. Add or string a racquet first.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Story 2.4: given settings screen, when fastForwardRacquetAge fails via RPC, shows error snackbar',
      (tester) async {
        final authService = await signedIn();

        final mockClient = MockClient();
        final mockEndpointBag = MockEndpointBag();
        final mockBagBloc = MockBagBloc();

        final targetJob = StringJob(
          id: 1,
          userId: Namespace.nil.uuidValue,
          racquetId: 1,
          materialCategory: StringMaterialCategory.coPoly,
          stringingDate: DateTime.utc(2026, 9, 20),
          currentHealthScore: 76,
          createdAt: DateTime.utc(2026, 9, 20),
        );
        final targetRacquet = Racquet(
          id: 1,
          userId: Namespace.nil.uuidValue,
          name: 'Wilson Blade 98',
          isPrimary: true,
          activeStringJob: targetJob,
          createdAt: DateTime.utc(2026, 9, 20),
          updatedAt: DateTime.utc(2026, 9, 20),
        );

        when(() => mockClient.bag).thenReturn(mockEndpointBag);
        when(() => mockBagBloc.state).thenReturn(BagLoaded([targetRacquet]));
        when(
          () => mockEndpointBag.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).thenThrow(Exception('RPC timeout'));

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              authService: authService,
              client: mockClient,
              bagBloc: mockBagBloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(SettingsScreen.keyDevFastForwardButton),
        );
        await tester.tap(find.byKey(SettingsScreen.keyDevFastForwardButton));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Error fast-forwarding age: Exception: RPC timeout',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
