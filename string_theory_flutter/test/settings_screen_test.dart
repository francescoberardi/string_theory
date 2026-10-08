import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/settings_screen.dart';
import 'package:string_theory_flutter/services/auth_service.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockBagBloc extends Mock implements BagBloc {}

class InMemoryAuthSuccessStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _stored;

  InMemoryAuthSuccessStorage([this._stored]);

  @override
  Future<AuthSuccess?> get() async => _stored;

  @override
  Future<void> set(AuthSuccess? data) async => _stored = data;
}

class FakeEndpointAnonymousIdp implements EndpointAnonymousIdp {
  @override
  Future<AuthSuccess> login({String? token}) async {
    return AuthSuccess(
      authStrategy: 'session',
      token: 'dummy-token',
      authUserId: UuidValue.fromString('99999999-9999-9999-9999-999999999999'),
      scopeNames: {},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

    testWidgets(
      'given authenticated guest, when settings renders, then guest ID and link button are displayed',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();
        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(authService: authService),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(
          find.textContaining('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
          findsOneWidget,
        );
        expect(find.text('Link Google / Email'), findsOneWidget);
      },
    );

    testWidgets(
      'given settings screen, when link button tapped, then account linking dialog appears',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();
        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(authService: authService),
          ),
        );
        await tester.pumpAndSettle();

        final linkButton = find.text('Link Google / Email');
        await tester.tap(linkButton);
        await tester.pumpAndSettle();

        expect(find.text('Link Account'), findsOneWidget);
        expect(
          find.textContaining('preserve all your virtual gear bags'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given link account dialog, when Continue with Google is tapped, then shows google preview feedback',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(authService: authService)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Link Google / Email'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(find.text('Google linking preview enabled'), findsOneWidget);
      },
    );

    testWidgets(
      'given link account dialog, when Continue with Email is tapped, then shows email preview feedback',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(authService: authService)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Link Google / Email'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue with Email'));
        await tester.pumpAndSettle();

        expect(find.text('Email linking preview enabled'), findsOneWidget);
      },
    );

    testWidgets(
      'given settings screen, when Refresh is tapped and confirmed, then re-authenticates and shows feedback',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();
        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(authService: authService)),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Refresh'));
        await tester.tap(find.text('Refresh'));
        await tester.pumpAndSettle();

        expect(find.text('Re-authenticate Guest?'), findsOneWidget);
        await tester.tap(find.text('Re-authenticate'));
        await tester.pumpAndSettle();

        expect(find.text('Guest session refreshed'), findsOneWidget);
      },
    );

    testWidgets(
      'given settings screen, when Sign Out is tapped and confirmed, then signs out and shows feedback',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(authService: authService)),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Sign Out'));
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        expect(find.text('Sign Out Device?'), findsOneWidget);
        final dialogConfirmButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign Out'),
        );
        await tester.tap(dialogConfirmButton);
        await tester.pumpAndSettle();

        expect(find.text('Device signed out'), findsOneWidget);
        expect(authService.isAuthenticated, isFalse);
      },
    );

    testWidgets(
      'Story 2.3: given settings screen, should render DEVELOPER & JUDGE CONTROLS and Trigger FutureCall Decay button',
      (tester) async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
        );
        await authService.initialize();

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
