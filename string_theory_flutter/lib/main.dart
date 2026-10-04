import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/bag_bloc.dart';
import 'client.dart';
import 'screens/settings_screen.dart';
import 'screens/virtual_bag_screen.dart';
import 'services/health/health_sync_resolver.dart';
import 'services/health/health_sync_service.dart';
import 'theme/court_midnight_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final BagBloc? bagBloc;
  final HealthSyncService? healthSyncService;

  const MyApp({super.key, this.bagBloc, this.healthSyncService});

  @override
  Widget build(BuildContext context) {
    final materialApp = MaterialApp(
      title: 'String Theory',
      theme: CourtMidnightTheme.themeData,
      home: const MyHomePage(title: 'STRING THEORY'),
    );

    final Widget withBag = bagBloc != null
        ? BlocProvider<BagBloc>.value(value: bagBloc!, child: materialApp)
        : BlocProvider<BagBloc>(
            create: (context) => BagBloc(client: client)..add(const LoadBag()),
            child: materialApp,
          );

    if (healthSyncService != null) {
      return RepositoryProvider<HealthSyncService>.value(
        value: healthSyncService!,
        child: withBag,
      );
    }

    // The resolver binds SimulatedHealthSyncService off-mobile, and
    // NativeHealthSyncService creates its plugin gateway lazily on first sync,
    // so the native health plugin is never touched on web / desktop.
    return RepositoryProvider<HealthSyncService>(
      create: (_) => createHealthSyncService(),
      dispose: (service) => service.dispose(),
      child: withBag,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // If not authenticated after launch (e.g. offline on first boot), notify user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Offline on first launch: unable to provision guest session.',
            ),
            backgroundColor: const Color(0xFFFF9F0A),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.black,
              onPressed: () async {
                try {
                  await authService.loginAsGuest();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retry failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ValueListenableBuilder(
            valueListenable: authService.authInfoListenable,
            builder: (context, authInfo, _) {
              final isAuthed = authService.isAuthenticated;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAuthed
                      ? const Color(0xFFC6F10E).withValues(alpha: 0.15)
                      : const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAuthed
                        ? const Color(0xFFC6F10E).withValues(alpha: 0.4)
                        : const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isAuthed
                          ? const Color(0xFFC6F10E)
                          : const Color(0xFFFF9F0A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAuthed ? 'GUEST' : 'OFFLINE',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAuthed
                            ? const Color(0xFFC6F10E)
                            : const Color(0xFFFF9F0A),
                      ),
                    ),
                  ],
                ),
              );
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
