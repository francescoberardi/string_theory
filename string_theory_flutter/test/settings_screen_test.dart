import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/screens/settings_screen.dart';
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
  });
}
