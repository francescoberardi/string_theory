import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_flutter/client.dart' as app_client;
import 'package:string_theory_flutter/services/auth_service.dart';

import 'helpers/fake_auth.dart';

void main() {
  test(
    'a 401 from any call makes the app client re-check the session',
    () async {
      // A server that rejects every call as unauthenticated.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
      });

      final client = app_client.buildAppClient(
        'http://127.0.0.1:${server.port}/',
        authSessionManager: FlutterAuthSessionManager(
          storage: InMemoryAuthSuccessStorage(testAuthSuccess(guestUserId)),
        ),
      );
      addTearDown(client.close);
      var checks = 0;
      app_client.authService = AuthService(
        client: client,
        fetchAccountEmail: () async => null,
        validateAuthentication: () async {
          checks++;
          return true;
        },
      );
      await app_client.authService.initialize();

      await expectLater(client.bag.getVirtualBag(), throwsA(anything));
      await pumpEventQueue();

      expect(checks, 1);
    },
  );
}
