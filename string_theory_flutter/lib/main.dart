import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'bloc/bag_bloc.dart';
import 'client.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/virtual_bag_screen.dart';
import 'services/auth_service.dart';
import 'services/health/health_sync_resolver.dart';
import 'services/health/health_sync_service.dart';
import 'theme/court_midnight_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// Bag state to use instead of one created per signed-in identity (tests).
  final BagBloc? bagBloc;

  /// Creates the bag state for each signed-in identity; defaults to a
  /// [BagBloc] on the global client and offline queue.
  final BagBloc Function()? bagBlocFactory;

  final HealthSyncService? healthSyncService;

  const MyApp({
    super.key,
    this.bagBloc,
    this.bagBlocFactory,
    this.healthSyncService,
  });

  BagBloc _createBagBloc() =>
      bagBlocFactory?.call() ??
      BagBloc(client: client, offlineQueue: offlineSessionQueue);

  /// Signed out: the sign-in screen. Signed in: the bag, under a [BagBloc]
  /// keyed by the auth user, so a new identity gets a fresh bloc and a fresh
  /// navigator, and the old bloc (and its bag stream) is closed.
  Widget _buildGate(BuildContext context, AuthSuccess? authInfo, Widget? _) {
    if (authInfo == null) {
      return MaterialApp(
        key: const ValueKey('signed-out'),
        title: 'String Theory',
        theme: CourtMidnightTheme.themeData,
        home: const SignInScreen(),
      );
    }

    final materialApp = MaterialApp(
      title: 'String Theory',
      theme: CourtMidnightTheme.themeData,
      home: const MyHomePage(title: 'STRING THEORY'),
    );
    final injected = bagBloc;
    if (injected != null) {
      return BlocProvider<BagBloc>.value(
        key: ValueKey(authInfo.authUserId),
        value: injected,
        child: materialApp,
      );
    }
    return BlocProvider<BagBloc>(
      key: ValueKey(authInfo.authUserId),
      create: (_) => _createBagBloc()..add(const LoadBag()),
      child: materialApp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gate = ValueListenableBuilder<AuthSuccess?>(
      valueListenable: authService.authInfoListenable,
      builder: _buildGate,
    );

    if (healthSyncService != null) {
      return RepositoryProvider<HealthSyncService>.value(
        value: healthSyncService!,
        child: gate,
      );
    }

    // The resolver binds SimulatedHealthSyncService off-mobile, and
    // NativeHealthSyncService creates its plugin gateway lazily on first sync,
    // so the native health plugin is never touched on web / desktop.
    return RepositoryProvider<HealthSyncService>(
      create: (_) => createHealthSyncService(),
      dispose: (service) => service.dispose(),
      child: gate,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  static const keyGuestBadge = Key('app_bar_guest_badge');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ValueListenableBuilder<AccountInfo>(
            valueListenable: authService.account,
            builder: (context, account, _) {
              if (!account.isGuest) return const SizedBox.shrink();
              return const _GuestBadge(key: keyGuestBadge);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const VirtualBagScreen(),
    );
  }
}

/// AppBar badge marking an anonymous guest session.
class _GuestBadge extends StatelessWidget {
  const _GuestBadge({super.key});

  static const _volt = Color(0xFFC6F10E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _volt.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _volt.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: _volt),
          const SizedBox(width: 4),
          Text(
            'GUEST',
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _volt,
            ),
          ),
        ],
      ),
    );
  }
}
