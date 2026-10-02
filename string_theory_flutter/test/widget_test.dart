import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/client.dart' as app_client;
import 'package:string_theory_flutter/main.dart';
import 'package:string_theory_flutter/services/auth_service.dart';

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
  setUp(() {
    final storage = InMemoryAuthSuccessStorage(
      AuthSuccess(
        authStrategy: 'session',
        token: 'test-token',
        authUserId: UuidValue.fromString(
          '99999999-9999-9999-9999-999999999999',
        ),
        scopeNames: {},
      ),
    );
    app_client.client = Client('http://localhost:8080/')
      ..authSessionManager = FlutterAuthSessionManager(storage: storage);
    app_client.authService = AuthService(
      client: app_client.client,
      anonymousEndpoint: FakeEndpointAnonymousIdp(),
    );
  });

  testWidgets(
    'MyHomePage displays title, auth badge, and navigates to Settings',
    (tester) async {
      await app_client.authService.initialize();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('STRING THEORY'), findsOneWidget);
      expect(find.text('GUEST'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ACCOUNT & SYNC'), findsOneWidget);
    },
  );

  testWidgets(
    'given unauthenticated state, MyHomePage displays OFFLINE badge and retry snackbar',
    (tester) async {
      final storage = InMemoryAuthSuccessStorage();
      app_client.client = Client('http://localhost:8080/')
        ..authSessionManager = FlutterAuthSessionManager(storage: storage);
      app_client.authService = AuthService(
        client: app_client.client,
        anonymousEndpoint: FakeEndpointAnonymousIdp(),
      );

      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(
        find.text(
          'Offline on first launch: unable to provision guest session.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('GUEST'), findsOneWidget);
    },
  );
}
