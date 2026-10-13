import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'services/auth_service.dart';
import 'services/offline_session_queue.dart';

// When you are running the app on a physical device, you need to set the
// server URL to the IP address of your computer. You can find the IP
// address by running `ipconfig` on Windows or `ifconfig` on Mac/Linux.
//
// You can set the variable when running or building your app like this:
// E.g. `flutter run --dart-define=SERVER_URL=https://api.example.com/`.
//
// Otherwise, the server URL is fetched from the assets/config.json file or
// defaults to http://$localhost:8080/ if not found.
final serverUrl = getServerUrl();

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app.
late Client client;

/// Global authentication service: sign-in, sign-out and the signed-in account.
late AuthService authService;

/// Sessions logged while offline. App-wide, so sign-out can clear it.
late OfflineSessionQueue offlineSessionQueue;

/// Builds [client] and [authService] and restores a stored session, if any.
/// No session is created here: without one the app shows the sign-in screen.
Future<void> initializeClient() async {
  client = Client(await serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
  offlineSessionQueue = OfflineSessionQueue(
    storage: SharedPreferencesSessionQueueStorage(),
  );
  authService = AuthService(client: client, offlineQueue: offlineSessionQueue);
  try {
    await authService.initialize();
  } catch (e) {
    debugPrint('Auth initialization error (offline or unreachable): $e');
  }
}
